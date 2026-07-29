import Foundation

private enum TennisBallAdvanceResult: Equatable { case inFlight, firstGroundContact, secondGroundContactDue, pointEnded }

struct TennisSimulation {
    private(set) var snapshot: TennisMatchSnapshot
    private var rules: TennisRules
    private var cpuController: TennisCPUController
    private var humanShotInput: TennisShotInputMachine
    private var random: TennisSeededRandom
    private var totalPointsPlayed: Int
    private var phaseElapsedMilliseconds: UInt64
    private var phaseBeforeHitstop: TennisPointPhase?
    private var lastContactQuality: [TennisSide: TennisContactQuality]
    private var movementRemainderMilliPixels: [TennisSide: TennisPoint]

    init(surface: TennisSurface, configuration: TennisGameConfiguration) {
        rules = TennisRules(configuration: configuration)
        let near = TennisPlayerState(side: .human, courtEnd: configuration.humanCourtEnd, position: TennisPoint(x: 80, y: 120), preset: .balanced)
        let farEnd: TennisCourtEnd = configuration.humanCourtEnd == .near ? .far : .near
        let cpu = TennisPlayerState(side: .cpu, courtEnd: farEnd, position: TennisPoint(x: 80, y: 24), preset: .power)
        snapshot = TennisMatchSnapshot(surface: surface, players: [.human: near, .cpu: cpu], ball: nil, score: TennisScore(human: 0, cpu: 0), server: configuration.openingServer, phase: .serveAnticipation, liveBallPhase: nil, matchWinner: nil)
        cpuController = TennisCPUController()
        humanShotInput = TennisShotInputMachine()
        random = TennisSeededRandom(seed: configuration.seed)
        totalPointsPlayed = 0; phaseElapsedMilliseconds = 0; phaseBeforeHitstop = nil
        lastContactQuality = [:]
        movementRemainderMilliPixels = [.human: TennisPoint(x: 0, y: 0), .cpu: TennisPoint(x: 0, y: 0)]
    }

    mutating func advance(input: TennisInputFrame) -> TennisTickResult {
        var events: [TennisSimulationEvent] = []
        if input.keyboardFocusLost { cancelHumanInput(events: &events) }
        phaseElapsedMilliseconds += rules.configuration.tickMilliseconds
        if snapshot.phase == .ended && phaseElapsedMilliseconds >= 2000 && snapshot.matchWinner == nil { beginPoint() }
        switch snapshot.phase {
        case .serveAnticipation, .awaitingServeInput: advanceServe(input: input, events: &events)
        case .rally: advanceRally(input: input, events: &events)
        case .hitstop: advanceHitstop(input: input)
        case .ended: advancePostPoint(events: &events)
        }
        return TennisTickResult(snapshot: snapshot, events: events)
    }

    mutating func beginPoint() {
        snapshot.server = rules.server(totalPointsPlayed: totalPointsPlayed)
        snapshot.phase = .serveAnticipation; snapshot.liveBallPhase = nil; snapshot.ball = nil; snapshot.matchWinner = nil; phaseElapsedMilliseconds = 0
        for side in [TennisSide.human, .cpu] {
            guard var player = snapshot.players[side] else { continue }
            let bounds = rules.movementBounds(for: player.courtEnd)
            player.position = TennisPoint(x: 80, y: player.courtEnd == .near ? bounds.maxY : bounds.minY)
            snapshot.players[side] = player
        }
        humanShotInput.reset(); cpuController.resetForPoint(random: &random)
    }

    private mutating func cancelHumanInput(events: inout [TennisSimulationEvent]) {
        guard humanShotInput.transaction != nil else { return }
        humanShotInput.cancelAndRequireRelease([])
        events.append(.shotTransactionCancelled(.human))
    }

    private mutating func advancePlayers(humanInput: TennisPoint, cpuInput: TennisPoint) {
        for (side, input) in [(TennisSide.human, humanInput), (.cpu, cpuInput)] {
            guard var player = snapshot.players[side], snapshot.phase == .rally else { continue }
            var remainder = movementRemainderMilliPixels[side] ?? TennisPoint(x: 0, y: 0)
            let delta = rules.movementDelta(input: input, preset: player.preset, remainderMilliPixels: &remainder)
            let bounds = rules.movementBounds(for: player.courtEnd)
            player.position = TennisPoint(x: min(bounds.maxX, max(bounds.minX, player.position.x + delta.x)), y: min(bounds.maxY, max(bounds.minY, player.position.y + delta.y)))
            snapshot.players[side] = player; movementRemainderMilliPixels[side] = remainder
        }
    }

    private mutating func advanceServe(input: TennisInputFrame, events: inout [TennisSimulationEvent]) {
        if snapshot.phase == .serveAnticipation { snapshot.phase = .awaitingServeInput; events.append(.serveAnticipationStarted(snapshot.server)); return }
        guard input.servePressed, let server = snapshot.players[snapshot.server], let receiver = snapshot.players[snapshot.server == .human ? .cpu : .human] else { return }
        let box = snapshot.server == .human ? rules.configuration.humanServeBox : rules.configuration.cpuServeBox
        let target = TennisPoint(x: (box.minX + box.maxX) / 2, y: (box.minY + box.maxY) / 2)
        launchShot(hitter: server.side, shot: .serve, chargedMilliseconds: 0, target: target, events: &events)
        _ = receiver
    }

    private mutating func advanceRally(input: TennisInputFrame, events: inout [TennisSimulationEvent]) {
        guard let ball = snapshot.ball, let human = snapshot.players[.human], let cpu = snapshot.players[.cpu] else { return }
        let cpuQuality = rules.contactQuality(player: cpu.position, ball: ball.shadow)
        lastContactQuality[.cpu] = cpuQuality
        let cpuOutput = cpuController.advance(context: TennisCPUTacticalContext(cpu: cpu, human: human, ball: ball, contactQuality: cpuQuality, isLegalReturnOpportunity: rules.isLegalReturnOpportunity(for: .cpu, phase: snapshot.liveBallPhase, ball: ball)), elapsedMilliseconds: rules.configuration.tickMilliseconds, rules: rules)
        advancePlayers(humanInput: input.movement, cpuInput: cpuOutput.movement)
        let humanQuality = rules.contactQuality(player: human.position, ball: ball.shadow)
        lastContactQuality[.human] = humanQuality
        let previousHumanTransaction = humanShotInput.transaction
        let humanCommit = humanShotInput.advance(input: input, elapsedMilliseconds: rules.configuration.tickMilliseconds, contactOpportunity: humanQuality != nil && rules.isLegalReturnOpportunity(for: .human, phase: snapshot.liveBallPhase, ball: ball), smashEligible: rules.isSmashEligible(player: human.position, ball: ball))
        if let transaction = humanShotInput.transaction,
           previousHumanTransaction != transaction {
            events.append(.shotTransactionChanged(.human, transaction.heldChargeMilliseconds, transaction.isChargeCapped))
        }
        for action in cpuOutput.actions {
            if case let .transactionChanged(shot, elapsed, capped) = action { events.append(.shotTransactionChanged(.cpu, elapsed, capped)); _ = shot }
        }
        let cpuPlan = cpuOutput.actions.compactMap { action -> TennisCPUShotPlan? in
            if case let .commit(plan) = action { return plan }
            return nil
        }.first
        if humanCommit != nil || cpuPlan != nil {
            resolveSimultaneousContacts(human: humanCommit, cpu: cpuPlan, events: &events)
            if snapshot.phase == .hitstop { humanShotInput.cancelAndRequireRelease(input.pressedShotButtons) }
        }
        if snapshot.phase != .hitstop {
            let result = advanceBall(events: &events)
            if result == .secondGroundContactDue { resolveSecondGroundContact(events: &events) }
        }
    }

    private mutating func advanceHitstop(input: TennisInputFrame) { if phaseElapsedMilliseconds >= 100 { snapshot.phase = phaseBeforeHitstop ?? .rally; phaseBeforeHitstop = nil; phaseElapsedMilliseconds = 0 } }
    private mutating func advanceBall(events: inout [TennisSimulationEvent]) -> TennisBallAdvanceResult {
        guard var ball = snapshot.ball else { return .pointEnded }
        ball.elapsedMilliseconds += rules.configuration.tickMilliseconds
        ball.position = rules.flightPosition(ball)
        ball.hasCrossedNetPlane = rules.hasCrossedNetPlane(ball)
        if ball.elapsedMilliseconds < ball.contactToBounceMilliseconds { snapshot.ball = ball; return .inFlight }
        // The ball is already at rest at its landing point for every fault-ending branch below
        // (flightPosition clamps to `landing` once elapsed >= duration); write it back before
        // ending the point so the post-point continuation has a resting position to slide from.
        snapshot.ball = ball
        if ball.shot == .serve && rules.landingJudgment(ball.landing) == .outOfBounds {
            endPoint(winner: ball.hitter == .human ? .cpu : .human, reason: .outOfBounds, events: &events); return .pointEnded
        }
        if !rules.clearsNet(ball) {
            endPoint(winner: ball.hitter == .human ? .cpu : .human, reason: .netFault, events: &events); return .pointEnded
        }
        if rules.landingJudgment(ball.landing) == .outOfBounds {
            endPoint(winner: ball.hitter == .human ? .cpu : .human, reason: .outOfBounds, events: &events); return .pointEnded
        }
        if ball.shot == .serve && !rules.isLegalServeLanding(ball.landing, server: ball.hitter) {
            endPoint(winner: ball.hitter == .human ? .cpu : .human, reason: .illegalServe, events: &events); return .pointEnded
        }
        ball.origin = ball.landing; ball.position = ball.landing; ball.shadow = ball.landing; ball.elapsedMilliseconds = 0
        ball.contactToBounceMilliseconds = ball.responseWindowMilliseconds
        ball.consecutiveGroundContacts += 1
        if ball.shot == .serve { snapshot.liveBallPhase = .rally }
        snapshot.phase = .rally
        snapshot.ball = ball
        events.append(.bounce(snapshot.surface, ball.shot, ball.landing))
        return ball.consecutiveGroundContacts >= 2 ? .secondGroundContactDue : .firstGroundContact
    }

    /// Slides the resting ball by its already-computed `skidDistance` along the dominant axis of
    /// its final flight direction, over a fixed short duration, then holds it for the remainder of
    /// the point's 2s window. No new trajectory math: `landing`/`origin`/`skidDistance` already
    /// exist on the ball from the shot that ended the point.
    private mutating func advancePostPoint(events: inout [TennisSimulationEvent]) {
        guard var ball = snapshot.ball else { return }
        ball.elapsedMilliseconds += rules.configuration.tickMilliseconds
        let skidDurationMilliseconds: UInt64 = 200
        let progress = min(skidDurationMilliseconds, ball.elapsedMilliseconds)
        let dx = ball.landing.x - ball.origin.x
        let dy = ball.landing.y - ball.origin.y
        var restX = ball.landing.x
        var restY = ball.landing.y
        if dx != 0 || dy != 0 {
            if abs(dx) >= abs(dy) {
                restX += dx >= 0 ? ball.skidDistance : -ball.skidDistance
            } else {
                restY += dy >= 0 ? ball.skidDistance : -ball.skidDistance
            }
        }
        restX = min(159, max(0, restX))
        restY = min(143, max(0, restY))
        ball.position = TennisPoint(
            x: ball.landing.x + (restX - ball.landing.x) * Int(progress) / Int(skidDurationMilliseconds),
            y: ball.landing.y + (restY - ball.landing.y) * Int(progress) / Int(skidDurationMilliseconds)
        )
        snapshot.ball = ball
    }

    private mutating func resolveSecondGroundContact(events: inout [TennisSimulationEvent]) {
        guard let ball = snapshot.ball else { return }
        endPoint(winner: ball.hitter == .human ? .cpu : .human, reason: .secondBounce, events: &events)
    }

    private mutating func resolveSimultaneousContacts(human: TennisShotCommit?, cpu: TennisCPUShotPlan?, events: inout [TennisSimulationEvent]) {
        guard let ball = snapshot.ball else { return }
        if let human, rules.isLegalReturnOpportunity(for: .human, phase: snapshot.liveBallPhase, ball: ball) {
            launchShot(hitter: .human, shot: human.shot, chargedMilliseconds: human.chargedMilliseconds, target: ball.landing, events: &events)
        } else if let cpu, rules.isLegalReturnOpportunity(for: .cpu, phase: snapshot.liveBallPhase, ball: ball) {
            launchShot(hitter: .cpu, shot: cpu.shot, chargedMilliseconds: cpu.chargeMilliseconds, target: cpu.target, events: &events)
        }
    }
    private mutating func launchShot(hitter: TennisSide, shot: TennisShotType, chargedMilliseconds: UInt64, target: TennisPoint, events: inout [TennisSimulationEvent]) {
        guard let player = snapshot.players[hitter], let opponent = snapshot.players[hitter == .human ? .cpu : .human] else { return }
        let outcome = rules.shotOutcome(hitter: player, opponent: opponent, surface: snapshot.surface, shot: shot, chargedMilliseconds: chargedMilliseconds, target: target, random: &random)
        let receiver: TennisSide = hitter == .human ? .cpu : .human
        snapshot.ball = TennisBallFlight(hitter: hitter, receiver: receiver, shot: shot, contactQuality: lastContactQuality[hitter] ?? .good, origin: player.position, landing: outcome.landing, position: player.position, shadow: outcome.landing, height: outcome.bounceHeight, elapsedMilliseconds: 0, contactToBounceMilliseconds: outcome.contactToBounceMilliseconds, responseWindowMilliseconds: outcome.responseWindowMilliseconds, bounceHeight: outcome.bounceHeight, skidDistance: outcome.skidDistance, hasCrossedNetPlane: false, consecutiveGroundContacts: 0)
        snapshot.liveBallPhase = shot == .serve ? .serveFlight : .rally
        let fullyCharged = chargedMilliseconds >= 600
        snapshot.phase = shot == .smash || fullyCharged ? .hitstop : .rally
        phaseBeforeHitstop = snapshot.phase == .hitstop ? .rally : nil
        phaseElapsedMilliseconds = 0
        events.append(.shotContact(hitter, shot, outcome.landing, fullyCharged))
    }
    private mutating func endPoint(winner: TennisSide, reason: TennisPointEndReason, events: inout [TennisSimulationEvent]) { snapshot.score = rules.score(after: winner, current: snapshot.score); snapshot.ball?.elapsedMilliseconds = 0; snapshot.liveBallPhase = .pointEnding; snapshot.phase = .ended; phaseElapsedMilliseconds = 0; totalPointsPlayed += 1; if reason == .netFault { events.append(.fault(.net)) }; if reason == .outOfBounds { events.append(.fault(.out)) }; if reason == .illegalServe { events.append(.fault(.fault)) }; if let matchWinner = rules.hasMatchWinner(snapshot.score) { snapshot.matchWinner = matchWinner; events.append(.matchEnded(matchWinner)) } else { events.append(.pointEnded(winner, reason)) } }
}

import Foundation

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
        snapshot = TennisMatchSnapshot(surface: surface, players: [.human: near, .cpu: cpu], ball: nil, score: TennisScore(human: 0, cpu: 0), server: configuration.openingServer, phase: .serveAnticipation, matchWinner: nil)
        cpuController = TennisCPUController()
        humanShotInput = TennisShotInputMachine()
        random = TennisSeededRandom(seed: configuration.seed)
        totalPointsPlayed = 0; phaseElapsedMilliseconds = 0; phaseBeforeHitstop = nil
        lastContactQuality = [:]
        movementRemainderMilliPixels = [.human: TennisPoint(x: 0, y: 0), .cpu: TennisPoint(x: 0, y: 0)]
    }

    mutating func advance(input: TennisInputFrame) -> TennisTickResult {
        var events: [TennisSimulationEvent] = []
        phaseElapsedMilliseconds += rules.configuration.tickMilliseconds
        if snapshot.phase == .ended { beginPoint() }
        switch snapshot.phase {
        case .serveAnticipation, .awaitingServeInput: advanceServe(input: input, events: &events)
        case .rally: advanceRally(input: input, events: &events)
        case .hitstop: advanceHitstop(input: input)
        case .ended: break
        }
        return TennisTickResult(snapshot: snapshot, events: events)
    }

    mutating func beginPoint() {
        snapshot.server = rules.server(totalPointsPlayed: totalPointsPlayed)
        snapshot.phase = .serveAnticipation; snapshot.ball = nil; snapshot.matchWinner = nil; phaseElapsedMilliseconds = 0
        for side in [TennisSide.human, .cpu] {
            guard var player = snapshot.players[side] else { continue }
            let bounds = rules.movementBounds(for: player.courtEnd)
            player.position = TennisPoint(x: 80, y: player.courtEnd == .near ? bounds.maxY : bounds.minY)
            snapshot.players[side] = player
        }
        humanShotInput.reset(); cpuController.resetForPoint(random: &random)
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
        let cpuOutput = cpuController.advance(context: TennisCPUTacticalContext(cpu: cpu, human: human, ball: ball, contactQuality: cpuQuality, legalSwingOpportunity: ball.bounceCount > 0), elapsedMilliseconds: rules.configuration.tickMilliseconds, rules: rules)
        advancePlayers(humanInput: input.movement, cpuInput: cpuOutput.movement)
        let humanQuality = rules.contactQuality(player: human.position, ball: ball.shadow)
        lastContactQuality[.human] = humanQuality
        let humanCommit = humanShotInput.advance(input: input, elapsedMilliseconds: rules.configuration.tickMilliseconds, contactOpportunity: humanQuality != nil && ball.bounceCount > 0, smashEligible: rules.isSmashEligible(player: human.position, ball: ball))
        for action in cpuOutput.actions {
            if case let .transactionChanged(shot, elapsed, capped) = action { events.append(.shotTransactionChanged(.cpu, elapsed, capped)); _ = shot }
        }
        let cpuPlan = cpuOutput.actions.compactMap { action -> TennisCPUShotPlan? in
            if case let .commit(plan) = action { return plan }
            return nil
        }.first
        if humanCommit != nil || cpuPlan != nil {
            resolveSimultaneousContacts(human: humanCommit, cpu: cpuPlan, events: &events)
        }
        advanceBall(events: &events)
    }

    private mutating func advanceHitstop(input: TennisInputFrame) { phaseElapsedMilliseconds += input.movement.x == 0 && input.movement.y == 0 ? 0 : 0; if phaseElapsedMilliseconds >= 100 { snapshot.phase = phaseBeforeHitstop ?? .rally; phaseBeforeHitstop = nil; phaseElapsedMilliseconds = 0 } }
    private mutating func advanceBall(events: inout [TennisSimulationEvent]) {
        guard var ball = snapshot.ball else { return }
        ball.elapsedMilliseconds += rules.configuration.tickMilliseconds
        if ball.elapsedMilliseconds < ball.contactToBounceMilliseconds { snapshot.ball = ball; return }
        if rules.landingJudgment(ball.landing) == .outOfBounds { endPoint(winner: ball.hitter == .human ? .cpu : .human, reason: .outOfBounds, events: &events); return }
        ball.bounceCount += 1; ball.shadow = ball.landing; ball.elapsedMilliseconds = 0; ball.contactToBounceMilliseconds = ball.responseWindowMilliseconds
        snapshot.ball = ball; events.append(.bounce(snapshot.surface, ball.shot, ball.landing))
        if ball.bounceCount >= 2 { endPoint(winner: ball.hitter == .human ? .cpu : .human, reason: .secondBounce, events: &events) }
    }

    private mutating func resolveSimultaneousContacts(human: TennisShotCommit?, cpu: TennisCPUShotPlan?, events: inout [TennisSimulationEvent]) { if let human { launchShot(hitter: .human, shot: human.shot, chargedMilliseconds: human.chargedMilliseconds, target: snapshot.ball?.landing ?? TennisPoint(x: 80, y: 72), events: &events) } else if let cpu { launchShot(hitter: .cpu, shot: cpu.shot, chargedMilliseconds: cpu.chargeMilliseconds, target: cpu.target, events: &events) } }
    private mutating func launchShot(hitter: TennisSide, shot: TennisShotType, chargedMilliseconds: UInt64, target: TennisPoint, events: inout [TennisSimulationEvent]) {
        guard let player = snapshot.players[hitter], let opponent = snapshot.players[hitter == .human ? .cpu : .human] else { return }
        let outcome = rules.shotOutcome(hitter: player, opponent: opponent, surface: snapshot.surface, shot: shot, chargedMilliseconds: chargedMilliseconds, target: target, random: &random)
        snapshot.ball = TennisBallFlight(hitter: hitter, shot: shot, contactQuality: lastContactQuality[hitter] ?? .good, origin: player.position, landing: outcome.landing, shadow: player.position, height: outcome.bounceHeight, elapsedMilliseconds: 0, contactToBounceMilliseconds: outcome.contactToBounceMilliseconds, responseWindowMilliseconds: outcome.responseWindowMilliseconds, bounceHeight: outcome.bounceHeight, skidDistance: outcome.skidDistance, bounceCount: 0)
        snapshot.phase = .rally; phaseElapsedMilliseconds = 0; events.append(.shotContact(hitter, shot, outcome.landing, chargedMilliseconds >= 600))
    }
    private mutating func endPoint(winner: TennisSide, reason: TennisPointEndReason, events: inout [TennisSimulationEvent]) { snapshot.score = rules.score(after: winner, current: snapshot.score); snapshot.ball = nil; snapshot.phase = .ended; totalPointsPlayed += 1; if let matchWinner = rules.hasMatchWinner(snapshot.score) { snapshot.matchWinner = matchWinner; events.append(.matchEnded(matchWinner)) } else { events.append(.pointEnded(winner, reason)) } }
}

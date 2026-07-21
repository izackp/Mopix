import XCTest
@testable import TennisCore

final class TennisSimulationTests: XCTestCase {
    func testPacingRowsAndResponseFloorAcrossShotClassesAndSurfaces() {
        let cases: [(TennisSwingSequence, ShotKind, ClosedRange<Int>, ClosedRange<Int>, ClosedRange<Int>, TennisFixed)] = [
            (.standaloneA, .topspin, 22...32, 26...40, 18...27, 0),
            (.standaloneB, .slice, 24...36, 28...44, 20...31, 0),
            (.simultaneousAB, .flat, 18...28, 22...34, 15...24, 0),
            (.aThenB, .lob, 36...56, 42...68, 31...48, 0),
            (.bThenA, .drop, 20...30, 24...36, 17...26, 0),
            (.simultaneousAB, .smash, 16...24, 19...29, 14...21, 1000)
        ]
        for (sequence, expectedShot, hard, clay, grass, ballHeight) in cases {
            let ranges = [CourtSurface.hard: hard, .clay: clay, .grass: grass]
            for surface in [CourtSurface.hard, .clay, .grass] {
                let trace = flightTrace(surface: surface, sequence: sequence, charge: 0, ballHeight: ballHeight)
                XCTAssertEqual(trace.shot, expectedShot)
                XCTAssertTrue(ranges[surface]!.contains(trace.firstBounce), "\(surface) \(expectedShot) bounce \(trace.firstBounce)")
                XCTAssertGreaterThanOrEqual(trace.firstOpportunity - trace.firstBounce, 8, "\(surface) \(expectedShot) response floor")
                XCTAssertEqual(trace.bounceSurface, surface)
            }
        }
        let serveRanges = [CourtSurface.hard: 24...36, .clay: 28...44, .grass: 20...31]
        for surface in [CourtSurface.hard, .clay, .grass] {
            let trace = serveTrace(surface: surface, charge: 0)
            XCTAssertTrue(serveRanges[surface]!.contains(trace.firstBounce), "\(surface) serve bounce \(trace.firstBounce)")
            XCTAssertGreaterThanOrEqual(trace.firstOpportunity - trace.firstBounce, 8, "\(surface) serve response floor")
            XCTAssertEqual(trace.bounceSurface, surface)
        }
    }

    func testMatchedSurfaceOrderingAndChargePacing() {
        let hard = flightTrace(surface: .hard, sequence: .standaloneA, charge: 0, ballHeight: 0)
        let clay = flightTrace(surface: .clay, sequence: .standaloneA, charge: 0, ballHeight: 0)
        let grass = flightTrace(surface: .grass, sequence: .standaloneA, charge: 0, ballHeight: 0)
        XCTAssertGreaterThan(clay.firstBounce, hard.firstBounce)
        XCTAssertGreaterThan(hard.firstBounce, grass.firstBounce)
        XCTAssertEqual(hard.bounceSurface, .hard)
        XCTAssertEqual(clay.bounceSurface, .clay)
        XCTAssertEqual(grass.bounceSurface, .grass)

        let uncharged = flightTrace(surface: .hard, sequence: .standaloneA, charge: 0, ballHeight: 0)
        let full = flightTrace(surface: .hard, sequence: .standaloneA, charge: 100, ballHeight: 0)
        XCTAssertTrue((2...6).contains(uncharged.firstBounce - full.firstBounce), "uncharged \(uncharged.firstBounce), full \(full.firstBounce)")
        XCTAssertTrue((22...32).contains(full.firstBounce))
    }

    func testRuleBookMapsEverySwingSequenceAndSmashFallback() {
        let rules = DefaultTennisRuleBook()
        XCTAssertEqual(rules.shotKind(for: .standaloneA, smashEligible: false), .topspin)
        XCTAssertEqual(rules.shotKind(for: .standaloneB, smashEligible: false), .slice)
        XCTAssertEqual(rules.shotKind(for: .aThenB, smashEligible: false), .lob)
        XCTAssertEqual(rules.shotKind(for: .bThenA, smashEligible: false), .drop)
        XCTAssertEqual(rules.shotKind(for: .simultaneousAB, smashEligible: true), .smash)
        XCTAssertEqual(rules.shotKind(for: .simultaneousAB, smashEligible: false), .flat)
    }

    func testSimulationEmitsAllRallyShotKinds() {
        for (sequence, expected) in [(TennisSwingSequence.standaloneA, ShotKind.topspin), (.standaloneB, .slice), (.aThenB, .lob), (.bThenA, .drop), (.simultaneousAB, .flat)] {
            let recorder = EventRecorder(); let simulation = makeSimulation(seed: 10, inFlight: true, ballHeight: 400)
            simulation.delegate = recorder
            simulation.step(tickInput: TennisTickInput(human: .swing(sequence: sequence, charge: 0), cpu: .none))
            XCTAssertTrue(recorder.events.contains { if case .shotHit(side: .human, shot: expected, quality: .perfect) = $0.kind { return true }; return false }, "missing \(expected)")
        }
        let smashRecorder = EventRecorder(); let smash = makeSimulation(seed: 10, inFlight: true, ballHeight: 1000); smash.delegate = smashRecorder
        smash.step(tickInput: TennisTickInput(human: .swing(sequence: .simultaneousAB, charge: 0), cpu: .none))
        XCTAssertTrue(smashRecorder.events.contains { if case .shotHit(side: .human, shot: .smash, quality: .perfect) = $0.kind { return true }; return false })
    }

    func testIllegalServeUsesLandingFaultAndReceiverWins() {
        let legal = makeSimulation(seed: 4)
        let legalRecorder = EventRecorder(); legal.delegate = legalRecorder
        legal.step(tickInput: TennisTickInput(human: .swing(sequence: .standaloneA, charge: 0), cpu: .none))
        XCTAssertTrue(legalRecorder.events.contains { if case .serveHit(side: .human) = $0.kind { return true }; return false })
        let simulation = makeSimulation(seed: 4, serviceBoxes: .remote)
        let recorder = EventRecorder(); simulation.delegate = recorder
        simulation.step(tickInput: TennisTickInput(human: .swing(sequence: .standaloneA, charge: 0), cpu: .none))
        guard case .serveFault(let server, let landing) = simulation.state.pointEnd else { return XCTFail("expected serve fault") }
        XCTAssertEqual(server, .human)
        XCTAssertTrue(recorder.events.contains { if case .serveFault(server: .human, landing: let eventLanding) = $0.kind { return eventLanding == landing }; return false })
        XCTAssertEqual(DefaultTennisRuleBook().pointWinner(for: simulation.state.pointEnd!), .cpu)
    }

    func testServeWindUpLocksMovementAndLaunchesOnOneFixedTick() {
        let simulation = makeSimulation(seed: 8)
        let baseline = simulation.state.players[.human]?.position

        simulation.step(tickInput: TennisTickInput(human: .move(direction: TennisDirection(x: 1, y: -1)), cpu: .none))
        XCTAssertEqual(simulation.state.phase, .serveWindUp)
        XCTAssertEqual(simulation.state.players[.human]?.position, baseline)
        XCTAssertFalse(simulation.state.ball.isInFlight)
        XCTAssertEqual(simulation.state.tick, 1)

        simulation.step(tickInput: TennisTickInput(human: .swing(sequence: .standaloneA, charge: 0), cpu: .none))
        XCTAssertEqual(simulation.state.phase, .rally)
        XCTAssertTrue(simulation.state.ball.isInFlight)
        XCTAssertEqual(simulation.state.tick, 2)
    }

    func testResetPointRestoresFixedBaselineCenters() {
        let simulation = makeSimulation(seed: 5)
        simulation.resetPoint(server: .human)
        XCTAssertEqual(simulation.state.players[.human]?.position, TennisPoint(x: 5000, y: 20000))
        XCTAssertEqual(simulation.state.players[.cpu]?.position, TennisPoint(x: 5000, y: 0))
        XCTAssertEqual(simulation.state.ball.position, TennisPoint(x: 5000, y: 20000))

        simulation.resetPoint(server: .cpu)
        XCTAssertEqual(simulation.state.players[.human]?.position, TennisPoint(x: 5000, y: 20000))
        XCTAssertEqual(simulation.state.players[.cpu]?.position, TennisPoint(x: 5000, y: 0))
        XCTAssertEqual(simulation.state.ball.position, TennisPoint(x: 5000, y: 0))
    }

    func testEqualSeedServeReplayMatchesLegalLandingProjectionAndEvents() {
        let legalA = makeSimulation(seed: 31); let legalB = makeSimulation(seed: 31)
        legalA.resetPoint(server: .human); legalB.resetPoint(server: .human)
        let legalRecorderA = EventRecorder(); let legalRecorderB = EventRecorder(); legalA.delegate = legalRecorderA; legalB.delegate = legalRecorderB
        let serve = TennisTickInput(human: .swing(sequence: .standaloneA, charge: 0), cpu: .none)
        legalA.step(tickInput: serve); legalB.step(tickInput: serve)
        XCTAssertEqual(legalA.state.ball.velocity, legalB.state.ball.velocity)
        XCTAssertEqual(legalRecorderA.events.map(EventShape.init), legalRecorderB.events.map(EventShape.init))
        XCTAssertNil(legalA.state.pointEnd)

        let illegalA = makeSimulation(seed: 31, serviceBoxes: .remote); let illegalB = makeSimulation(seed: 31, serviceBoxes: .remote)
        illegalA.resetPoint(server: .human); illegalB.resetPoint(server: .human)
        let illegalRecorderA = EventRecorder(); let illegalRecorderB = EventRecorder(); illegalA.delegate = illegalRecorderA; illegalB.delegate = illegalRecorderB
        illegalA.step(tickInput: serve); illegalB.step(tickInput: serve)
        XCTAssertEqual(illegalRecorderA.events.map(EventShape.init), illegalRecorderB.events.map(EventShape.init))
        guard case .serveFault(_, let landingA) = illegalA.state.pointEnd, case .serveFault(_, let landingB) = illegalB.state.pointEnd else { return XCTFail("expected deterministic serve faults") }
        XCTAssertEqual(landingA, landingB)
    }

    func testSecondBounceUsesReceivingSideAndWinner() {
        let simulation = makeSimulation(seed: 2, inFlight: true, ballHeight: 1, ballVelocity: TennisVelocity(x: 0, y: 0, z: -90), ballPosition: TennisPoint(x: 5000, y: 5000), lastHitter: .human); let recorder = EventRecorder(); simulation.delegate = recorder
        for _ in 0..<6 { simulation.step(tickInput: TennisTickInput(human: .none, cpu: .none)) }
        XCTAssertEqual(simulation.state.pointEnd, .secondBounce(side: .cpu))
        XCTAssertEqual(DefaultTennisRuleBook().pointWinner(for: simulation.state.pointEnd!), .human)
        XCTAssertTrue(recorder.events.contains { if case .pointEnded(reason: .secondBounce(side: .cpu)) = $0.kind { return true }; return false })
    }

    func testSurfacesAndAllStatsChangeDeterministicOutcomes() {
        let hard = hitVelocity(surface: .hard, stats: PlayerStats(power: 100, speed: 100, control: 100, spin: 100))
        let clay = hitVelocity(surface: .clay, stats: PlayerStats(power: 100, speed: 100, control: 100, spin: 100))
        let grass = hitVelocity(surface: .grass, stats: PlayerStats(power: 100, speed: 100, control: 100, spin: 100))
        XCTAssertNotEqual(hard.y, clay.y); XCTAssertNotEqual(hard.y, grass.y)
        let lowPower = hitVelocity(stats: PlayerStats(power: 50, speed: 100, control: 100, spin: 100))
        let highPower = hitVelocity(stats: PlayerStats(power: 150, speed: 100, control: 100, spin: 100))
        XCTAssertNotEqual(lowPower.y, highPower.y)
        let lowControl = hitVelocity(stats: PlayerStats(power: 100, speed: 100, control: 0, spin: 100))
        let highControl = hitVelocity(stats: PlayerStats(power: 100, speed: 100, control: 100, spin: 100))
        XCTAssertNotEqual(lowControl.x, highControl.x)
        let lowSpin = hitVelocity(stats: PlayerStats(power: 100, speed: 100, control: 100, spin: 50))
        let highSpin = hitVelocity(stats: PlayerStats(power: 100, speed: 100, control: 100, spin: 150))
        XCTAssertNotEqual(lowSpin.z, highSpin.z)
        let slow = movedPosition(speed: 50); let fast = movedPosition(speed: 150)
        XCTAssertNotEqual(slow.x, fast.x)
    }

    func testFullyChargedRoutineShotHasHitstopButRoutineContactDoesNot() {
        let charged = makeSimulation(seed: 3, inFlight: true)
        charged.step(tickInput: TennisTickInput(human: .swing(sequence: .standaloneA, charge: 100), cpu: .none))
        XCTAssertEqual(charged.state.hitstopTicksRemaining, 2)
        XCTAssertEqual(charged.state.players[.human]?.hitstopTicksRemaining, 2)
        charged.step(tickInput: TennisTickInput(human: .none, cpu: .none))
        XCTAssertEqual(charged.state.hitstopTicksRemaining, 1)
        XCTAssertEqual(charged.state.players[.human]?.hitstopTicksRemaining, 1)
        let routine = makeSimulation(seed: 3, inFlight: true)
        routine.step(tickInput: TennisTickInput(human: .swing(sequence: .standaloneA, charge: 99), cpu: .none))
        XCTAssertEqual(routine.state.hitstopTicksRemaining, 0)
    }

    private struct FlightTrace {
        let shot: ShotKind
        let firstBounce: Int
        let firstOpportunity: Int
        let bounceSurface: CourtSurface?
    }

    private func flightTrace(surface: CourtSurface, sequence: TennisSwingSequence, charge: Int, ballHeight: TennisFixed) -> FlightTrace {
        let simulation = makeTraceSimulation(surface: surface, ballHeight: ballHeight)
        let recorder = EventRecorder(); simulation.delegate = recorder
        simulation.step(tickInput: TennisTickInput(human: .swing(sequence: sequence, charge: charge), cpu: .none))
        var firstOpportunity: UInt64?
        for _ in 0..<120 {
            if simulation.state.players[.cpu].map({ distanceSquared(simulation.state.ball.position, $0.position) <= 1_440_000 }) == true {
                firstOpportunity = simulation.state.tick
                break
            }
            simulation.step(tickInput: TennisTickInput(human: .none, cpu: .none))
        }
        let bounce = recorder.events.first { if case .bounce = $0.kind { return true }; return false }
        let shot = recorder.events.compactMap { event -> ShotKind? in
            if case .shotHit(side: .human, shot: let shot, quality: _) = event.kind { return shot }
            return nil
        }.first ?? .serve
        let bounceSurface: CourtSurface? = bounce.flatMap { event in
            if case .bounce(let surface) = event.kind { return surface }
            return nil
        }
        return FlightTrace(shot: shot, firstBounce: Int(bounce?.tick ?? 0), firstOpportunity: Int(firstOpportunity ?? simulation.state.tick), bounceSurface: bounceSurface)
    }

    private func serveTrace(surface: CourtSurface, charge: Int) -> FlightTrace {
        let simulation = makeSimulation(seed: 1, surface: surface); simulation.resetPoint(server: .human)
        let recorder = EventRecorder(); simulation.delegate = recorder
        simulation.step(tickInput: TennisTickInput(human: .swing(sequence: .standaloneA, charge: charge), cpu: .none))
        var firstOpportunity: UInt64?
        for _ in 0..<120 {
            if simulation.state.players[.cpu].map({ distanceSquared(simulation.state.ball.position, $0.position) <= 1_440_000 }) == true {
                firstOpportunity = simulation.state.tick
                break
            }
            simulation.step(tickInput: TennisTickInput(human: .none, cpu: .none))
        }
        let bounce = recorder.events.first { if case .bounce = $0.kind { return true }; return false }
        let bounceSurface: CourtSurface? = bounce.flatMap { event in
            if case .bounce(let surface) = event.kind { return surface }
            return nil
        }
        return FlightTrace(shot: .serve, firstBounce: Int(bounce?.tick ?? 0), firstOpportunity: Int(firstOpportunity ?? simulation.state.tick), bounceSurface: bounceSurface)
    }

    private func distanceSquared(_ a: TennisPoint, _ b: TennisPoint) -> Int64 {
        let x = Int64(a.x - b.x); let y = Int64(a.y - b.y)
        return x * x + y * y
    }

    func testSeededReplayProducesIdenticalEvents() {
        let first = makeSimulation(seed: 77); let second = makeSimulation(seed: 77)
        let a = EventRecorder(); let b = EventRecorder(); first.delegate = a; second.delegate = b
        let input = TennisTickInput(human: .swing(sequence: .aThenB, charge: 35), cpu: .none)
        for _ in 0..<4 { first.step(tickInput: input); second.step(tickInput: input) }
        XCTAssertEqual(a.events.map(EventShape.init), b.events.map(EventShape.init))
    }

    private enum BoxSet: Equatable { case normal, remote }
    private func makeSimulation(seed: UInt64, serviceBoxes: BoxSet = .normal, surface: CourtSurface = .hard, stats: PlayerStats = PlayerStats(power: 100, speed: 100, control: 100, spin: 100), inFlight: Bool = false, ballHeight: TennisFixed = 1000, ballVelocity: TennisVelocity = TennisVelocity(x: 0, y: 0, z: 0), ballPosition: TennisPoint = TennisPoint(x: 5000, y: 12000), lastHitter: TennisSide? = nil) -> TennisSimulation {
        let boundary = TennisRect(minX: 0, minY: 0, maxX: 10000, maxY: 20000)
        let top = serviceBoxes == .normal ? TennisRect(minX: 0, minY: 0, maxX: 5000, maxY: 5000) : TennisRect(minX: 20000, minY: 30000, maxX: 20100, maxY: 31000)
        let bottom = TennisRect(minX: 0, minY: 15000, maxX: 5000, maxY: 20000)
        let boxes = TennisServiceBoxes(topLeft: top, topRight: top, bottomLeft: bottom, bottomRight: bottom)
        let court = CourtRules(surface: surface, singlesBoundary: boundary, serviceBoxes: boxes, netY: 10000)
        let players = [TennisSide.human: TennisPlayerState(side: .human, position: TennisPoint(x: 5000, y: 12000), stats: stats, preset: .balanced), TennisSide.cpu: TennisPlayerState(side: .cpu, position: TennisPoint(x: 5000, y: 12000), stats: stats, preset: .power)]
        let ball = TennisBallState(position: ballPosition, height: ballHeight, velocity: ballVelocity, shotKind: .serve, lastHitter: lastHitter, isInFlight: inFlight)
        let phase: TennisPointPhase = inFlight ? .rally : .serveWindUp
        return TennisSimulation(rules: court, ruleBook: DefaultTennisRuleBook(), random: SeededTennisRandomSource(seed: seed), state: TennisSimulationState(tick: 0, server: .human, phase: phase, players: players, ball: ball))
    }
    private func makeTraceSimulation(surface: CourtSurface, ballHeight: TennisFixed = 0) -> TennisSimulation {
        let simulation = makeSimulation(seed: 1, surface: surface, inFlight: true, ballHeight: ballHeight, ballPosition: TennisPoint(x: 5000, y: 20000))
        var state = simulation.state
        let stats = PlayerStats(power: 100, speed: 100, control: 100, spin: 100)
        state.players[.human] = TennisPlayerState(side: .human, position: TennisPoint(x: 5000, y: 20000), stats: stats, preset: .balanced)
        state.players[.cpu] = TennisPlayerState(side: .cpu, position: TennisPoint(x: 5000, y: 0), stats: stats, preset: .power)
        state.ball.position = TennisPoint(x: 5000, y: 20000)
        return TennisSimulation(rules: simulation.rules, ruleBook: simulation.ruleBook, random: SeededTennisRandomSource(seed: 1), state: state)
    }
    private func hitVelocity(surface: CourtSurface = .hard, stats: PlayerStats) -> TennisVelocity { let s = makeSimulation(seed: 9, surface: surface, stats: stats, inFlight: true)
        let recorder = EventRecorder(); s.delegate = recorder; s.step(tickInput: TennisTickInput(human: .swing(sequence: .standaloneA, charge: 0), cpu: .none)); return s.state.ball.velocity }
    private func movedPosition(speed: Int) -> TennisPoint { let s = makeSimulation(seed: 1, stats: PlayerStats(power: 100, speed: speed, control: 100, spin: 100), inFlight: true); s.step(tickInput: TennisTickInput(human: .move(direction: TennisDirection(x: 1, y: 0)), cpu: .none)); return s.state.players[.human]!.position }
}

private final class EventRecorder: TennisSimulationDelegate { var events: [TennisSimulationEvent] = []; func simulationDidEmit(_ event: TennisSimulationEvent) { events.append(event) } }
private enum EventShape: Equatable {
    case serve(TennisSide), fault(TennisSide, TennisPoint), shot(TennisSide, ShotKind, ContactQuality), bounce(CourtSurface), net(TennisSide), out(TennisSide), ended(PointEndReason)
    init(_ event: TennisSimulationEvent) { switch event.kind { case .serveHit(let side): self = .serve(side); case .serveFault(let server, let landing): self = .fault(server, landing); case .shotHit(let side, let shot, let quality): self = .shot(side, shot, quality); case .bounce(let surface): self = .bounce(surface); case .netContact(let side): self = .net(side); case .outOfBounds(let side): self = .out(side); case .pointEnded(let reason): self = .ended(reason) } }
}

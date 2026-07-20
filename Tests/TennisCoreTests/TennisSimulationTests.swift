import XCTest
@testable import TennisCore

final class TennisSimulationTests: XCTestCase {
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
        let routine = makeSimulation(seed: 3, inFlight: true)
        routine.step(tickInput: TennisTickInput(human: .swing(sequence: .standaloneA, charge: 99), cpu: .none))
        XCTAssertEqual(routine.state.hitstopTicksRemaining, 0)
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
        let top = serviceBoxes == .normal ? TennisRect(minX: 0, minY: 0, maxX: 5000, maxY: 5000) : TennisRect(minX: 20000, minY: 30000, maxX: 21000, maxY: 31000)
        let bottom = TennisRect(minX: 0, minY: 15000, maxX: 5000, maxY: 20000)
        let boxes = TennisServiceBoxes(topLeft: top, topRight: top, bottomLeft: bottom, bottomRight: bottom)
        let court = CourtRules(surface: surface, singlesBoundary: boundary, serviceBoxes: boxes, netY: 10000)
        let players = [TennisSide.human: TennisPlayerState(side: .human, position: TennisPoint(x: 5000, y: 12000), stats: stats, preset: .balanced), TennisSide.cpu: TennisPlayerState(side: .cpu, position: TennisPoint(x: 5000, y: 12000), stats: stats, preset: .power)]
        let ball = TennisBallState(position: ballPosition, height: ballHeight, velocity: ballVelocity, shotKind: .serve, lastHitter: lastHitter, isInFlight: inFlight)
        return TennisSimulation(rules: court, ruleBook: DefaultTennisRuleBook(), random: SeededTennisRandomSource(seed: seed), state: TennisSimulationState(tick: 0, server: .human, players: players, ball: ball))
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

import XCTest
@testable import TennisGame

final class TennisLiveBallLegalityTests: XCTestCase {
    private let rules = TennisRules(configuration: .approvedMVP)

    private func ball(
        receiver: TennisSide = .cpu,
        phase: TennisShotType = .topspin,
        crossed: Bool = false,
        contacts: Int = 0
    ) -> TennisBallFlight {
        TennisBallFlight(
            hitter: .human,
            receiver: receiver,
            shot: phase,
            contactQuality: .good,
            origin: TennisPoint(x: 80, y: 100),
            landing: TennisPoint(x: 80, y: 40),
            position: TennisPoint(x: 80, y: crossed ? 70 : 100),
            shadow: TennisPoint(x: 80, y: 40),
            height: 12,
            elapsedMilliseconds: 0,
            contactToBounceMilliseconds: 700,
            responseWindowMilliseconds: 350,
            bounceHeight: 12,
            skidDistance: 8,
            hasCrossedNetPlane: crossed,
            consecutiveGroundContacts: contacts
        )
    }

    func testServeIsProtectedUntilItsFirstLegalLanding() {
        XCTAssertFalse(rules.isLegalReturnOpportunity(for: .cpu, phase: .serveFlight, ball: ball(phase: .serve, crossed: true)))
        XCTAssertTrue(rules.isLegalReturnOpportunity(for: .cpu, phase: .rally, ball: ball(phase: .serve, contacts: 1)))
    }

    func testRallyAllowsVolleyAfterNetCrossingAndReturnAfterFirstBounce() {
        XCTAssertTrue(rules.isLegalReturnOpportunity(for: .cpu, phase: .rally, ball: ball(crossed: true)))
        XCTAssertTrue(rules.isLegalReturnOpportunity(for: .cpu, phase: .rally, ball: ball(contacts: 1)))
        XCTAssertFalse(rules.isLegalReturnOpportunity(for: .human, phase: .rally, ball: ball(contacts: 1)))
    }

    func testSecondGroundContactClosesReturnOpportunity() {
        XCTAssertFalse(rules.isLegalReturnOpportunity(for: .cpu, phase: .rally, ball: ball(contacts: 2)))
    }

    func testCrossingStateIsDerivedFromFixedFlightPosition() {
        var flight = ball()
        flight.elapsedMilliseconds = 400
        XCTAssertTrue(rules.hasCrossedNetPlane(flight))
        XCTAssertEqual(rules.flightPosition(flight).y, 66)
    }

    func testLowFlightFailsNetClearanceGate() {
        var flight = ball()
        flight.height = 8
        XCTAssertFalse(rules.clearsNet(flight))
    }

    func testSimulationLegalServeBecomesRallyLiveAfterFirstLanding() {
        var simulation = TennisSimulation(surface: .hard, configuration: .approvedMVP)
        let empty = TennisInputFrame(movement: TennisPoint(x: 0, y: 0), pressedShotButtons: [], shotEvents: [], menuLeftPressed: false, menuRightPressed: false, menuAcceptPressed: false, servePressed: false)
        _ = simulation.advance(input: empty)
        let serve = TennisInputFrame(movement: TennisPoint(x: 0, y: 0), pressedShotButtons: [], shotEvents: [], menuLeftPressed: false, menuRightPressed: false, menuAcceptPressed: false, servePressed: true)
        _ = simulation.advance(input: serve)
        var firstBounce: TennisTickResult?
        for _ in 0..<100 {
            let tick = simulation.advance(input: empty)
            if tick.events.contains(where: { if case .bounce = $0 { return true }; return false }) {
                firstBounce = tick
                break
            }
        }
        let tick = try! XCTUnwrap(firstBounce)
        XCTAssertEqual(tick.snapshot.phase, .rally)
        XCTAssertEqual(tick.snapshot.liveBallPhase, .rally)
        XCTAssertEqual(tick.snapshot.ball?.consecutiveGroundContacts, 1)
        XCTAssertEqual(tick.snapshot.ball?.receiver, .cpu)
    }

    func testSimulationSecondGroundContactEndsWithoutReturn() {
        var configuration = TennisGameConfiguration.approvedMVP
        configuration.openingServer = .cpu
        var simulation = TennisSimulation(surface: .hard, configuration: configuration)
        let empty = TennisInputFrame(movement: TennisPoint(x: 0, y: 0), pressedShotButtons: [], shotEvents: [], menuLeftPressed: false, menuRightPressed: false, menuAcceptPressed: false, servePressed: false)
        _ = simulation.advance(input: empty)
        let serve = TennisInputFrame(movement: TennisPoint(x: 0, y: 0), pressedShotButtons: [], shotEvents: [], menuLeftPressed: false, menuRightPressed: false, menuAcceptPressed: false, servePressed: true)
        _ = simulation.advance(input: serve)
        var ended: TennisTickResult?
        var firstBounceTick: Int?
        var firstBounceWindow: UInt64 = 0
        var endTick: Int?
        for index in 0..<180 {
            let tick = simulation.advance(input: empty)
            if firstBounceTick == nil, tick.events.contains(where: { if case .bounce = $0 { return true }; return false }) {
                firstBounceTick = index
                firstBounceWindow = tick.snapshot.ball?.responseWindowMilliseconds ?? 0
            }
            if tick.snapshot.phase == .ended {
                ended = tick
                endTick = index
                break
            }
        }
        let tick = try! XCTUnwrap(ended)
        XCTAssertTrue(tick.events.contains(.pointEnded(.human, .secondBounce)), "terminal events: \(tick.events)")
        let expectedTicks = (firstBounceWindow + configuration.tickMilliseconds - 1) / configuration.tickMilliseconds
        let observedEndTick = try! XCTUnwrap(endTick)
        let observedFirstBounceTick = try! XCTUnwrap(firstBounceTick)
        XCTAssertEqual(UInt64(observedEndTick - observedFirstBounceTick), expectedTicks)
    }

    func testSimulationServeOutsideTargetEndsBeforeRally() {
        var configuration = TennisGameConfiguration.approvedMVP
        configuration.humanServeBox = TennisRect(minX: 80, minY: 40, maxX: 80, maxY: 40)
        var simulation = TennisSimulation(surface: .hard, configuration: configuration)
        let empty = TennisInputFrame(movement: TennisPoint(x: 0, y: 0), pressedShotButtons: [], shotEvents: [], menuLeftPressed: false, menuRightPressed: false, menuAcceptPressed: false, servePressed: false)
        _ = simulation.advance(input: empty)
        let serve = TennisInputFrame(movement: TennisPoint(x: 0, y: 0), pressedShotButtons: [], shotEvents: [], menuLeftPressed: false, menuRightPressed: false, menuAcceptPressed: false, servePressed: true)
        _ = simulation.advance(input: serve)
        var ended: TennisTickResult?
        for _ in 0..<100 {
            let tick = simulation.advance(input: empty)
            if tick.snapshot.phase == .ended { ended = tick; break }
        }
        let tick = try! XCTUnwrap(ended)
        XCTAssertTrue(tick.events.contains(.pointEnded(.cpu, .illegalServe)), "terminal events: \(tick.events)")
        XCTAssertEqual(tick.snapshot.liveBallPhase, .pointEnding)
    }

    func testSimulationServeOutsideSinglesBoundaryEndsAsOut() {
        var configuration = TennisGameConfiguration.approvedMVP
        configuration.humanServeBox = TennisRect(minX: -100, minY: 40, maxX: -100, maxY: 40)
        var simulation = TennisSimulation(surface: .hard, configuration: configuration)
        let empty = TennisInputFrame(movement: TennisPoint(x: 0, y: 0), pressedShotButtons: [], shotEvents: [], menuLeftPressed: false, menuRightPressed: false, menuAcceptPressed: false, servePressed: false)
        _ = simulation.advance(input: empty)
        let serve = TennisInputFrame(movement: TennisPoint(x: 0, y: 0), pressedShotButtons: [], shotEvents: [], menuLeftPressed: false, menuRightPressed: false, menuAcceptPressed: false, servePressed: true)
        _ = simulation.advance(input: serve)
        var ended: TennisTickResult?
        for _ in 0..<100 {
            let tick = simulation.advance(input: empty)
            if tick.snapshot.phase == .ended { ended = tick; break }
        }
        let tick = try! XCTUnwrap(ended)
        XCTAssertTrue(tick.events.contains(.pointEnded(.cpu, .outOfBounds)), "terminal events: \(tick.events)")
    }

    func testSimulationLowFlightRallyReturnEndsWithNetFault() {
        var configuration = TennisGameConfiguration.approvedMVP
        configuration.openingServer = .cpu
        var simulation = TennisSimulation(surface: .hard, configuration: configuration)
        let empty = TennisInputFrame(movement: TennisPoint(x: 0, y: 0), pressedShotButtons: [], shotEvents: [], menuLeftPressed: false, menuRightPressed: false, menuAcceptPressed: false, servePressed: false)
        _ = simulation.advance(input: empty)
        let serve = TennisInputFrame(movement: TennisPoint(x: 0, y: 0), pressedShotButtons: [], shotEvents: [], menuLeftPressed: false, menuRightPressed: false, menuAcceptPressed: false, servePressed: true)
        _ = simulation.advance(input: serve)
        let moveDiagonally = TennisInputFrame(movement: TennisPoint(x: 1, y: -1), pressedShotButtons: [], shotEvents: [], menuLeftPressed: false, menuRightPressed: false, menuAcceptPressed: false, servePressed: false)
        let moveRight = TennisInputFrame(movement: TennisPoint(x: 1, y: 0), pressedShotButtons: [], shotEvents: [], menuLeftPressed: false, menuRightPressed: false, menuAcceptPressed: false, servePressed: false)
        for _ in 0..<24 { _ = simulation.advance(input: moveDiagonally) }
        for _ in 0..<8 { _ = simulation.advance(input: moveRight) }
        var settled = false
        for _ in 0..<240 {
            let tick = simulation.advance(input: empty)
            if tick.snapshot.ball?.consecutiveGroundContacts == 1 { settled = true; break }
        }
        guard settled, simulation.snapshot.ball?.receiver == .human else { return XCTFail("expected human to hold a legal first-bounce return opportunity") }

        // Not smash-eligible (distance to ball shadow exceeds the smash radius), so a two-button
        // commit resolves to `.flat`, which is below the net-clearance height threshold on hard courts.
        let bothPressed = TennisInputFrame(movement: TennisPoint(x: 0, y: 0), pressedShotButtons: [.a, .b], shotEvents: [.init(button: .a, edge: .pressed), .init(button: .b, edge: .pressed)], menuLeftPressed: false, menuRightPressed: false, menuAcceptPressed: false, servePressed: false)
        _ = simulation.advance(input: bothPressed)
        let held = TennisInputFrame(movement: TennisPoint(x: 0, y: 0), pressedShotButtons: [.a, .b], shotEvents: [], menuLeftPressed: false, menuRightPressed: false, menuAcceptPressed: false, servePressed: false)
        var commitTick: TennisTickResult?
        for _ in 0..<10 {
            let tick = simulation.advance(input: held)
            if tick.events.contains(where: { if case .shotContact(.human, .flat, _, _) = $0 { return true }; return false }) { commitTick = tick; break }
        }
        guard commitTick != nil else { return XCTFail("expected human flat return contact") }

        let released = TennisInputFrame(movement: TennisPoint(x: 0, y: 0), pressedShotButtons: [], shotEvents: [.init(button: .a, edge: .released), .init(button: .b, edge: .released)], menuLeftPressed: false, menuRightPressed: false, menuAcceptPressed: false, servePressed: false)
        var ended: TennisTickResult?
        for _ in 0..<40 {
            let tick = simulation.advance(input: released)
            if tick.snapshot.phase == .ended { ended = tick; break }
        }
        let tick = try! XCTUnwrap(ended, "expected the low-flight return to end the point via net fault")
        XCTAssertTrue(tick.events.contains(.fault(.net)), "terminal events: \(tick.events)")
        XCTAssertTrue(tick.events.contains(where: { if case .pointEnded(.cpu, .netFault) = $0 { return true }; return false }), "terminal events: \(tick.events)")
        XCTAssertEqual(tick.snapshot.liveBallPhase, .pointEnding)
    }

    func testCPULegalityGateMatchesSharedReturnOpportunity() {
        let human = TennisPlayerState(side: .human, courtEnd: .near, position: TennisPoint(x: 80, y: 100), preset: .balanced)
        let cpu = TennisPlayerState(side: .cpu, courtEnd: .far, position: TennisPoint(x: 80, y: 40), preset: .power)
        let flight = ball(receiver: .cpu, crossed: true)
        var random = TennisSeededRandom(seed: 1)
        var controller = TennisCPUController()
        controller.resetForPoint(random: &random)
        let blocked = controller.advance(context: TennisCPUTacticalContext(cpu: cpu, human: human, ball: flight, contactQuality: .good, isLegalReturnOpportunity: false), elapsedMilliseconds: 350, rules: rules)
        XCTAssertTrue(blocked.actions.isEmpty)
        let allowed = controller.advance(context: TennisCPUTacticalContext(cpu: cpu, human: human, ball: flight, contactQuality: .good, isLegalReturnOpportunity: true), elapsedMilliseconds: 350, rules: rules)
        XCTAssertFalse(allowed.actions.isEmpty)
    }
}

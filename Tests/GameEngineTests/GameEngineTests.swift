import XCTest
@testable import GameEngine
@testable import SpaceInvaders

final class SpaceInvadersDisplayClientTests: XCTestCase {
    func testDisplayClientDrawCommandsProduced() async throws {
        let scene = SIScene()
        scene.awake()

        let bullet = Bullet(Point(250, 390), Vector(0, -10))
        bullet.isAlive = true
        scene.bullets.append(bullet)

        for tick in 1...3 {
            scene.step(100)
            let currentTime = UInt64(tick * 100)
            let capture = try await captureDisplayCommands(scene: scene, time: currentTime)

            XCTAssertEqual(capture.clientTick, currentTime, "client tick mismatch at tick \(tick)")
            XCTAssertFalse(capture.commands.isEmpty, "no draw commands at tick \(tick)")
        }
    }

    private func captureDisplayCommands(scene: SIScene, time: UInt64) async throws -> Capture {
        scene.didLoad = false
        scene.resourceIds = nil

        let transport = FakeDisplayTransport()
        let displayClient = DisplayClient(transport: transport, logicalSize: Size(800, 600))
        transport.client = displayClient
        let renderer = DisplayRenderClient(
            displayClient: displayClient,
            windowSize: Size<Int16>(800, 600)
        )
        renderer.defaultTime = time
        scene.draw(time, renderer)
        let resources = try XCTUnwrap(scene.resourceIds)
        await renderer.sendCommands().value
        let frame = try XCTUnwrap(transport.lastFrame())
        return Capture(clientTick: frame.clientTick, commands: frame.cmds, resources: resources)
    }
}

private struct Capture {
    let clientTick: UInt64
    let commands: [DrawCmd]
    let resources: ResourceIds
}

private final class FakeDisplayTransport: DisplayTransport {
    weak var client: DisplayClient?
    var frames: [(clientTick: UInt64, cmds: [DrawCmd])] = []

    func lastFrame() -> (clientTick: UInt64, cmds: [DrawCmd])? {
        frames.last
    }

    func send(_ message: ClientMessage) async {
        switch message {
        case let .loadResource(requestId, _, kind, _, preferredHandle):
            guard kind == .image else { return }
            let handle = preferredHandle ?? 1
            let response = Response(
                requestId: requestId,
                status: .ok,
                body: .image(handle: handle, size: Size(24, 24))
            )
            await client?.receive(.response(response))

        case let .sendFrame(clientTick, _, cmds):
            frames.append((clientTick: clientTick, cmds: cmds))

        default:
            break
        }
    }

    func send(_ message: ServerMessage) async {
    }
}

final class TennisSimulationTests: XCTestCase {
    func testSeededReplayAndHumanPriorityAreStable() {
        let first = makeSimulation(seed: 7)
        let second = makeSimulation(seed: 7)
        let recorder1 = EventRecorder(); let recorder2 = EventRecorder()
        first.delegate = recorder1; second.delegate = recorder2
        let input = TennisTickInput(human: .swing(buttons: [.a, .b], charge: 100), cpu: .swing(buttons: [.a], charge: 0))
        first.step(tickInput: input); second.step(tickInput: input)
        XCTAssertEqual(recorder1.events.map { EventShape($0) }, recorder2.events.map { EventShape($0) })
        XCTAssertTrue(recorder1.events.contains { if case .shotHit(side: .human, shot: .smash, quality: .perfect) = $0.kind { return true }; return false })
        XCTAssertEqual(first.state.ball.lastHitter, .human)
        XCTAssertEqual(first.state.hitstopTicksRemaining, 2)
    }

    func testSmashFallsBackToFlatOutsideOverheadWindow() {
        let simulation = makeSimulation(seed: 1)
        let recorder = EventRecorder(); simulation.delegate = recorder
        simulation.state.ball.isInFlight = true; simulation.state.ball.height = 400
        simulation.step(tickInput: TennisTickInput(human: .swing(buttons: [.a, .b], charge: 0), cpu: .none))
        XCTAssertTrue(recorder.events.contains { if case .shotHit(side: .human, shot: .flat, quality: .perfect) = $0.kind { return true }; return false })
        XCTAssertEqual(simulation.state.hitstopTicksRemaining, 0)
    }

    func testBounceNetAndOutEndPoints() {
        let simulation = makeSimulation(seed: 2)
        let recorder = EventRecorder(); simulation.delegate = recorder
        simulation.state.ball.isInFlight = true; simulation.state.ball.lastHitter = .human
        simulation.state.ball.height = 1; simulation.state.ball.velocity = TennisVelocity(x: 0, y: 0, z: -90)
        simulation.step(tickInput: TennisTickInput(human: .none, cpu: .none))
        XCTAssertTrue(recorder.events.contains { if case .bounce = $0.kind { return true }; return false })
        simulation.state.ball.height = 1; simulation.state.ball.velocity = TennisVelocity(x: 0, y: 0, z: -90)
        simulation.step(tickInput: TennisTickInput(human: .none, cpu: .none))
        XCTAssertEqual(simulation.state.pointEnd, .secondBounce(side: .human))

        simulation.resetPoint(server: .human)
        simulation.state.ball.isInFlight = true; simulation.state.ball.lastHitter = .human
        simulation.state.ball.height = 400; simulation.state.ball.position = TennisPoint(x: 5000, y: 9900)
        simulation.state.ball.velocity = TennisVelocity(x: 0, y: 200, z: 0)
        simulation.step(tickInput: TennisTickInput(human: .none, cpu: .none))
        XCTAssertEqual(simulation.state.pointEnd, .netFault(hitter: .human))

        simulation.resetPoint(server: .human)
        simulation.state.ball.isInFlight = true; simulation.state.ball.lastHitter = .cpu
        simulation.state.ball.height = 1; simulation.state.ball.position = TennisPoint(x: 10001, y: 5000)
        simulation.state.ball.velocity = TennisVelocity(x: 0, y: 0, z: -90)
        simulation.step(tickInput: TennisTickInput(human: .none, cpu: .none))
        XCTAssertEqual(simulation.state.pointEnd, .outOfBounds(hitter: .cpu))
    }

    func testServeAndContactQualityRules() {
        let book = DefaultTennisRuleBook()
        let boundary = TennisRect(minX: 0, minY: 0, maxX: 10000, maxY: 20000)
        let top = TennisRect(minX: 0, minY: 10000, maxX: 5000, maxY: 15000)
        let bottom = TennisRect(minX: 0, minY: 5000, maxX: 5000, maxY: 10000)
        let court = CourtRules(surface: .hard, singlesBoundary: boundary, serviceBoxes: TennisServiceBoxes(topLeft: top, topRight: top, bottomLeft: bottom, bottomRight: bottom), netY: 10000)
        XCTAssertTrue(book.isLegalServe(landing: TennisPoint(x: 2500, y: 12000), server: .human, court: court))
        XCTAssertFalse(book.isLegalServe(landing: TennisPoint(x: 2500, y: 3000), server: .human, court: court))
        XCTAssertEqual(book.contactQuality(distance: 0), .perfect)
        XCTAssertEqual(book.contactQuality(distance: 500), .good)
        XCTAssertEqual(book.contactQuality(distance: 1000), .poor)
    }

    private func makeSimulation(seed: UInt64) -> TennisSimulation {
        let boundary = TennisRect(minX: 0, minY: 0, maxX: 10000, maxY: 20000)
        let box = TennisRect(minX: 1000, minY: 10000, maxX: 9000, maxY: 15000)
        let lower = TennisRect(minX: 1000, minY: 5000, maxX: 9000, maxY: 10000)
        let boxes = TennisServiceBoxes(topLeft: box, topRight: box, bottomLeft: lower, bottomRight: lower)
        let court = CourtRules(surface: .hard, singlesBoundary: boundary, serviceBoxes: boxes, netY: 10000)
        let stats = DefaultTennisRuleBook().playerStats(for: .balanced)
        let players = [TennisSide.human: TennisPlayerState(side: .human, position: TennisPoint(x: 5000, y: 12000), stats: stats, preset: .balanced), TennisSide.cpu: TennisPlayerState(side: .cpu, position: TennisPoint(x: 5000, y: 12000), stats: stats, preset: .power)]
        let ball = TennisBallState(position: TennisPoint(x: 5000, y: 12000), height: 1000, velocity: TennisVelocity(x: 0, y: 0, z: 0), shotKind: .serve)
        return TennisSimulation(rules: court, ruleBook: DefaultTennisRuleBook(), random: SeededTennisRandomSource(seed: seed), state: TennisSimulationState(tick: 0, server: .human, players: players, ball: ball))
    }
}

private final class EventRecorder: TennisSimulationDelegate {
    var events: [TennisSimulationEvent] = []
    func simulationDidEmit(_ event: TennisSimulationEvent) { events.append(event) }
}

private enum EventShape: Equatable {
    case serve(TennisSide), shot(TennisSide, ShotKind, ContactQuality), bounce(CourtSurface), net(TennisSide), out(TennisSide), ended(PointEndReason)
    init(_ event: TennisSimulationEvent) { switch event.kind { case .serveHit(let side): self = .serve(side); case .shotHit(let side, let shot, let quality): self = .shot(side, shot, quality); case .bounce(let surface): self = .bounce(surface); case .netContact(let side): self = .net(side); case .outOfBounds(let side): self = .out(side); case .pointEnded(let reason): self = .ended(reason) } }
}

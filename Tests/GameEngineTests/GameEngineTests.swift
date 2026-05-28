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

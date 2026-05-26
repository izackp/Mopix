import XCTest
@testable import GameEngine
@testable import SpaceInvaders

final class SpaceInvadersDisplayClientTests: XCTestCase {
    func testDisplayClientMatchesRendererClientDrawCommands() async throws {
        let scene = SIScene()
        scene.awake()

        let bullet = Bullet(Point(250, 390), Vector(0, -10))
        bullet.isAlive = true
        scene.bullets.append(bullet)

        for tick in 1...3 {
            scene.step(100)
            let currentTime = UInt64(tick * 100)

            let oldCapture = try await captureRendererCommands(scene: scene, time: currentTime)
            let newCapture = try await captureDisplayCommands(scene: scene, time: currentTime)

            XCTAssertEqual(
                oldCapture.clientTick,
                newCapture.clientTick,
                "client tick mismatch at tick \(tick)"
            )
            XCTAssertEqual(
                normalize(oldCapture.commands, resources: oldCapture.resources),
                normalize(newCapture.commands, resources: newCapture.resources),
                "draw commands diverged at tick \(tick)"
            )
        }
    }

    private func captureRendererCommands(scene: SIScene, time: UInt64) async throws -> Capture {
        scene.didLoad = false
        scene.resourceIds = nil

        let server = CapturingRendererServer()
        let renderer = RendererClient([], server)
        renderer.defaultTime = time
        scene.draw(time, renderer)
        let resources = try XCTUnwrap(scene.resourceIds)
        await renderer.sendCommands().value
        let maybeCommands = await server.lastReceived()
        let commands = try XCTUnwrap(maybeCommands)
        return Capture(clientTick: time, commands: commands, resources: resources)
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

    private func normalize(_ commands: [DrawCmd], resources: ResourceIds) -> [ComparableCmd] {
        let resourceMap: [UInt64: String] = [
            resources.bullet.id: "bullet",
            resources.oryx_16bit_scifi_vehicles_105.id: "player",
            resources.oryx_16bit_scifi_vehicles_189.id: "enemy",
        ]

        return commands.map { cmd in
            let resourceName: String
            switch cmd.type {
            case let .image(resourceId):
                resourceName = resourceMap[resourceId] ?? "unknown:\(resourceId)"
            default:
                resourceName = String(describing: cmd.type)
            }

            return ComparableCmd(
                animationId: cmd.animationId,
                parentAnimationId: cmd.parentAnimationId,
                resourceName: resourceName,
                dest: cmd.dest,
                color: cmd.color.rawValue,
                alpha: cmd.alpha,
                z: cmd.z,
                rotation: cmd.rotation,
                rotationPoint: cmd.rotationPoint,
                clippingRect: cmd.clippingRect,
                time: cmd.time
            )
        }
    }
}

private struct Capture {
    let clientTick: UInt64
    let commands: [DrawCmd]
    let resources: ResourceIds
}

private struct ComparableCmd: Equatable {
    let animationId: UInt64
    let parentAnimationId: UInt64
    let resourceName: String
    let dest: Rect<Int>
    let color: UInt32
    let alpha: Float
    let z: Int
    let rotation: Float
    let rotationPoint: Point<Int>
    let clippingRect: Rect<Int>
    let time: UInt64
}

private actor CapturingRendererServer: IRendererServer {
    var received: [[DrawCmd]] = []

    func lastReceived() -> [DrawCmd]? {
        received.last
    }

    func loadResource(_ url: VDUrl) async throws -> Image {
        Image(id: 1, size: Size<UInt>(24, 24))
    }

    func loadResourceAsEditable(_ url: VDUrl) async throws -> ReadOnlyImage {
        throw GenericError("unused")
    }

    func loadResource(_ image: PixelData) async throws -> ReadOnlyImage {
        throw GenericError("unused")
    }

    func loadResources(_ urlList: [VDUrl]) async -> [Result<Image, Error>] {
        urlList.map { _ in .failure(GenericError("unused")) }
    }

    func loadResource(_ url: VDUrl, _ choosenId: UInt64) async throws -> Image {
        Image(id: choosenId, size: Size<UInt>(24, 24))
    }

    func loadResourceAsEditable(_ url: VDUrl, _ choosenId: UInt64) async throws -> ReadOnlyImage {
        throw GenericError("unused")
    }

    func loadResource(_ image: PixelData, _ choosenId: UInt64) async throws -> ReadOnlyImage {
        throw GenericError("unused")
    }

    func loadResources(_ urlList: [VDUrl], _ choosenId: [UInt64]) async -> [Result<Image, Error>] {
        zip(urlList, choosenId).map { _, id in .success(Image(id: id, size: Size<UInt>(24, 24))) }
    }

    func unloadResource(_ id: ImageResource) async {
    }

    func unloadResources(_ idList: [ImageResource]) async {
    }

    func updateImage(_ image: EditedImage) async throws -> ReadOnlyImage {
        throw GenericError("unused")
    }

    func updateImage(_ id: UInt64, _ data: PixelData) async throws {
        throw GenericError("unused")
    }

    func toImage(_ id: ImageFlyWeight) async throws -> Image {
        Image(id: id.id, size: Size<UInt>(24, 24))
    }

    func toEditableImage(_ id: ImageFlyWeight) async throws -> ReadOnlyImage {
        throw GenericError("unused")
    }

    func receiveCmds(_ list: [DrawCmd]) async {
        received.append(list)
    }
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

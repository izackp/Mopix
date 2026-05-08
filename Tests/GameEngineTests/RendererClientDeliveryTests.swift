import XCTest
@testable import GameEngine

// Minimal mock that captures commands delivered via receiveCmds.
private final class MockRendererServer: IRendererServer {
    var receivedBatches: [[DrawCmd]] = []

    func receiveCmds(_ list: [DrawCmd]) async {
        receivedBatches.append(list)
    }

    // MARK: Stub load / unload / convert — not exercised by delivery tests
    func loadResource(_ url: VDUrl) async throws -> Image { throw MockError() }
    func loadResourceAsEditable(_ url: VDUrl) async throws -> ReadOnlyImage { throw MockError() }
    func loadResource(_ image: PixelData) async throws -> ReadOnlyImage { throw MockError() }
    func loadResources(_ urlList: [VDUrl]) async -> [Result<Image, Error>] { [] }
    func loadResource(_ url: VDUrl, _ id: UInt64) async throws -> Image { throw MockError() }
    func loadResourceAsEditable(_ url: VDUrl, _ id: UInt64) async throws -> ReadOnlyImage { throw MockError() }
    func loadResource(_ image: PixelData, _ id: UInt64) async throws -> ReadOnlyImage { throw MockError() }
    func loadResources(_ urlList: [VDUrl], _ ids: [UInt64]) async -> [Result<Image, Error>] { [] }
    func unloadResource(_ id: GameEngine.ImageResource) async {}
    func unloadResources(_ idList: [GameEngine.ImageResource]) async {}
    func updateImage(_ image: EditedImage) async throws -> ReadOnlyImage { throw MockError() }
    func updateImage(_ id: UInt64, _ data: PixelData) async throws {}
    func toImage(_ id: ImageFlyWeight) async throws -> Image { throw MockError() }
    func toEditableImage(_ id: ImageFlyWeight) async throws -> ReadOnlyImage { throw MockError() }
}

private struct MockError: Error {}

// MARK: -

final class RendererClientDeliveryTests: XCTestCase {

    // Single batch of commands is delivered after awaiting the returned task.
    func testSingleBatchDelivered() async {
        let mock = MockRendererServer()
        let client = RendererClient([], mock)

        let cmd = makeCmd(animationId: 1)
        client.drawCmd(cmd)

        await client.sendCommands().value

        XCTAssertEqual(mock.receivedBatches.count, 1)
        XCTAssertEqual(mock.receivedBatches.first?.count, 1)
        XCTAssertEqual(mock.receivedBatches.first?.first?.animationId, 1)
    }

    // Empty cmdList produces no receiveCmds call.
    func testEmptyBatchSkipsDelivery() async {
        let mock = MockRendererServer()
        let client = RendererClient([], mock)

        await client.sendCommands().value

        XCTAssertTrue(mock.receivedBatches.isEmpty)
    }

    // Three sequential sendCommands() calls are chained — each waits for the
    // previous before calling receiveCmds, so they arrive in order.
    func testChainedBatchesArriveInOrder() async {
        let mock = MockRendererServer()
        let client = RendererClient([], mock)

        client.drawCmd(makeCmd(animationId: 10))
        let t1 = client.sendCommands()

        client.clearCommands()
        client.drawCmd(makeCmd(animationId: 20))
        let t2 = client.sendCommands()

        client.clearCommands()
        client.drawCmd(makeCmd(animationId: 30))
        let t3 = client.sendCommands()

        // Awaiting the last task drains the whole chain.
        await t3.value
        _ = t1  // keep strong refs alive
        _ = t2

        XCTAssertEqual(mock.receivedBatches.count, 3)
        XCTAssertEqual(mock.receivedBatches[0].first?.animationId, 10)
        XCTAssertEqual(mock.receivedBatches[1].first?.animationId, 20)
        XCTAssertEqual(mock.receivedBatches[2].first?.animationId, 30)
    }

    // clearCommands() before sendCommands() produces no delivery.
    func testClearBeforeSendProducesNoBatch() async {
        let mock = MockRendererServer()
        let client = RendererClient([], mock)

        client.drawCmd(makeCmd(animationId: 99))
        client.clearCommands()

        await client.sendCommands().value

        XCTAssertTrue(mock.receivedBatches.isEmpty)
    }
}

// MARK: - Helpers

private func makeCmd(animationId: UInt64) -> DrawCmd {
    DrawCmd(
        animationId: animationId,
        parentAnimationId: 0,
        dest: Rect(x: 0, y: 0, width: 10, height: 10),
        color: .white,
        alpha: 1,
        z: 0,
        rotation: 0,
        rotationPoint: .zero,
        clippingRect: .zero,
        flip: [],
        time: 0,
        type: .fill
    )
}

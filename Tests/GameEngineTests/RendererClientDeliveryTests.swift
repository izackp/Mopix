import XCTest
@testable import GameEngine

// MARK: - Helpers shared within this file

private final class FakeTransport: DisplayTransport {
    weak var client: DisplayClient?
    var frames: [(clientTick: UInt64, cmds: [DrawCmd])] = []

    func lastFrame() -> (clientTick: UInt64, cmds: [DrawCmd])? { frames.last }

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

    func send(_ message: ServerMessage) async {}
}

private func makeDisplayClient() -> (DisplayRenderClient, FakeTransport) {
    let transport = FakeTransport()
    let displayClient = DisplayClient(transport: transport, logicalSize: Size(800, 600))
    transport.client = displayClient
    let renderer = DisplayRenderClient(displayClient: displayClient, windowSize: Size<Int16>(800, 600))
    return (renderer, transport)
}

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

// MARK: -

final class DisplayRenderClientDeliveryTests: XCTestCase {

    // Single batch of commands is delivered after awaiting the returned task.
    func testSingleBatchDelivered() async {
        let (client, transport) = makeDisplayClient()

        let cmd = makeCmd(animationId: 1)
        client.drawCmd(cmd)

        await client.sendCommands().value

        let frame = transport.lastFrame()
        XCTAssertNotNil(frame)
        XCTAssertEqual(frame?.cmds.count, 1)
        XCTAssertEqual(frame?.cmds.first?.animationId, 1)
    }

    // Empty cmdList produces no sendFrame call.
    func testEmptyBatchSkipsDelivery() async {
        let (client, transport) = makeDisplayClient()

        await client.sendCommands().value

        XCTAssertNil(transport.lastFrame())
    }

    // Three sequential sendCommands() calls are chained — frames arrive in order.
    func testChainedBatchesArriveInOrder() async {
        let (client, transport) = makeDisplayClient()

        client.drawCmd(makeCmd(animationId: 10))
        let t1 = client.sendCommands()

        client.clearCommands()
        client.drawCmd(makeCmd(animationId: 20))
        let t2 = client.sendCommands()

        client.clearCommands()
        client.drawCmd(makeCmd(animationId: 30))
        let t3 = client.sendCommands()

        await t3.value
        _ = t1
        _ = t2

        XCTAssertEqual(transport.frames.count, 3)
        XCTAssertEqual(transport.frames[0].cmds.first?.animationId, 10)
        XCTAssertEqual(transport.frames[1].cmds.first?.animationId, 20)
        XCTAssertEqual(transport.frames[2].cmds.first?.animationId, 30)
    }

    // clearCommands() before sendCommands() produces no delivery.
    func testClearBeforeSendProducesNoBatch() async {
        let (client, transport) = makeDisplayClient()

        client.drawCmd(makeCmd(animationId: 99))
        client.clearCommands()

        await client.sendCommands().value

        XCTAssertNil(transport.lastFrame())
    }
}

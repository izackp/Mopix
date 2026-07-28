import XCTest
@testable import GameEngine

@MainActor
final class DrawCmdInterpolatorFailureTests: XCTestCase {
    func testInvalidImageHandleReportsCommandIdentityAndUnderlyingError() throws {
        let application = try Application()
        let window = try FullWindow(
            parent: application,
            title: "DrawCmdFailureTest",
            frame: Rect(x: 0, y: 0, width: 32, height: 32),
            windowOptions: [.hidden]
        )
        let command = DrawCmd(
            animationId: 42,
            parentAnimationId: 0,
            dest: Rect(x: 0, y: 0, width: 8, height: 8),
            color: .white,
            alpha: 1,
            z: 0,
            rotation: 0,
            rotationPoint: .zero,
            clippingRect: .zero,
            flip: [],
            time: 0,
            type: .image(resourceId: UInt64.max)
        )
        window.renderServer.drawingInterpolator.receiveCmds([command])

        XCTAssertThrowsError(try window.renderServer.drawingInterpolator.draw(0)) { error in
            let message = "\(String(reflecting: error)) — \(error.localizedDescription)"
            XCTAssertTrue(message.contains("type: image"))
            XCTAssertTrue(message.contains("resource: \(UInt64.max)"))
            XCTAssertTrue(message.contains("animationId: 42"))
            XCTAssertTrue(message.contains("No resource with id"))
        }
    }
}

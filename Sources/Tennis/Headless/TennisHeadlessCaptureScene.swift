import Foundation
import GameEngine
import SDL2
import SDL2Swift

@MainActor
public final class TennisHeadlessCaptureScene: HeadlessCaptureScene {
    private let controller: TennisGameController
    public private(set) var result: HeadlessCaptureResult?

    public init() throws {
        let resources = URL(fileURLWithPath: Bundle.tennis.resourcePath!).appendingPathComponent("ExternalFiles")
        try VirtualDrive.shared.mountPath(path: resources)
        controller = TennisGameController(
            configuration: .approvedMVP,
            fontURL: URL(string: "vd:/Roboto-Medium.ttf")!
        )
    }

    public func prepare(using client: DisplayClient) async throws {
        try await controller.prepare(using: client)
    }

    public func onEvents(_ events: [SDL_Event]) {
        controller.onEvents(events)
    }

    public func step(_ delta: UInt64) {
        controller.step(delta)
        guard let winner = controller.flow.result else { return }
        result = HeadlessCaptureResult(label: winner == .human ? "YOU WIN" : "CPU WINS")
    }

    public func draw(_ delta: UInt64, _ renderer: DisplayRenderClient) throws {
        try controller.draw(delta, renderer)
    }
}

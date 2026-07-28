import Foundation
import SDL2
import SDL2Swift

public struct HeadlessCaptureResult: Equatable {
    public let label: String

    public init(label: String) {
        self.label = label
    }
}

@MainActor
public protocol HeadlessCaptureScene: AnyObject, IDrawable {
    var result: HeadlessCaptureResult? { get }

    func prepare(using client: DisplayClient) async throws
    func onEvents(_ events: [SDL_Event])
    func step(_ delta: UInt64)
    func draw(_ delta: UInt64, _ renderer: DisplayRenderClient) throws
}

import Foundation
import GameEngine
import SDL2Swift

extension Bundle {
    static var tennis: Bundle { .module }
}

@MainActor
public final class TennisGameApp: Application {
    private(set) var gameWindow: FullWindow!
    private(set) var gameController: TennisGameController!

    public override init() throws {
        let fontURL = URL(string: "vd:/Roboto-Medium.ttf")!
        try super.init()
        let resources = URL(fileURLWithPath: Bundle.tennis.resourcePath!).appendingPathComponent("ExternalFiles")
        try vd.mountPath(path: resources)
        gameWindow = try FullWindow(
            parent: self,
            title: "Tennis",
            windowOptions: headlessWindowOptions,
            options: isHeadless ? [] : [Renderer.Option.presentVsync]
        )
        gameController = TennisGameController(configuration: .approvedMVP, fontURL: fontURL)
        addWindow(gameWindow)
        addFixedListener(gameController, msPerTick: Int(TennisGameConfiguration.approvedMVP.tickMilliseconds))
        addEventListener(gameController)
        gameWindow.drawable = gameController
    }

    public func prepare() async throws {
        // FullWindow starts the display-client handshake during initialization.
        // Resource requests must wait until the server has registered this client.
        try await gameWindow.waitForConnection()
        try await gameController.prepare(using: gameWindow.displayClient)
    }
}

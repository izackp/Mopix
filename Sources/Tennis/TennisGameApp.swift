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
    private let displayScale: Float = 3

    public override init() throws {
        let fontURL = URL(string: "vd:/Roboto-Medium.ttf")!
        Self.configureKeyboardRuntime()
        try super.init()
        let resources = URL(fileURLWithPath: Bundle.tennis.resourcePath!).appendingPathComponent("ExternalFiles")
        try vd.mountPath(path: resources)
        gameWindow = try FullWindow(
            parent: self,
            title: "Tennis",
            frame: Rect(x: 0, y: 0, width: Int(Float(TennisRenderer.screenWidth) * displayScale), height: Int(Float(TennisRenderer.screenHeight) * displayScale)),
            windowOptions: headlessWindowOptions,
            options: isHeadless ? [] : [Renderer.Option.presentVsync]
        )
        gameController = TennisGameController(configuration: .approvedMVP, fontURL: fontURL, windowActive: true, keyboardFocused: false)
        addWindow(gameWindow)
        addFixedListener(gameController, msPerTick: Int(TennisGameConfiguration.approvedMVP.tickMilliseconds))
        addEventListener(gameController)
        gameWindow.drawable = gameController
    }

    /// Suppresses macOS's press-and-hold accent popup so that holding a mapped key (e.g. WASD)
    /// produces the expected repeated key-down/held state instead of an OS text-input gesture.
    private static func configureKeyboardRuntime() {
        UserDefaults.standard.register(defaults: ["ApplePressAndHoldEnabled": false])
    }

    public func prepare() async throws {
        // FullWindow starts the display-client handshake during initialization.
        // Resource requests must wait until the server has registered this client.
        try await gameWindow.waitForConnection()
        try await gameWindow.displayClient.setDisplayConfig(
            logicalSize: Size(TennisRenderer.screenWidth, TennisRenderer.screenHeight),
            scale: displayScale
        )
        try await gameController.prepare(using: gameWindow.displayClient)
    }
}

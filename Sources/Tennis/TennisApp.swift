import GameEngine
import SDL2Swift

@MainActor
final class TennisApp: Application {
    static let logicalSize = Size(160, 144)

    override init() throws {
        try super.init()

        let windowFrame = Rect(
            x: 0,
            y: 0,
            width: TennisApp.logicalSize.width,
            height: TennisApp.logicalSize.height
        )
        let window = try FullWindow(
            parent: self,
            title: "Tennis",
            frame: windowFrame,
            windowOptions: headlessWindowOptions,
            options: isHeadless ? [] : [Renderer.Option.presentVsync]
        )
        window.drawable = TennisScene()
        addWindow(window)
    }
}

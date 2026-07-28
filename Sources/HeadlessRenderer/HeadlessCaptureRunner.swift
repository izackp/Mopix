import Foundation
import GameEngine
import SDL2
import SDL2Swift

@MainActor
final class HeadlessCaptureRunner {
    private let scene: any HeadlessCaptureScene
    private let client: DisplayClient
    private let renderer: DisplayRenderClient
    private let inputTimeline: [Int: [InputCommand]]
    private let screenshotTicks: Set<Int>
    private let outputDirectory: URL
    private let millisecondsPerTick: UInt64

    init(
        scene: any HeadlessCaptureScene,
        client: DisplayClient,
        renderer: DisplayRenderClient,
        inputCommands: [InputCommand],
        screenshotTicks: Set<Int>,
        outputDirectory: URL
    ) {
        self.scene = scene
        self.client = client
        self.renderer = renderer
        self.inputTimeline = buildTimeline(from: inputCommands)
        self.screenshotTicks = screenshotTicks
        self.outputDirectory = outputDirectory
        self.millisecondsPerTick = 16
    }

    func run() async throws -> HeadlessCaptureResult {
        try await scene.prepare(using: client)
        let finalInputTick = inputTimeline.keys.max() ?? 0
        let finalScreenshotTick = screenshotTicks.max() ?? 0
        let totalTicks = max(finalInputTick, finalScreenshotTick)

        guard totalTicks > 0 else {
            throw GenericError("Headless capture requires input or screenshot ticks")
        }

        for tick in 1...totalTicks {
            scene.onEvents(events(for: inputTimeline[tick] ?? []))
            scene.step(millisecondsPerTick)
            renderer.clearCommands()
            renderer.defaultTime = UInt64(tick)
            scene.draw(millisecondsPerTick, renderer)
            await renderer.sendCommands().value

            if screenshotTicks.contains(tick) {
                try await captureScreenshot(at: tick)
            }
        }

        guard let result = scene.result else {
            throw GenericError("Headless capture did not reach Result")
        }
        return result
    }

    private func events(for commands: [InputCommand]) -> [SDL_Event] {
        commands.compactMap { command in
            var event = SDL_Event()
            switch command {
            case let .keyDown(keycode, scancode):
                event.type = UInt32(SDL_KEYDOWN.rawValue)
                event.key.keysym.sym = keycode
                event.key.keysym.scancode = scancode
                event.key.state = UInt8(SDL_PRESSED)
            case let .keyUp(keycode, scancode):
                event.type = UInt32(SDL_KEYUP.rawValue)
                event.key.keysym.sym = keycode
                event.key.keysym.scancode = scancode
                event.key.state = UInt8(SDL_RELEASED)
            case let .mouseMove(x, y):
                event.type = UInt32(SDL_MOUSEMOTION.rawValue)
                event.motion.x = x
                event.motion.y = y
            case let .mouseButton(x, y, down):
                event.type = down ? UInt32(SDL_MOUSEBUTTONDOWN.rawValue) : UInt32(SDL_MOUSEBUTTONUP.rawValue)
                event.button.x = x
                event.button.y = y
                event.button.button = UInt8(SDL_BUTTON_LEFT)
                event.button.state = down ? UInt8(SDL_PRESSED) : UInt8(SDL_RELEASED)
            case .wait:
                return nil
            }
            return event
        }
    }

    private func captureScreenshot(at tick: Int) async throws {
        let (size, rgba) = try await client.screenshot()
        let hasVisiblePixel = stride(from: 0, to: rgba.count, by: 4).contains { index in
            rgba[index] != 0 || rgba[index + 1] != 0 || rgba[index + 2] != 0
        }
        guard hasVisiblePixel else {
            throw GenericError("Headless capture at tick \(tick) is black")
        }
        try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
        let outputURL = outputDirectory.appendingPathComponent("frame_\(tick).png")
        try writePNG(rgba: rgba, size: size, to: outputURL)
        print("Saved \(outputURL.path)")
    }
}

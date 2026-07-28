import Foundation
import GameEngine
import SDL2
import SDL2Swift
import SDL2_TTFSwift
import TennisGame

struct Args {
    let scenePath: URL
    let inputCommands: [InputCommand]
    let screenshotTicks: Set<Int>
    let outputDirectory: URL
}

func parseArgs() throws -> Args {
    var arguments = Array(CommandLine.arguments.dropFirst())
    var scenePath: URL?
    var inputCommands: [InputCommand] = []
    var screenshotTicks: Set<Int> = []
    var outputDirectory = URL(fileURLWithPath: "./")

    while !arguments.isEmpty {
        let flag = arguments.removeFirst()
        switch flag {
        case "--scene":
            guard !arguments.isEmpty else { throw GenericError("Missing argument for --scene") }
            scenePath = URL(fileURLWithPath: arguments.removeFirst())
        case "--inputs":
            guard !arguments.isEmpty else { throw GenericError("Missing argument for --inputs") }
            inputCommands = try parseInputCommands(arguments.removeFirst())
        case "--screenshots":
            guard !arguments.isEmpty else { throw GenericError("Missing argument for --screenshots") }
            screenshotTicks = Set(arguments.removeFirst().split(separator: ",").compactMap { Int($0) })
        case "--output-dir":
            guard !arguments.isEmpty else { throw GenericError("Missing argument for --output-dir") }
            outputDirectory = URL(fileURLWithPath: arguments.removeFirst())
        default:
            throw GenericError("Unknown argument: \(flag)")
        }
    }

    guard let scenePath else {
        throw GenericError("Usage: HeadlessRenderer --scene <path> [--inputs <commands>] [--screenshots <ticks>] [--output-dir <path>]")
    }
    return Args(
        scenePath: scenePath,
        inputCommands: inputCommands,
        screenshotTicks: screenshotTicks,
        outputDirectory: outputDirectory
    )
}

@MainActor
final class HeadlessApp: Application {
    override init() throws {
        try super.init()
        isHeadless = true
        SDL_SetHint(SDL_HINT_RENDER_DRIVER, "software")
    }
}

Task { @MainActor in
    do {
        let args = try parseArgs()
        let sceneFile = try SceneFile.load(from: args.scenePath)
        guard sceneFile.scene == .tennis else {
            throw GenericError("Unsupported headless scene")
        }

        let app = try HeadlessApp()
        let window = try FullWindow(
            parent: app,
            title: "HeadlessRenderer",
            frame: Rect(x: 0, y: 0, width: sceneFile.logicalWidth, height: sceneFile.logicalHeight),
            windowOptions: [.hidden]
        )
        app.addWindow(window)
        try await window.waitForConnection()
        try await window.displayClient.setDisplayConfig(
            logicalSize: Size(sceneFile.logicalWidth, sceneFile.logicalHeight),
            scale: sceneFile.scale
        )

        let scene = try TennisHeadlessCaptureScene()
        let runner = HeadlessCaptureRunner(
            scene: scene,
            application: app,
            window: window,
            inputCommands: args.inputCommands,
            screenshotTicks: args.screenshotTicks,
            outputDirectory: args.outputDirectory
        )
        let result = try await runner.run()
        guard result.label == sceneFile.expectedResult else {
            throw GenericError("Expected \(sceneFile.expectedResult), got \(result.label)")
        }
        print("Headless capture reached \(result.label)")
        await window.displayClient.disconnect()
        exit(EXIT_SUCCESS)
    } catch {
        fputs("Fatal error: \(String(reflecting: error))\n", stderr)
        exit(EXIT_FAILURE)
    }
}

RunLoop.main.run()

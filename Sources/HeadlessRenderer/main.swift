import Foundation
import GameEngine
import SDL2
import SDL2Swift
import SDL2_TTFSwift

// MARK: - CLI argument parsing

struct Args {
    let scenePath: URL
    let inputCommands: [InputCommand]
    let screenshotTicks: Set<Int>
    let outputDir: URL
}

func parseArgs() throws -> Args {
    var args = CommandLine.arguments.dropFirst()
    var scenePathStr: String?
    var inputsStr: String?
    var screenshotsStr: String?
    var outputDirStr: String = "./"

    while !args.isEmpty {
        let flag = args.removeFirst()
        switch flag {
        case "--scene":
            scenePathStr = args.isEmpty ? nil : String(args.removeFirst())
        case "--inputs":
            inputsStr = args.isEmpty ? nil : String(args.removeFirst())
        case "--screenshots":
            screenshotsStr = args.isEmpty ? nil : String(args.removeFirst())
        case "--output-dir":
            outputDirStr = args.isEmpty ? "./" : String(args.removeFirst())
        default:
            fputs("Unknown argument: \(flag)\n", stderr)
            exit(1)
        }
    }

    guard let sceneStr = scenePathStr else {
        fputs("Usage: HeadlessRenderer --scene <path> [--inputs \"...\"] [--screenshots \"1,5,10\"] [--output-dir ./]\n", stderr)
        exit(1)
    }

    let scenePath = URL(fileURLWithPath: sceneStr)
    let inputCmds = try inputsStr.map { try parseInputCommands($0) } ?? []
    let ticks: Set<Int> = screenshotsStr.map { str in
        Set(str.components(separatedBy: ",").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) })
    } ?? []
    let outputDir = URL(fileURLWithPath: outputDirStr)
    return Args(scenePath: scenePath, inputCommands: inputCmds, screenshotTicks: ticks, outputDir: outputDir)
}

// MARK: - HeadlessApp

final class HeadlessApp: Application {
    override init() throws {
        setenv("SDL_VIDEODRIVER", "dummy", 1)
        try super.init()
        SDL_SetHint(SDL_HINT_RENDER_DRIVER, "software")
    }
}

// MARK: - Main

Task { @MainActor in
    do {
        let args: Args
        do {
            args = try parseArgs()
        } catch {
            fputs("Error parsing arguments: \(error.localizedDescription)\n", stderr)
            exit(1)
        }

        let scene: SceneFile
        do {
            scene = try SceneFile.load(from: args.scenePath)
        } catch {
            fputs("Failed to load scene: \(error.localizedDescription)\n", stderr)
            exit(1)
        }

        let app = try HeadlessApp()
        let window = try FullWindow(parent: app, title: "HeadlessRenderer", windowOptions: [])
        app.addWindow(window)
        let logicalSize = Size<Int>(scene.logicalWidth, scene.logicalHeight)

        let (clientEnd, serverEnd) = InProcessTransport.makePair()
        let displayServer = DisplayServer(rendererServer: window.renderServer)
        displayServer.bind(serverEnd)
        let displayClient = DisplayClient(transport: clientEnd, logicalSize: logicalSize)

        try await displayClient.connect(name: "HeadlessRenderer", version: 1, logicalSize: logicalSize, resourceLingerMs: 0)
        try await displayClient.setDisplayConfig(logicalSize: logicalSize, scale: scene.scale)

        if let packName = scene.packName {
            let packURL = args.scenePath.deletingLastPathComponent().appendingPathComponent("\(packName).mopx")
            if FileManager.default.fileExists(atPath: packURL.path) {
                let data = try [UInt8](Data(contentsOf: packURL))
                try await displayClient.uploadPack(name: packName, data: data)
            }
        }

        try FileManager.default.createDirectory(at: args.outputDir, withIntermediateDirectories: true)

        let inputTimeline = buildTimeline(from: args.inputCommands)
        let maxTick = args.screenshotTicks.max() ?? 0
        let lastInputTick = inputTimeline.keys.max() ?? 0
        let totalTicks = max(maxTick, lastInputTick, 1)

        for tick in 1...totalTicks {
            if let cmds = inputTimeline[tick] {
                for cmd in cmds {
                    var sdlEvent = SDL_Event()
                    switch cmd {
                    case .keyDown(let kc, let sc):
                        sdlEvent.type = UInt32(SDL_KEYDOWN.rawValue)
                        sdlEvent.key.keysym.sym = kc
                        sdlEvent.key.keysym.scancode = sc
                        sdlEvent.key.state = UInt8(SDL_PRESSED)
                        SDL_PushEvent(&sdlEvent)
                    case .keyUp(let kc, let sc):
                        sdlEvent.type = UInt32(SDL_KEYUP.rawValue)
                        sdlEvent.key.keysym.sym = kc
                        sdlEvent.key.keysym.scancode = sc
                        sdlEvent.key.state = UInt8(SDL_RELEASED)
                        SDL_PushEvent(&sdlEvent)
                    case .mouseMove(let x, let y):
                        sdlEvent.type = UInt32(SDL_MOUSEMOTION.rawValue)
                        sdlEvent.motion.x = x
                        sdlEvent.motion.y = y
                        SDL_PushEvent(&sdlEvent)
                    case .mouseButton(let x, let y, let down):
                        sdlEvent.type = down
                            ? UInt32(SDL_MOUSEBUTTONDOWN.rawValue)
                            : UInt32(SDL_MOUSEBUTTONUP.rawValue)
                        sdlEvent.button.x = x
                        sdlEvent.button.y = y
                        sdlEvent.button.button = UInt8(SDL_BUTTON_LEFT)
                        sdlEvent.button.state = down ? UInt8(SDL_PRESSED) : UInt8(SDL_RELEASED)
                        SDL_PushEvent(&sdlEvent)
                    case .wait:
                        break
                    }
                }
            }
            SDL_PumpEvents()

            await displayClient.sendFrame(clientTick: UInt64(tick))

            if args.screenshotTicks.contains(tick) {
                do {
                    let (size, rgba) = try await displayClient.screenshot()
                    let outURL = args.outputDir.appendingPathComponent("frame_\(tick).png")
                    try writePNG(rgba: rgba, size: size, to: outURL)
                    print("Saved \(outURL.path)")
                } catch {
                    fputs("Screenshot at tick \(tick) failed: \(error.localizedDescription)\n", stderr)
                }
            }
        }

        await displayClient.disconnect()
        exit(0)
    } catch {
        fputs("Fatal error: \(error.localizedDescription)\n", stderr)
        exit(1)
    }
}

RunLoop.main.run()

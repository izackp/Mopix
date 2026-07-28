import Foundation
import SDL2
import SDL2Swift

private func pushJKeyEvent(down: Bool) {
    var event = SDL_Event()
    event.type = UInt32((down ? SDL_KEYDOWN : SDL_KEYUP).rawValue)
    event.key.keysym.sym = Int32(SDLK_j.rawValue)
    event.key.state = UInt8(down ? SDL_PRESSED : SDL_RELEASED)
    SDL_PushEvent(&event)
}

@MainActor
private func configureScoreScreenDemo(_ app: TennisGameApp) {
    guard CommandLine.arguments.contains("--score-screen") else { return }

    // Hold J across the two menu ticks, then use same-tick down/up edges for
    // each scheduled serve so servePressed is queued without starting a rally shot.
    var maxTick = 750
    if let index = CommandLine.arguments.firstIndex(of: "--ticks"),
       index + 1 < CommandLine.arguments.count,
       let parsed = Int(CommandLine.arguments[index + 1]) {
        maxTick = parsed
    }
    var keyDownTicks = Set([1])
    for serveTick in stride(from: 132, through: maxTick, by: 128) {
        keyDownTicks.insert(serveTick)
    }
    var keyUpTicks = Set([3])
    for tick in keyDownTicks where tick != 1 {
        keyUpTicks.insert(tick)
    }
    app.headlessTickHook = { tick in
        if keyDownTicks.contains(tick) { pushJKeyEvent(down: true) }
        if keyUpTicks.contains(tick) { pushJKeyEvent(down: false) }
    }
}

func tennisMain(
    argc: Int32,
    argv: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?
) -> Int32 {
    var exitCode: Int32 = EXIT_SUCCESS
    let semaphore = DispatchSemaphore(value: 0)
    Task { @MainActor in
        do {
            let app = try TennisGameApp(configuration: .approvedMVP)
            configureScoreScreenDemo(app)
            try await app.prepare()
            try await app.runLoop()
            if CommandLine.arguments.contains("--score-screen") {
                precondition(
                    app.gameController.flow.screen == .result && app.gameController.flow.result != nil,
                    "Score-screen capture did not reach Result with a winner"
                )
                print("Score-screen capture reached Result")
            }
        } catch let error as SDLError {
            fputs("Error: \(error.debugDescription)\n", stderr)
            exitCode = EXIT_FAILURE
        } catch {
            fputs("Error: \(error.localizedDescription)\n", stderr)
            exitCode = EXIT_FAILURE
        }
        semaphore.signal()
    }
    while semaphore.wait(timeout: .now()) == .timedOut {
        RunLoop.main.run(mode: .default, before: Date(timeIntervalSinceNow: 0.001))
    }
    return exitCode
}

let _ = tennisMain(argc: CommandLine.argc, argv: CommandLine.unsafeArgv)

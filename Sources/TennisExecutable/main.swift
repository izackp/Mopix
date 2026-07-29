import Foundation
import SDL2
import SDL2Swift
import TennisGame

func tennisMain(
    argc: Int32,
    argv: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?
) -> Int32 {
    var exitCode: Int32 = EXIT_SUCCESS
    let semaphore = DispatchSemaphore(value: 0)
    Task { @MainActor in
        do {
            let app = try TennisGameApp()
            try await app.prepare()
            try await app.runLoop()
        } catch let error as SDLError {
            fputs("Error: \(error.debugDescription)\n", stderr)
            exitCode = EXIT_FAILURE
        } catch {
            let message = (error as? LocalizedError)?.errorDescription
                ?? "\(String(describing: error)) (\(String(reflecting: error)))"
            fputs("Error: \(message)\n", stderr)
            exitCode = EXIT_FAILURE
        }
        semaphore.signal()
    }
    while semaphore.wait(timeout: .now()) == .timedOut {
        RunLoop.main.run(mode: .default, before: Date(timeIntervalSinceNow: 0.001))
    }
    return exitCode
}

exit(tennisMain(argc: CommandLine.argc, argv: CommandLine.unsafeArgv))

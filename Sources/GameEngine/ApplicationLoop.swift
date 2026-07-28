import Foundation
import SDL2

@MainActor
protocol ApplicationLoopDriver {
    func run(application: Application) async throws
}

@MainActor
final class RealtimeApplicationLoopDriver: ApplicationLoopDriver {
    func run(application: Application) async throws {
        while application.isRunning {
            application.readEvents()

            application.eventLogger.measure("FixedStep") {
                application.stats.measure("FixedStep") {
                    application.runFixedUpdates(currentTime: SDL_GetTicks64())
                }
            }

            application.stats.measure("Step") {
                application.runDeltaUpdatesRealtime()
            }

            await Task.yield()
            application.stats.printStats()
        }

        application.persistTimelineIfPossible()
    }
}

@MainActor
final class HeadlessApplicationLoopDriver: ApplicationLoopDriver {
    private let config: HeadlessConfig
    private let millisecondsPerTick: UInt64

    init(config: HeadlessConfig, millisecondsPerTick: UInt64 = 16) {
        self.config = config
        self.millisecondsPerTick = millisecondsPerTick
    }

    func run(application: Application) async throws {
        let maxTick = config.maxTicks
        guard maxTick > 0 else { return }
        var simulatedTime: UInt64 = 0

        for tick in 1...maxTick {
            simulatedTime += millisecondsPerTick
            application.pumpAndReadEvents()

            application.runFixedUpdates(currentTime: simulatedTime)
            application.runDeltaUpdatesHeadless(simTime: simulatedTime, delta: millisecondsPerTick)

            if config.screenshotTicks.contains(tick) || config.writeCmds {
                try await application.captureScreenshots(for: tick, outputDir: config.outputDir)
            }
        }
    }
}

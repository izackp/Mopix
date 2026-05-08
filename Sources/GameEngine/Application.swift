//
//  Application.swift
//  TestGame
//
//  Created by Isaac Paul on 4/12/22.
//

import Foundation
import SDL2
import SDL2Swift
import SDL2_TTFSwift

public protocol IUpdate : AnyObject {
    //Fixed step also takes a delta. There could be a case were we want to change
    //ticks per second or simulate multiple ticks at once
    func step(_ delta:UInt64)
}

public protocol IEventListener : AnyObject {
    func onEvents(_ events:[SDL_Event])
}


extension IUpdate {
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs === rhs
    }
}

//TODO: Weird; refactor
struct FixedUpdatedListener : Equatable {
    static func == (lhs: FixedUpdatedListener, rhs: FixedUpdatedListener) -> Bool {
        return lhs.listener === rhs.listener
    }
    
    let listener:IUpdate
    let tickBank:TickBank
}

class UpdatedListener : Equatable {
    internal init(listener: IUpdate, lastTick: UInt64) {
        self.listener = listener
        self.lastTick = lastTick
    }
    
    static func == (lhs: UpdatedListener, rhs: UpdatedListener) -> Bool {
        return lhs.listener === rhs.listener
    }
    
    let listener:IUpdate
    var lastTick:UInt64
}

struct EventListener : Equatable {
    static func == (lhs: EventListener, rhs: EventListener) -> Bool {
        return lhs.listener === rhs.listener
    }
    
    let listener:IEventListener
}

public struct HeadlessConfig {
    public let screenshotTicks: Set<Int>
    public let outputDir: URL

    public static func parse() -> HeadlessConfig? {
        var args = CommandLine.arguments.dropFirst()
        var screenshotsStr: String?
        var outputDirStr: String?
        while !args.isEmpty {
            let flag = args.removeFirst()
            switch flag {
            case "--screenshots":
                screenshotsStr = args.isEmpty ? nil : String(args.removeFirst())
            case "--output-dir":
                outputDirStr = args.isEmpty ? nil : String(args.removeFirst())
            default:
                break
            }
        }
        guard screenshotsStr != nil || outputDirStr != nil else { return nil }
        let ticks: Set<Int> = screenshotsStr.map { str in
            Set(str.components(separatedBy: ",").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) })
        } ?? []
        let outputDir = URL(fileURLWithPath: outputDirStr ?? "./")
        return HeadlessConfig(screenshotTicks: ticks, outputDir: outputDir)
    }
}

open class Application {
    var listWindows: [LiteWindow] = []

    var listFixedUpdate = MutableIteratableArray<IUpdate, FixedUpdatedListener>()
    var listUpdate = MutableIteratableArray<IUpdate, UpdatedListener>()
    var listEvent = MutableIteratableArray<IEventListener, EventListener>()


    public let vd = VirtualDrive.shared
    public let eventLogger = EventTimeline()
    //var engine:IEngine? = nil
    //var delegate:LGAppDelegate
    public var isRunning = true
    public var stats = Stats()

    public var everySecond:Double = 0
    public var skippedFrames = 0
    public var skippedTime:Int = 0
    public var lastStats:String = ""

    public let headlessConfig: HeadlessConfig?
    public var isHeadless: Bool { headlessConfig != nil }
    public var headlessWindowOptions: BitMaskOptionSet<SDLWindow.Option> { isHeadless ? [.hidden] : [] }

    static weak var _shared:Application!
    public static func shared() -> Application {
        return _shared!
    }

    public init() throws {
        headlessConfig = HeadlessConfig.parse()
        CodableTypeResolver.resolve = { try TypeMap.customDecodeSwitch($0) }
        //Note: automatically initializes the Event Handling, File I/O and Threading subsystems
        //NOTE: Present via metal is .. slow? taking 32+ms
        SDL_SetHint(SDL_HINT_RENDER_DRIVER, "opengl")

        try SDL.initialize([.video])
        try TTF.initialize()
        //engine.start()
        //let resources = Bundle.main.bundleURL.appendingPathComponent("Contents").appendingPathComponent("Resources")

        Application._shared = self
    }
    
    deinit {
        //TODO: Never called??
        TTF.quit()
        SDL.quit()
    }
    
    public func addWindow() throws -> LiteWindow {
        let window = try LiteWindow(parent: self, title: "Test", frame: Rect<Int>(origin: Point.zero, size: Size(800, 600)), windowOptions: [], driver: .default, options: [])
        addWindow(window)
        return window
    }
    
    public func addWindow(_ window:LiteWindow) {
        listWindows.append(window)
        addEventListener(window)
        addDeltaListener(window)
    }
    
    public func removeWindow(_ window:LiteWindow) {
        listWindows.removeAll(where: { $0 === window })
        removeEventListener(window)
        removeDeltaListener(window)
        if (listWindows.count == 0) {
            isRunning = false
        }
    }
    
    public func addFixedListener(_ listener:IUpdate, msPerTick:Int) {
        let tb = TickBank(startTime: SDL_GetTicks64(), timePerTick: UInt64(msPerTick), startingTick: 0)
        let listenerWrapped = FixedUpdatedListener(listener: listener, tickBank: tb)
        listFixedUpdate.append(listener, listenerWrapped)
    }
    
    public func addDeltaListener(_ listener:IUpdate) {
        let listenerWrapped = UpdatedListener(listener: listener, lastTick: 0)
        listUpdate.append(listener, listenerWrapped)
    }
    
    public func addEventListener(_ listener:IEventListener) {
        let listenerWrapped = EventListener(listener: listener)
        listEvent.append(listener, listenerWrapped)
    }
    
    public func removeDeltaListener(_ listener:IUpdate) {
        listUpdate.remove(listener)
    }
    
    public func removeFixedListener(_ listener:IUpdate) {
        listFixedUpdate.remove(listener)
    }
    
    public func removeEventListener(_ listener:IEventListener) {
        listEvent.remove(listener)
    }
    
    func readEvents() {
        
        var allEvents:[SDL_Event] = []
        eventLogger.measure("readEvents") {
            var event = SDL_Event()
            stats.measure("poll") {
                while (SDL_PollEvent(&event) == 1) {
                    //allImmediateUseEvents.append(event)
                    allEvents.append(event)
                }
            }
        }
        
        notifyEventListeners(allEvents)
    }
    
    func notifyEventListeners(_ events:[SDL_Event]) {
        if (events.count == 0) { return }
        
        eventLogger.measure("onEvents") {
            listEvent.applyChanges()
            for eachListener in listEvent.data {
                eachListener.onEvents(events)
            }
        }
    }
    
    func runFixedUpdates(currentTime: UInt64) {
        listFixedUpdate.applyChanges()
        for eachUpdateListener in listFixedUpdate.metaData {
            let regulator = eachUpdateListener.tickBank
            regulator.setCurrentTime(time: currentTime)
            var count = regulator.withdrawAll()
            while (count > 0) {
                readEvents()
                eachUpdateListener.listener.step(regulator._timePerTick)
                count -= 1
            }
        }
    }

    func runDeltaUpdatesRealtime() {
        listUpdate.applyChanges()
        for eachUpdateListener in listUpdate.metaData {
            let callTime = SDL_GetTicks64()
            let deltaTicks = callTime - eachUpdateListener.lastTick
            if deltaTicks > 0 {
                readEvents()
                stats.insertSample("delta", Double(deltaTicks) / 1000)
                eachUpdateListener.listener.step(deltaTicks)
                eachUpdateListener.lastTick = callTime
            }
        }
    }

    func runDeltaUpdatesHeadless(simTime: UInt64, delta: UInt64) {
        listUpdate.applyChanges()
        for eachUpdateListener in listUpdate.metaData {
            eachUpdateListener.listener.step(delta)
            eachUpdateListener.lastTick = simTime
        }
    }

    func pumpAndReadEvents() {
        SDL_PumpEvents()
        readEvents()
    }

    func captureScreenshots(for tick: Int, outputDir: URL) throws {
        try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)
        for window in listWindows {
            guard let fullWindow = window as? FullWindow else { continue }
            do {
                let (size, rgba) = try fullWindow.screenshot()
                let outURL = outputDir.appendingPathComponent("frame_\(tick).png")
                try writePNG(rgba: rgba, size: size, to: outURL)
                print("Saved \(outURL.path)")
            } catch {
                fputs("Screenshot at tick \(tick) failed: \(error.localizedDescription)\n", stderr)
            }
        }
    }

    func persistTimelineIfPossible() {
        if let anyPath = vd.packages.first?.path {
            do {
                let namedFile = anyPath.appendingPathComponent("timeline.json")
                try eventLogger.writeToFile(namedFile)
            } catch let error {
                print("Error saving timeline: \(error.localizedDescription)")
            }
        }
    }
    /*
    func logicTick() {
        _tickBank.setCurrentTime(time: SDL_GetTicks64())
        var count = _tickBank.withdrawAll()
        while (count > 0) {
            gameWorld.fixedStep(_tickBank._timePerTick)
            count -= 1
        }
    }
    
    func animationTick() {
        let currentTick = SDL_GetTicks64()
        let deltaTicks = currentTick - _lastTick
        if (deltaTicks > 0) {
            gameWorld.step(deltaTicks)
            _lastTick = currentTick
        }
    }*/
    
    public func runLoop() throws {
        let loopDriver: ApplicationLoopDriver
        if let config = headlessConfig {
            loopDriver = HeadlessApplicationLoopDriver(config: config)
        } else {
            loopDriver = RealtimeApplicationLoopDriver()
        }
        try loopDriver.run(application: self)
    }
}

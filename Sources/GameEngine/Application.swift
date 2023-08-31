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
    static func == (lhs: IUpdate, rhs: IUpdate) -> Bool {
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
    
    static weak var _shared:Application!
    public static func shared() -> Application {
        return _shared!
    }
    
    public init() throws {
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
    
/*
    func logic(_ events:[SDL_Event], _ delta:Int) {
        var keyCommands:[InputCommand] = []
        for event in events {
            if let command = event.toCommand() {
                keyCommands.append(command)
            }
        }
        engine?.onCommand(InputCommandList(clientId: 0, deviceId: 0, commands: keyCommands))
        engine?.onLogic()
    }*/
    
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
    
    func logic() {
        listFixedUpdate.applyChanges()
        for eachUpdateListener in listFixedUpdate.metaData {
            let regulator = eachUpdateListener.tickBank
            regulator.setCurrentTime(time: SDL_GetTicks64())
            var count = regulator.withdrawAll()
            if (count == 0) {
                //print("Skip - \(elapsedSinceStart)s")
            }
            while (count > 0) {
                //stats.measure("logic") {
                readEvents()
                eachUpdateListener.listener.step(regulator._timePerTick)
                    //logic(events, Int(count))
                //}
                //allEvents.removeAll()
                count -= 1
            }
        }
    }
    
    public func runLoop() throws {
        
        //var allImmediateUseEvents:[SDL_Event] = []

        while isRunning {
            //try autoreleasepool {
                readEvents()
            
            eventLogger.measure("FixedStep") {
                stats.measure("FixedStep") {
                    logic()
                }
            }
                
                //eventLogger.startEvent("Step")
                stats.measure("Step") {
                    listUpdate.applyChanges()
                    for eachUpdateListener in listUpdate.metaData {
                        let currentTick = SDL_GetTicks64()
                        let deltaTicks = currentTick - eachUpdateListener.lastTick
                        if (deltaTicks > 0) {
                            readEvents()
                            stats.insertSample("delta", Double(deltaTicks)/1000)
                            eachUpdateListener.listener.step(deltaTicks)
                            eachUpdateListener.lastTick = currentTick
                        }
                    }
                }
            //eventLogger.endEvent("Step")
            stats.printStats()
                
                /*
                stats.measure("poll 2") {
                    while (SDL_PollEvent(&event) == 1) {
                        allImmediateUseEvents.append(event)
                        allEvents.append(event)
                    }
                }*/
                
                /*
                stats.measure("window - Manage Window") {
                    
                    listWindows.append(contentsOf: _listWindowsPendingAdd)
                    _listWindowsPendingAdd.removeAll(keepingCapacity: true)
                    for eachItem in _listWindowsPendingRemove {
                        guard let i = listWindows.firstIndex(where: {$0 === eachItem}) else { continue }
                        listWindows.remove(at: i)
                    }
                    _listWindowsPendingRemove.removeAll(keepingCapacity: true)
                }*/
                /*
                try stats.measure("window - Whole Window") {
                    var isFirst = true
                    for eachWindow in listWindows {

                        stats.measure("window - handle events") {
                            eachWindow.handleEvents(allImmediateUseEvents)
                        }
                        
                        try eachWindow.drawStart()
                        if (isFirst) {
                            /*
                            if let window = eachWindow as? FullWindow { //Hack: Until I figure out the api between the two; ideally the engine can run without a renderer or knowledge of.
                                stats.measure("engine - draw") {
                                    engine.onDraw(eachWindow.renderer, window.imageManager) //TODO: I'm not sure how to tie the window to the engine.. lol
                                }
                                isFirst = false
                            }*/
                        }
                        //I think there should be a window view that gets tied to a camera in the engine..
                        try stats.measure("window - draw") {
                            try eachWindow.draw(time: 0)
                            
                        }
                        
                        //double before_time = (double)SDL_GetPerformanceCounter() / SDL_GetPerformanceFrequency();
                        let stopTime = CFAbsoluteTimeGetCurrent()
                        let elapsedMs = stopTime - idk
                        everySecond += elapsedMs
                        if (everySecond > 2) {
                            skippedFrames = 0
                            everySecond = elapsedMs
                            skippedTime = 0
                        }
                        idk = stopTime
                        if (elapsedMs > 0.032) {
                            skippedFrames += (Int(elapsedMs*1000) / 16) - 1
                            skippedTime = Int(elapsedMs*1000)
                            lastStats = stats.lastStats()
                        }
                        stats.measure("window - draw finish") {
                            eachWindow.drawFinish() //TODO: Tied to vsync .. We should separate to different threads or predict this somehow
                            //texture = nil
                            //https://blog.unity.com/technology/fixing-time-deltatime-in-unity-2020-2-for-smoother-gameplay-what-did-it-take
                            //Basically sample the time right after the vsync (from the hw?)
                        }
                    }
                    allImmediateUseEvents.removeAll()
                    stats.printStats()
                }*/
            //}
        }
        
        
        if let anyPath = vd.packages.first?.path {
            do {
                let namedFile = anyPath.appendingPathComponent("timeline.json")
                try eventLogger.writeToFile(namedFile)
            } catch let error {
                print("Error saving timeline: \(error.localizedDescription)")
            }
        }
    }
}

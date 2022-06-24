//
//  Application.swift
//  TestGame
//
//  Created by Isaac Paul on 4/12/22.
//

import Foundation
import SDL2
import SDL2_ttf

extension Dictionary {
    mutating func fetchOrInsert(_ key:Key, _ builder:()throws->(Value)) rethrows -> Value {
        if let item = self[key] {
            return item
        }
        
        let newItem = try builder()
        self[key] = newItem
        return newItem
    }
}

func approxRollingAverage(avg: Double, input: Double, numSamples:Double) -> Double {
    var result = avg - avg/numSamples
    result += input/numSamples
    return result
}

public class SingleStat {
    var average:Double = 0
    /*public init(average: Double) {
        self.average = average
    }*/
    
    public func measure(_ block:() throws ->()) rethrows {
        let time = CFAbsoluteTimeGetCurrent()
        try block()
        let elapsed = CFAbsoluteTimeGetCurrent() - time
        insertSample(elapsed)
    }
    
    public func insertSample(_ value:Double) {
        average = approxRollingAverage(avg: average, input: value, numSamples: 60)
    }
}

public class Stats {
    
    var stats:[String: SingleStat] = [:]
    var enabled:Bool = true
    var printDelay:Double = 10
    var lastPrint:Double = 0
    
    public func measure(_ name:String, _ block:() throws ->()) rethrows {
        if (enabled) {
            let stat = stats.fetchOrInsert(name, {SingleStat()})
            try stat.measure(block)
        } else {
            try block()
        }
    }
    
    public func insertSample(_ name:String, _ value:Double) {
        if (enabled) {
            let stat = stats.fetchOrInsert(name, {SingleStat()})
            stat.insertSample(value)
        }
    }
    
    public func printStats() {
        if (enabled == false) { return }
        let currentTime = CFAbsoluteTimeGetCurrent()
        let delta = currentTime - lastPrint
        if (delta < printDelay) { return }
        lastPrint = currentTime
        print("Stats:")
        for kvp in stats {
            let average = String(format: "%.3f", kvp.value.average)
            print("  \(average)s - \(kvp.key)")
        }
    }
}

public class StopWatch {
    var lastTime:Double
    init() {
        lastTime = CFAbsoluteTimeGetCurrent()
    }
    
    public func reset() -> Double {
        let time = lastTime
        lastTime = CFAbsoluteTimeGetCurrent()
        return lastTime - time
    }
}


public protocol LGAppDelegate {
    
}

open class Application {
    var listWindows: Arr<Window> = Arr()
    private var _listWindowsPendingRemove: Arr<Window> = Arr()
    private var _listWindowsPendingAdd: Arr<Window> = Arr()
    let vd = VirtualDrive.shared
    var engine:SpaceInvaders = SpaceInvaders()
    //var delegate:LGAppDelegate
    var isRunning = true
    var stats = Stats()
    
    public init() throws {
        //Note: automatically initializes the Event Handling, File I/O and Threading subsystems
        try SDL.initialize(subSystems: [.video])
        try TTF.initialize()
        engine.start()
        let resources = Bundle.main.bundleURL.appendingPathComponent("Contents").appendingPathComponent("Resources")
        print("Mounting: \(resources)")
        try vd.mountPath(path: resources)
    }
    
    deinit {
        TTF.quit()
        SDL.quit()
    }
    
    //TODO: Do not allow on platforms with a set number of screens
    public func addWindow() throws -> Window {
        let window = try Window(parent: self, title: "Test", frame: Frame<Int>(origin: Point.zero, size: Size(800, 600)), windowOptions: [], driver: .default, options: [])
        _listWindowsPendingAdd.append(window)
        return window
    }
    
    public func addWindow(_ window:Window) {
        _listWindowsPendingAdd.append(window)
    }

    func logic(_ events:Arr<SDL_Event>, _ delta:Int) {
        var keyCommands = Arr<InputCommand>()
        for event in events {
            if let command = event.toCommand() {
                keyCommands.append(command)
            }
        }
        engine.onCommand(InputCommandList(clientId: 0, deviceId: 0, commands: keyCommands))
        engine.onLogic()
    }
    
    public func runLoop() throws {
        var event = SDL_Event()
        let regulator = TickBank(startTime: SDL_GetTicks64(), timePerTick: 24, startingTick: 0)
        
        var allEvents = Arr<SDL_Event>.init()
        var allImmediateUseEvents:Arr<SDL_Event> = Arr<SDL_Event>.init()


        while isRunning {
            try autoreleasepool {
                while (SDL_PollEvent(&event) == 1) {
                    allImmediateUseEvents.append(event)
                    allEvents.append(event)
                }
                //TODO: Not great; ms precision will be 0 in a lot of cases without rendering
                regulator.setCurrentTime(time: SDL_GetTicks64())
                var count = regulator.withdrawAll()
                if (count == 0) {
                    //print("Skip - \(elapsedSinceStart)s")
                }
                while (count > 0) {
                    stats.measure("logic") {
                        logic(allEvents, Int(count))
                    }
                    allEvents.removeAll()
                    count -= 1
                }
                
                while (SDL_PollEvent(&event) == 1) {
                    allImmediateUseEvents.append(event)
                    allEvents.append(event)
                }
                
                listWindows.append(contentsOf: _listWindowsPendingAdd)
                _listWindowsPendingAdd.removeAll(keepingCapacity: true)
                for eachItem in _listWindowsPendingRemove {
                    guard let i = listWindows.firstIndex(where: {$0 === eachItem}) else { continue }
                    listWindows.remove(at: i)
                }
                _listWindowsPendingRemove.removeAll(keepingCapacity: true)
                
                for eachWindow in listWindows {
                    guard let conv = eachWindow as? CustomWindow else { continue }
                    
                    stats.measure("window - handle events") {
                        eachWindow.handleEvents(allImmediateUseEvents)
                    }
                    
                    try eachWindow.drawStart()
                    stats.measure("engine - draw") {
                        engine.onDraw(eachWindow.renderer, conv.imageManager) //TODO: I'm not sure how to tie the window to the engine.. lol
                    }
                    //I think there should be a window view that gets tied to a camera in the engine..
                    try stats.measure("window - draw") {
                        try eachWindow.draw(time: 0)
                    }
                    
                    stats.measure("window - draw finish") {
                        eachWindow.drawFinish() //TODO: Tied to vsync .. We should separate to different threads or predict this somehow
                    }
                }
                allImmediateUseEvents.removeAll()
                stats.printStats()
            }
        }
    }
    
    public func removeWindow(_ window:Window) {
        _listWindowsPendingRemove.append(window)
    }
}

/*
 public func runOnce() throws {
     
     // renderer
     var event = SDL_Event()
     
     SDL_PollEvent(&event)
     
     // increment ticker
     //let startTime = SDL_GetTicks()
     let eventType = SDL_EventType(rawValue: event.type)
     
     switch eventType {
         case SDL_QUIT, SDL_APP_TERMINATING:
             isRunning = false
     default:
         break
     }
     /*
     for eachWindow in listWindows {
         eachWindow.handleEvents(event)
         try eachWindow.draw()
     }*/
 }
 
 */

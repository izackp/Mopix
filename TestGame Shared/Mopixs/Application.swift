//
//  Application.swift
//  TestGame
//
//  Created by Isaac Paul on 4/12/22.
//

import Foundation
import SDL2

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
    
    public init() throws {
        //Note: automatically initializes the Event Handling, File I/O and Threading subsystems
        try SDL.initialize(subSystems: [.video])
        engine.start()
        let resources = Bundle.main.bundleURL.appendingPathComponent("Contents").appendingPathComponent("Resources")
        print("Mounting: \(resources)")
        try vd.mountPath(path: resources)
    }
    
    deinit {
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
        //allEvents.reserveCapacity(10)
        let stopWatch = StopWatch()
        let stopWatchLogic = StopWatch()
        var logicPhase:Double = 0
        var drawPhase:Double = 0
        var presentPhase:Double = 0
        var windowCommand:Double = 0
        var lastTime:UInt64 = 0
        
        let stopWatchLogic2 = StopWatch()
        while isRunning {
            try autoreleasepool {
                while (SDL_PollEvent(&event) == 1) {
                    allImmediateUseEvents.append(event)
                    allEvents.append(event)
                }
                let newTime = SDL_GetTicks64()
                let delta = newTime - lastTime
                lastTime = newTime
                //print("New round depositing \(delta)")
                regulator.deposit(time: delta)
                let count = regulator.withdrawAll()
                let elapsedSinceStart = stopWatchLogic2.reset()
                if (count > 0) {
                    let elapsed = stopWatchLogic.reset()
                    print("Time since last logic \(elapsed)s : \(count) - \(elapsedSinceStart)s")
                    logic(allEvents, Int(count))
                    allEvents.removeAll()
                } else {
                    print("Skip - \(elapsedSinceStart)s")
                }
                logicPhase = stopWatch.reset()
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
                    eachWindow.handleEvents(allImmediateUseEvents)
                    
                    windowCommand = stopWatch.reset()
                    try eachWindow.drawStart()
                    engine.onDraw(eachWindow.renderer, conv.imageManager) //TODO: I'm not sure how to tie the window to the engine.. lol
                    //I think there should be a window view that gets tied to a camera in the engine..
                    try eachWindow.draw(time: delta)
                    drawPhase = stopWatch.reset()
                    eachWindow.drawFinish() //TODO: Tied to vsync .. We should seperate to different threads or predict this somehow
                    presentPhase = stopWatch.reset()
                    print("logic: \(logicPhase)s, draw: \(drawPhase)s, present: \(presentPhase)s")
                }
                allImmediateUseEvents.removeAll()
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

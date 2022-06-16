//
//  Application.swift
//  TestGame
//
//  Created by Isaac Paul on 4/12/22.
//

import Foundation
import SDL2


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
    }
    
    public func runLoop() throws {
        var event = SDL_Event()
        let regulator = TickBank(startTime: SDL_GetTicks64(), timePerTick: 25, startingTick: 0)
        
        var allEvents = Arr<SDL_Event>.init()
        var allImmediateUseEvents:Arr<SDL_Event> = Arr<SDL_Event>.init()
        //allEvents.reserveCapacity(10)
        while isRunning {
            
            while (SDL_PollEvent(&event) == 1) {
                allImmediateUseEvents.append(event)
                allEvents.append(event)
            }
            
            regulator.deposit(time: SDL_GetTicks64())
            let count = regulator.withdrawAll()
            if (count > 0) {
                logic(allEvents, Int(count))
                allEvents.removeAll()
            }
            while (SDL_PollEvent(&event) == 1) {
                allImmediateUseEvents.append(event)
                allEvents.append(event)
            }
            
            listWindows.append(contentsOf: _listWindowsPendingAdd)
            for eachItem in _listWindowsPendingRemove {
                guard let i = listWindows.firstIndex(where: {$0 === eachItem}) else { continue }
                listWindows.remove(at: i)
            }
            _listWindowsPendingRemove.removeAll(keepingCapacity: true)
            
            for eachWindow in listWindows {
                eachWindow.handleEvents(allImmediateUseEvents)
                try eachWindow.draw(time: SDL_GetTicks64())
            }
            allImmediateUseEvents.removeAll()
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

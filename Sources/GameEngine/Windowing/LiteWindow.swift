//
//  LiteWindow.swift
//  TestGame
//
//  Created by Isaac Paul on 4/13/22.
//

import Foundation
import SDL2
import SDL2Swift

public typealias SDLWindow = SDL2Swift.Window

public protocol IDrawable {
    func draw(_ delta: UInt64, _ renderer: GameEngine.RendererClient)
}

/*
 public struct ControllerState {
     public let buttons:PressedControllerButtons
     public let analogValues:[AnalogId:Int16] = [:]
 }

public struct Controller {
     public let clientId:Int32
     public let deviceId:Int32
     public var state:ControllerState
     public var statePrevious:ControllerState
     
     mutating func updateState(_ newState:ControllerState) {
         statePrevious = state
         state = newState
     }
 }
 */

open class LiteWindow : IUpdate, IEventListener {

    internal let sdlWindow:SDLWindow
    internal let renderer:Renderer
    private var _needsDisplay:Bool = false
    public let parentApp:Application
    //private var _devices:[UInt64:Controller] = [:]
    private let _clientId:UInt32 = 0
    public var frame:Rect<Int16>
    
    public init(parent:Application,
         title:String,
         frame:Rect<Int>,
         windowOptions: BitMaskOptionSet<SDLWindow.Option> = [.resizable, .shown],
         driver: Renderer.Driver = .default,
         options: BitMaskOptionSet<Renderer.Option> = []) throws {
        
        parentApp = parent
        sdlWindow = try SDLWindow(title: title,
                                  frame: frame.toSDLTuple(),
                                   options: windowOptions)
        
        renderer = try Renderer(window: sdlWindow, driver: driver, options: options)
        self.frame = Rect(x: Int16(frame.x), y: Int16(frame.y), width: Int16(frame.width), height: Int16(frame.height))
    }
    
    public init(parent:Application,
         sdlWindow:SDLWindow,
         renderer:Renderer) throws {
        
        parentApp = parent
        self.sdlWindow = sdlWindow
        self.renderer = renderer
        let (width, height) = sdlWindow.size
        let (x, y) = sdlWindow.position
        self.frame = Rect(x: Int16(x), y: Int16(y), width: Int16(width), height: Int16(height))
    }
    
    fileprivate let keyboardDeviceId:UInt32 = 1
    
    open func onEvents(_ events: [SDL_Event]) {
        handleEvents(events)
    }
    
    //TODO: Think about whether this should propate the error upwards
    open func step(_ delta: UInt64) {
        do {
            self.parentApp.eventLogger.startEvent("draw")
            try drawStart()
            try draw(time: delta)
            self.parentApp.eventLogger.endEvent("draw")
            
            self.parentApp.eventLogger.measure("present") {
                drawFinish()
            }
        } catch let error as SDLError {
            print("Error: \(error.debugDescription)")
        } catch {
            print("Error: \(error.localizedDescription)")
        }
    }
    
    //TODO: Hide sdl
    open func handleEvents(_ events:[SDL_Event]) {
        //let filtered = events.filter({ SDL_EventType(rawValue: $0.type) == SDL_WINDOWEVENT.rawValue })
        let filtered = events.filter({ $0.type == SDL_WINDOWEVENT.rawValue })
        let windowEvents = filtered.map({ $0.window.toWindowEvent() })
        onWindowEvent(windowEvents)
        //delegate?.handleEvents(events)
        //Swap All controllers
        /*
        for key in _devices.keys {
            _devices[key]?.pushState()
        }*/
        
    }
    
    open func onMouseEnter() {
        
    }
    
    open func onMouseLeave() {
        
    }
    
    open func onMousePress() {
        
    }
    
    open func onMouseRelease() {
        
    }
    
    open func onWindowEvent(_ events:[WindowEvent]) {
        if (events.contains(WindowEvent.closeRequest)) {
            parentApp.removeWindow(self)
        }
    }

    open func drawStart() throws {
        try renderer.setDrawColor(red: 0x00, green: 0x00, blue: 0x00, alpha: 0xFF)
        try renderer.clear()
    }
    
    open func draw(time:UInt64) throws {

    }
    
    open func drawFinish() {
        parentApp.stats.measure("Present", 0.01666666) {
            renderer.present()
        }
    }
    
    func close() {
        parentApp.removeWindow(self)
    }
}
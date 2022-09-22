//
//  Window.swift
//  TestGame
//
//  Created by Isaac Paul on 4/13/22.
//

import Foundation
import SDL2

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


public enum WindowEvent {
    case none
    case shown
    case hidden
    case exposed
    case moved(x:Int32, y:Int32)
    case resized(width:Int32, height:Int32)
    case sizeChanged(width:Int32, height:Int32)
    case minimized
    case maximized
    case restored
    case mouseEnter
    case mouseLeave
    case gainedKeyboardFocus
    case lostKeyboardFocus
    case closeRequest
    case takeFocus
    case hitTest
    case iccprofChanged
    case displayChanged(displayId:Int32)
    
    init(_ event:SDL_WindowEvent) {
        let thing = SDL_WindowEventID(rawValue: UInt32(event.event) )
        switch thing {
        case SDL_WINDOWEVENT_NONE:
            self = .none
        case SDL_WINDOWEVENT_SHOWN:
            self = .shown
        case SDL_WINDOWEVENT_HIDDEN:
            self = .hidden
        case SDL_WINDOWEVENT_EXPOSED:
            self = .exposed
        case SDL_WINDOWEVENT_MOVED:
            self = .moved(x: event.data1, y: event.data2)
        case SDL_WINDOWEVENT_RESIZED:
            self = .resized(width: event.data1, height: event.data2)
        case SDL_WINDOWEVENT_SIZE_CHANGED:
            self = .sizeChanged(width: event.data1, height: event.data2)
        case SDL_WINDOWEVENT_MINIMIZED:
            self = .minimized
        case SDL_WINDOWEVENT_MAXIMIZED:
            self = .maximized
        case SDL_WINDOWEVENT_RESTORED:
            self = .restored
        case SDL_WINDOWEVENT_ENTER:
            self = .mouseEnter
        case SDL_WINDOWEVENT_LEAVE:
            self = .mouseLeave
        case SDL_WINDOWEVENT_FOCUS_GAINED:
            self = .gainedKeyboardFocus
        case SDL_WINDOWEVENT_FOCUS_LOST:
            self = .lostKeyboardFocus
        case SDL_WINDOWEVENT_CLOSE:
            self = .closeRequest
        case SDL_WINDOWEVENT_TAKE_FOCUS:
            self = .takeFocus
        case SDL_WINDOWEVENT_HIT_TEST:
            self = .hitTest
        case SDL_WINDOWEVENT_ICCPROF_CHANGED:
            self = .iccprofChanged
        case SDL_WINDOWEVENT_DISPLAY_CHANGED:
            self = .displayChanged(displayId: event.data1)
        default:
            self = .none
        }
    }
}

extension SDL_WindowEvent {
    func toWindowEvent() -> WindowEvent {
        return WindowEvent(self)
    }
}

public class Window {
    public let sdlWindow:SDLWindow
    public let renderer:SDLRenderer
    private var _needsDisplay:Bool = false
    public let parentApp:Application
    //private var _devices:[UInt64:Controller] = [:]
    private let _clientId:UInt32 = 0
    var frame:Frame<Int16>
    
    init(parent:Application,
         title:String,
         frame:Frame<Int>,
         windowOptions: BitMaskOptionSet<SDLWindow.Option> = [.resizable, .shown],
         driver: SDLRenderer.Driver = .default,
         options: BitMaskOptionSet<SDLRenderer.Option> = []) throws {
        
        parentApp = parent
        sdlWindow = try SDLWindow(title: title,
                                  frame: frame.toSDLTuple(),
                                   options: windowOptions)
        
        renderer = try SDLRenderer(window: sdlWindow, driver: driver, options: options)
        self.frame = Frame(x: Int16(frame.x), y: Int16(frame.y), width: Int16(frame.width), height: Int16(frame.height))
    }
    
    init(parent:Application,
         sdlWindow:SDLWindow,
         renderer:SDLRenderer) throws {
        
        parentApp = parent
        self.sdlWindow = sdlWindow
        self.renderer = renderer
        let (width, height) = sdlWindow.size
        let (x, y) = sdlWindow.position
        self.frame = Frame(x: Int16(x), y: Int16(y), width: Int16(width), height: Int16(height))
    }
    
    fileprivate let keyboardDeviceId:UInt32 = 1
    
    open func handleEvents(_ events:Arr<SDL_Event>) {
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
    
    open func onWindowEvent(_ events:[WindowEvent]) {
        
    }
    

    /*
    func getOrCreateController(_ clientId:UInt32, _ deviceId:UInt32) -> Controller {
        
        let id:UInt64 = (UInt64(clientId) << 32) & UInt64(deviceId)
        if let device = _devices[id] {
            return device
        }
        let newDevice = Controller(clientId: clientId, deviceId: deviceId, state: ControllerState.blank, statePrevious: ControllerState.blank)
        _devices[id] = newDevice
        return newDevice
    }
    */
    open func drawStart() throws {
        try renderer.setDrawColor(red: 0x00, green: 0x00, blue: 0x00, alpha: 0xFF)
        try renderer.clear()
    }
    
    open func draw(time:UInt64) throws {
        //if (_needsDisplay == false) { return }
        //_needsDisplay = false
        //try renderer.setDrawColor(red: 0xFF, green: 0xFF, blue: 0xFF, alpha: 0xFF)
        //try renderer.clear()
        /*
        let surface = try SDLSurface(rgb: (0, 0, 0, 0), size: (width: 1, height: 1), depth: 32)
        let color = SDLColor(
            format: try SDLPixelFormat(format: .argb8888),
            red: 25, green: 50, blue: .max, alpha: .max / 2
        )
        try surface.fill(color: color)
        let surfaceTexture = try SDLTexture(renderer: renderer, surface: surface)
        try surfaceTexture.setBlendMode([.alpha])
        try renderer.copy(surfaceTexture, destination: SDL_Rect(x: 100, y: 100, w: 200, h: 200))
         */
        
    }
    open func drawFinish() {
        renderer.present()
    }
    
    func close() {
        parentApp.removeWindow(self)
    }
}

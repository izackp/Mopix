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

public class Window {
    private let sdlWindow:SDLWindow
    public let renderer:SDLRenderer
    private var _needsDisplay:Bool = false
    public let parentApp:Application
    //private var _devices:[UInt64:Controller] = [:]
    private let _clientId:UInt32 = 0
    
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
    }
    
    init(parent:Application,
         sdlWindow:SDLWindow,
         renderer:SDLRenderer) throws {
        
        parentApp = parent
        self.sdlWindow = sdlWindow
        self.renderer = renderer
    }
    
    fileprivate let keyboardDeviceId:UInt32 = 1
    
    open func handleEvents(_ events:Arr<SDL_Event>) {
        //delegate?.handleEvents(events)
        //Swap All controllers
        /*
        for key in _devices.keys {
            _devices[key]?.pushState()
        }*/
        
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
    open func draw(time:UInt64) throws {
        if (_needsDisplay == false) { return }
        _needsDisplay = false
        try renderer.setDrawColor(red: 0xFF, green: 0xFF, blue: 0xFF, alpha: 0xFF)
        try renderer.clear()
        
        let surface = try SDLSurface(rgb: (0, 0, 0, 0), size: (width: 1, height: 1), depth: 32)
        let color = SDLColor(
            format: try SDLPixelFormat(format: .argb8888),
            red: 25, green: 50, blue: .max, alpha: .max / 2
        )
        try surface.fill(color: color)
        let surfaceTexture = try SDLTexture(renderer: renderer, surface: surface)
        try surfaceTexture.setBlendMode([.alpha])
        try renderer.copy(surfaceTexture, destination: SDL_Rect(x: 100, y: 100, w: 200, h: 200))
        
        renderer.present()
    }
    
    func close() {
        parentApp.removeWindow(self)
    }
}

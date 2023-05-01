//
//  WindowEvent.swift
//  
//
//  Created by Isaac Paul on 4/22/23.
//

import SDL2
//import SDL2Swift

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
        let thing = SDL_WindowEventID(rawValue: SDL_WindowEventID.RawValue(event.event) )
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

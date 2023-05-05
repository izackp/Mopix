//
//  Commands+SDL.swift
//  TestGame
//
//  Created by Isaac Paul on 6/9/22.
//

import Foundation
import SDL2

extension SDL_Event {
    public func toCommand() -> InputCommand? {
        let eventType = SDL_EventType(rawValue: SDL_EventType.RawValue(self.type))
        let keyValue:Int16
        if (eventType == SDL_KEYDOWN) {
            keyValue = 1
        } else if (eventType == SDL_KEYUP) {
            keyValue = 0
        } else { return nil }
        
        
        let keyEvent = self.key //TODO: foremost or window with mouse should absorb key events when
        let keyCode = SDL_KeyCode(rawValue: SDL_KeyCode.RawValue(keyEvent.keysym.sym))
        return SDL_Event.toInputCommand(keyCode, value: keyValue)
        
        /*
        switch eventType {
        //case SDL_MOUSEMOTION:
        //    let commandX = InputCommand(id: Commands.mouseX.rawValue, value: Int16(event.motion.xrel))
        //    let commandY = InputCommand(id: Commands.mouseY.rawValue, value: Int16(event.motion.yrel))
        }*/
    }
    
    public static func toInputCommand(_ key:SDL_KeyCode, value:Int16) -> InputCommand? {
        if let btn = SDL_Event.keyToButton(key) {
            return InputCommand(id: UInt32(btn.rawValue), value: value)
        }
        return nil
    }
    
    public static func keyToButton(_ key:SDL_KeyCode) -> ButtonId? {
        switch key {
        case SDLK_UP:
            return .dpadUp
        case SDLK_LEFT:
            return .dpadLeft
        case SDLK_DOWN:
            return .dpadDown
        case SDLK_RIGHT:
            return .dpadRight
        case SDLK_SPACE:
            return .back
        case SDLK_RETURN:
            return .start
        case SDLK_RSHIFT:
            return .select
        case SDLK_c:
            return .action
        case SDLK_v:
            return .action2
        case SDLK_b:
            return .action3
        case SDLK_n:
            return .leftShoulder
        case SDLK_m:
            return .rightShoulder
        default:
            return nil
        }
    }
}

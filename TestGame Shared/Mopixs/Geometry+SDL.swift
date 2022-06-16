//
//  Geometry+SDL.swift
//  TestGame
//
//  Created by Isaac Paul on 4/21/22.
//

import Foundation
import SDL2

extension Frame where T == Int {

    func toSDLTuple() -> (SDLWindow.Position, SDLWindow.Position, Int, Int) {
        return (SDLWindow.Position.point(origin.x), SDLWindow.Position.point(origin.y), size.width, size.height)
    }
    
    func toSDLSize() -> (Int, Int) {
        return (Int(size.width), Int(size.height))
    }
    func sdlRect() -> SDL_Rect {
        return SDL_Rect(x: Int32(x), y: Int32(y), w: Int32(width), h: Int32(height))
    }
}

extension Frame where T == Int32 {

    func sdlRect() -> SDL_Rect {
        return SDL_Rect(x: x, y: y, w: width, h: height)
    }
}


extension Frame where T == UInt32 {

    func sdlRect() -> SDL_Rect {
        return SDL_Rect(x: Int32(x), y: Int32(y), w: Int32(width), h: Int32(height))
    }
}

extension Frame where T == Int16 {
    func toSDLSize() -> (Int, Int) {
        return (Int(size.width), Int(size.height))
    }
    
    func sdlRect() -> SDL_Rect {
        return SDL_Rect(x: Int32(x), y: Int32(y), w: Int32(width), h: Int32(height))
    }
}

extension Frame where T == UInt16 {
    func toSDLSize() -> (Int, Int) {
        return (Int(size.width), Int(size.height))
    }
    func sdlRect() -> SDL_Rect {
        return SDL_Rect(x: Int32(x), y: Int32(y), w: Int32(width), h: Int32(height))
    }
}

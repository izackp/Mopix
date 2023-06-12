//
//  Geometry+SDL.swift
//  TestGame
//
//  Created by Isaac Paul on 4/21/22.
//

import Foundation
import SDL2
import SDL2Swift

public extension SDL_Rect {
    
    mutating func clip(_ other:Rect<DValue>) {
        if (top < other.top) {
            self.top = Int32(other.y)
        }
        if (self.left < other.left) {
            self.left = Int32(other.left)
        }
        if (bottom > other.bottom) {
            self.bottom = Int32(other.bottom)
        }
        if (self.right > other.right) {
            self.right = Int32(other.right)
        }
    }
}

extension Rect where T == Int {

    public func toSDLTuple() -> (SDLWindow.Position, SDLWindow.Position, Int, Int) {
        return (SDLWindow.Position.point(origin.x), SDLWindow.Position.point(origin.y), size.width, size.height)
    }
    
    func toSDLSize() -> (Int, Int) {
        return (Int(size.width), Int(size.height))
    }
    func sdlRect() -> SDL_Rect {
        return SDL_Rect(x: Int32(x), y: Int32(y), w: Int32(width), h: Int32(height))
    }
}

extension Rect where T == Int32 {

    func sdlRect() -> SDL_Rect {
        return SDL_Rect(x: x, y: y, w: width, h: height)
    }
}


extension Rect where T == UInt32 {

    func sdlRect() -> SDL_Rect {
        return SDL_Rect(x: Int32(x), y: Int32(y), w: Int32(width), h: Int32(height))
    }
}

extension Rect where T == Int16 {
    func toSDLSize() -> (Int, Int) {
        return (Int(size.width), Int(size.height))
    }
    
    func sdlRect() -> SDL_Rect {
        return SDL_Rect(x: Int32(x), y: Int32(y), w: Int32(width), h: Int32(height))
    }
}

extension Rect where T == UInt16 {
    func toSDLSize() -> (Int, Int) {
        return (Int(size.width), Int(size.height))
    }
    func sdlRect() -> SDL_Rect {
        return SDL_Rect(x: Int32(x), y: Int32(y), w: Int32(width), h: Int32(height))
    }
}

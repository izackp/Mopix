//
//  MouseButtonEvent+Shortcuts.swift
//  
//
//  Created by Isaac Paul on 4/22/23.
//

import SDL2

extension SDL_MouseMotionEvent {
    func pos() -> Point<DValue> {
        return Point<DValue>(DValue(x), DValue(y))
    }
    
    func previousPos() -> Point<DValue> {
        let pX = x - xrel
        let pY = y - yrel
        return Point(DValue(pX), DValue(pY))
    }
}

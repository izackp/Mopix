//
//  SDLRect+Ext.swift
//  TestGame
//
//  Created by Isaac Paul on 10/19/22.
//

import SDL2

extension SDL_Rect {
    var left : Int32 {
        get { return x }
        set {
            let diff = (newValue - x)
            x += diff
            w -= diff
        }
    }
    
    var top : Int32 {
        get { return y }
        set {
            let diff = (newValue - y)
            y += diff
            h -= diff
        }
    }
    
    var right : Int32 {
        get { return x + w }
        set {
            let diff = (newValue - right)
            w += diff
        }
    }

    var bottom : Int32 {
        get { return (y + h) }
        set {
            let diff = (newValue - bottom)
            h += diff
        }
    }
}

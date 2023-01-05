//
//  TTF.swift
//  TestGame
//
//  Created by Isaac Paul on 6/24/22.
//

import SDL2_ttf

public struct TTF {
    
    /// Use this function to initialize the SDL library.
    /// You should specify the subsystems which you will be using in your application
    ///
    /// - Note: This must be called before using most other SDL functions.
    public static func initialize() throws {
                
        try TTF_Init().sdlThrow(type: type(of: self))
    }
    
    /// Cleans up all initialized subsystems.
    ///
    /// You should call it upon all exit conditions.
    @inline(__always)
    public static func quit() {
        TTF_Quit()
    }
    
}

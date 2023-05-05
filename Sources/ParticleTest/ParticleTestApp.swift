//
//  ParticleTestApp.swift
//  
//
//  Created by Isaac Paul on 4/23/23.
//

import GameEngine
import SDL2Swift

class ParticleTestApp : Application {
    
    override init() throws {
        try super.init()
        
        #if os(iOS)
            let frame = Frame(x: 0, y: 0, width: 0, height: 0)
            let options:BitMaskOptionSet<SDLWindow.Option> = [.fullscreen]
        #else
            let frame = Frame(x: 0, y: 0, width: 800, height: 600)
            let options:BitMaskOptionSet<SDLWindow.Option> = []
        #endif

        let newWindow = try CustomWindow(parent: self, title: "My Test Game", frame: frame, windowOptions: options)
        addWindow(newWindow)
    }
    
}

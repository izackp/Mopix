//
//  File.swift
//  
//
//  Created by Isaac Paul on 4/23/23.
//

import GameEngine
import SDL2

class TestGameApp : Application {
    
    let engine:PTEngine
    
    override init() throws {
        engine = try PTEngine()
        try super.init()
        
        #if os(macOS)
        let newWindow = try PTWindow(parent: self, title: "My Test Game", frame: Frame(x: 0, y: 0, width: 800, height: 600), engine:engine)
        #else
        let newWindow = try PTWindow(parent: self, title: "My Test Game", frame: Frame(x: 0, y: 0, width: 0, height: 0), engine:engine, windowOptions: [.fullscreen])
        #endif
        
        addWindow(newWindow)
    }
    
}

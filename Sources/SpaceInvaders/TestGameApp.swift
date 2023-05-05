//
//  AppDelegate.swift
//  TestGame
//
//  Created by Isaac Paul on 4/13/22.
//

import GameEngine
import SDL2Swift
import SDL2


class TestGameApp : Application {
    
    let commandRepeater = CommandRepeater()
    let scene = SIScene()
    static var shared:TestGameApp! = nil
    
    override init() throws {
        try super.init()
        TestGameApp.shared = self
        
        //TODO: Automatically handle this in window
        #if os(iOS)
        let frame = Frame(x: 0, y: 0, width: 0, height: 0)
        let options:BitMaskOptionSet<SDLWindow.Option> = [.fullscreen]
        #else
        let frame = Frame(x: 0, y: 0, width: 800, height: 600)
        let options:BitMaskOptionSet<SDLWindow.Option> = []
        #endif
        
        let newWindow = try LiteWindow(parent: self, title: "My Test Game", frame: frame, windowOptions: options)
        addWindow(newWindow)
        newWindow.parentApp.addFixedListener(scene, msPerTick: 16)
    }
    
    
    
}

//
//  AppDelegate.swift
//  TestGame
//
//  Created by Isaac Paul on 4/13/22.
//

import Foundation
import GameEngine
import SDL2Swift
import SDL2

extension Bundle {
    public static var SpaceInvaders: Bundle = .module
}

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
        
        let newWindow = try CustomWindow(parent: self, title: "My Test Game", frame: frame, windowOptions: options)
        addWindow(newWindow)
        
        let resources = URL(fileURLWithPath: Bundle.SpaceInvaders.resourcePath!).appendingPathComponent("ExternalFiles")
        print("Mounting: \(resources)")
        try vd.mountPath(path: resources)
        
        addFixedListener(scene, msPerTick: 16)
        addEventListener(scene)
        newWindow.drawable = scene
        
        
    }
    
    
    
}

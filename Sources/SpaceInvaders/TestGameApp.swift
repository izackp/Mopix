//
//  AppDelegate.swift
//  TestGame
//
//  Created by Isaac Paul on 4/13/22.
//

import Foundation
import SDL2

class TestGameApp : Application {
    
    override init() throws {
        CodableTypeResolver.resolve = { try TypeMap.customDecodeSwitch($0) }
        //testSerialization()
        try super.init()
        //let allDisplays = SDLVideoDisplay.all
        //SDL_WINDOWPOS_CENTERED_DISPLAY Support picking a display and centering window
        //As well as saving previous settings
        //Mount Folders
        
        #if os(macOS)
        let newWindow = try SIWindow(parent: self, title: "My Test Game", frame: Frame(x: 0, y: 0, width: 800, height: 600))
        #else
        let newWindow = try SIWindow(parent: self, title: "My Test Game", frame: Frame(x: 0, y: 0, width: 0, height: 0), windowOptions: [.fullscreen])
        #endif
        
        addWindow(newWindow)
    }
    
}

//
//  CustomWindow.swift
//  TestGame
//
//  Created by Isaac Paul on 4/13/22.
//

import GameEngine

final class SIWindow: CustomWindow {
    
    override init(parent: Application,
                  title: String,
                  frame: Frame<Int>,
                  windowOptions: BitMaskOptionSet<SDLWindow.Option> = [.resizable, .shown],
                  driver: Renderer.Driver = .default,
                  options: BitMaskOptionSet<Renderer.Option> = []) throws {
        
        try super.init(parent: parent, sdlWindow: sdlWindow, renderer: renderer)
        //let vc = try UIBuilderController.build(imageManager)
        //setRootViewController(vc)
    }
}

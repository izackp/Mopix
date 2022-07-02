//
//  Engine.swift
//  TestGame
//
//  Created by Isaac Paul on 4/13/22.
//

import Foundation

//Ticks logic for the game
public class Engine {
    
    let commandRepeater = CommandRepeater()
    public var scenes:Arr<Scene> = Arr<Scene>()
    
    open func start() {
    }
    
    open func onCommand( _ list:InputCommandList) {
        commandRepeater.newTick()
        commandRepeater.onCommand(list)
    }
    
    open func onLogic() {
        for eachScene in scenes {
            eachScene.logic()
        }
    }
    
    open func onDraw(_ renderer:SDLRenderer, _ imageManager:SimpleImageManager) {
        for eachScene in scenes {
            eachScene.draw(renderer, imageManager)
        }
    }
}

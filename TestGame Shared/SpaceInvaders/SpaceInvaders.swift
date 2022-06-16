//
//  SpaceInvaders.swift
//  TestGame
//
//  Created by Isaac Paul on 5/3/22.
//

import Foundation

//I need somthing to build off of
class SpaceInvaders : Engine {
    
    func start() {
        let startScene = SIScene(self)
        scenes.append(startScene)
        startScene.awake()
    }
    
    func onCommand( _ list:InputCommandList) {
        commandRepeater.newTick()
        commandRepeater.onCommand(list)
    }
    
    func onLogic() {
        for eachScene in scenes {
            eachScene.logic()
        }
    }
    
    func onDraw() {
        for eachScene in scenes {
            eachScene.draw()
        }
    }
}



//
//  Engine.swift
//  TestGame
//
//  Created by Isaac Paul on 4/13/22.
//

import SDL2Swift

public protocol IEngine {
    
    func start()
    func onCommand( _ list:InputCommandList)
    func onLogic()
    //func onDraw(_ renderer:RendererWrapped)
}


//Ticks logic for the game
public class Engine : IEngine {
    
    let commandRepeater = CommandRepeater()
    public var scenes:[IScene] = []
    
    open func start() {
        //if (emitter == nil) { emitter = buildEmitter(false) }
    }
    
    open func onCommand( _ list:InputCommandList) {
        commandRepeater.newTick()
        commandRepeater.onCommand(list)
    }
    
    open func onLogic() {
        for eachScene in scenes {
            eachScene.logic(0)
        }
    }
    
    open func onDraw(_ renderer:BatchRenderer) {
        for eachScene in scenes {
            eachScene.draw(renderer)
        }
    }
}

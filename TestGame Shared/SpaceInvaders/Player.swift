//
//  Player.swift
//  TestGame
//
//  Created by Isaac Paul on 6/16/22.
//

import Foundation

class Player : IVirutalControllerListener {
    
    internal init(pos: Point<Int> = Point<Int>.zero, clientId: UInt32 = 0, deviceId: UInt32 = 0) {
        self.pos = pos
        self.clientId = clientId
        self.deviceId = deviceId
    }
    
    var pos = Point<Int>.zero
    var vel = Vector<Int>.zero
    var clientId:UInt32 = 0
    var deviceId:UInt32 = 0
    weak var scene:SIScene!
    
    func onInit(_ clientId:UInt32, _ deviceId:UInt32) {
        self.clientId = clientId
        self.deviceId = deviceId
    }
    
    func awake() {
        scene.engine.commandRepeater.addListener(clientId, deviceId, self)
    }
    
    deinit {
        scene.engine.commandRepeater.removeListener(clientId, deviceId, self)
    }
    
    func logic() {
        pos.x += vel.x
        pos.y += vel.y
    }
    
    func onInput(_ controller: VirtualController) {
        for eachCommand in controller.state.commands {
            guard
                let commandEnum = CommandId(rawValue: eachCommand.id),
                let button = commandEnum.buttonId
            else { continue }
            
            if (eachCommand.value == 1) {
                switch (button) {
                case ButtonId.dpadLeft: vel.x = -3; break
                case ButtonId.dpadRight: vel.x = 3; break
                default: break
                }
            } else {
                if (vel.x < 0 && button == ButtonId.dpadLeft) {
                    vel.x = 0
                }
                if (vel.x > 0 && button == ButtonId.dpadRight) {
                    vel.x = 0
                }
                if (button == ButtonId.action) {
                    let i = Bullet(self.pos + Point<Int>(0, -10), Vector(0, -10))
                    i.isAlive = true
                    scene.bullets.append(i)
                }
            }
        }
    }
    
    /*
    func onCommandList(_ inputCommandList: InputCommandList) {
        if (inputCommandList.clientId != clientId || inputCommandList.deviceId != deviceId) {
            return
        }
        for eachCommand in inputCommandList.commands {
            switch (eachCommand.commandId) {
            case .btnAction:
                shoot()
                
            case .btnLStickX:
                fallthrough
            case .btnDPadX:
                move(eachCommand.value)
            default:
                break
            }
        }
    }*/
    
    func move(_ dir:Int32) {
        let targetX = pos.x + Int(dir)
        if (targetX < 0 || targetX > scene.bounds.right) {
            return
        }
        pos.x = targetX
    }
    
    func shoot() {
        let bullet = Bullet(pos + Point(0, -10), Vector(0, -10))
        scene.bullets.append(bullet)
    }
    
    func draw() {
        
    }
}

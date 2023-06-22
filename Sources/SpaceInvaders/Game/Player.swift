//
//  Player.swift
//  TestGame
//
//  Created by Isaac Paul on 6/16/22.
//

import GameEngine

class Player : IVirutalControllerListener {
    
    internal init(pos: Point<Int> = Point<Int>.zero, clientId: UInt32 = 0, deviceId: UInt32 = 0) {
        self.pos = pos
        self.clientId = clientId
        self.deviceId = deviceId
    }
    
    var pos = Point<Int>.zero
    var vel = Vector<Int>.zero
    let size = Size<Int>(24, 24)
    var rot:Float = 0
    var clientId:UInt32 = 0
    var deviceId:UInt32 = 0
    let uuid = Xoroshiro.shared.randomBytes()
    weak var scene:SIScene!
    
    func onInit(_ clientId:UInt32, _ deviceId:UInt32) {
        self.clientId = clientId
        self.deviceId = deviceId
    }
    
    func awake() {
        scene.commandRepeater.addListener(clientId, deviceId, self)
    }
    
    deinit {
        scene.commandRepeater.removeListener(clientId, deviceId, self)
    }
    
    func logic(_ delta:UInt64) {
        //NOTE: The slowest you can go is 1 per ms.. otherwise using ints we truncate the value and lose determinism
        //We can go slower by using a lower resolution delta.. but its obviously not good
        //The only solution is storing a fixed point
        //Or guaranteeing delta is a multiple of 2; Because we can just do delta >> 1
        //for each multiple we can guarantee the higher we can shift. 2 == 1, 4 == 2, 8 == 3
        //Not sure what to do with this information.. or what kind of assumptions you can make.
        //I originally wanted to tick at 16, but lets say I decided 20.. it would cause issues if I shifted by 3
        pos.x += vel.x * Int(delta >> 2)
        pos.y += vel.y * Int(delta >> 2) //Now velocity is 1 per 4ms
        rot -= 8
        if (rot < 0) {
            rot += 360
        }
    }
    
    func onInput(_ controller: VirtualController) {
        for eachCommand in controller.state.commands {
            guard
                let commandEnum = CommandId(rawValue: eachCommand.id),
                let button = commandEnum.buttonId
            else { continue }
            
            if (eachCommand.value == 1) {
                switch (button) {
                case ButtonId.dpadLeft: vel.x = -1; break
                case ButtonId.dpadRight: vel.x = 1; break
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

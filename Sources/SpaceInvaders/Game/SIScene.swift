//
//  SIScene.swift
//  TestGame
//
//  Created by Isaac Paul on 6/16/22.
//

import GameEngine
import SDL2

struct Resources {
    static let oryx_16bit_scifi_vehicles_105 = VDUrl(string: "vd:/oryx_16bit_scifi_vehicles_105.bmp")!
    static let oryx_16bit_scifi_vehicles_189 = VDUrl(string: "vd:/oryx_16bit_scifi_vehicles_189.bmp")!
    static let bullet = VDUrl(string: "vd:/bullet.bmp")!
}


public class SIScene : IScene, IUpdate, IDrawable {
    var enemies = EntityPool<Enemy>()
    var player:Player! = Player()
    var bullets:[Bullet] = []
    var collisionNodes:[CollisionNode2D] = []
    var bounds:Frame<Int> = Frame(x: 0, y: 0, width: 800, height: 600)
    var isAwake = false
    
    public init() {
    }
    
    public func awake() {
        isAwake = true
        player.scene = self
        player.awake()
        bullets.removeAll()
        let startPosX = 40
        let spacingX = 40
        let startPosY = 40
        let spacingY = 40
        let start = Point(startPosX, startPosY)
        enemies.create([Enemy(start.offset(0, 0)),
                        Enemy(start.offset(spacingX * 1, 0)),
                        Enemy(start.offset(spacingX * 2, 0)),
                        Enemy(start.offset(spacingX * 3, 0)),
                        Enemy(start.offset(0, spacingY)),
                        Enemy(start.offset(spacingX * 1, spacingY)),
                        Enemy(start.offset(spacingX * 2, spacingY)),
                        Enemy(start.offset(spacingX * 3, spacingY))])
        
        player.pos = Point(250, 400)
    }
    
    var commandRepeater:CommandRepeater = CommandRepeater()
    
    
    var keyCommands:[InputCommand] = []
    func onEvents(_ events: [SDL_Event]) {
        if (isAwake == false) {
            awake()
        }
        //Wrap sdl_event; add 'use' counter
        for event in events {
            //ignore used events
            if let command = event.toCommand() {
                keyCommands.append(command)
            }
        }
        
    }
    
    public func step(_ delta: UInt64) {
        if (isAwake == false) {
            awake()
        }
        //Input pass; Tbh.. we could process it immediately.. or not. what if we do something different on 2 presses
        //vs 1 press.. yea.. better to batch it
        let list = InputCommandList(clientId: 0, deviceId: 0, commands: keyCommands)
        commandRepeater.onCommand(list)
        //Remember ordering is important.
        // Lets say this was a multiplayer game.. we need to apply some sorting to the input
        //
        logic()
        
        //
        commandRepeater.newTick()
        keyCommands.removeAll(keepingCapacity: true)
    }
    
    public func logic() {
        enemies.insertPending()
        enemies.forEach { (eachEnemy:inout Enemy) in
            eachEnemy.isAlive = true
            if (eachEnemy.isAlive) {
                eachEnemy.logic()
            }
        }
        
        player.logic()
        
        for eachBullet in bullets {
            if (eachBullet.isAlive) {
                eachBullet.logic(self)
            }
        }
    }
    
    //Scenes don't need to draw
    //Cameras do
    //Can't use texture backed resources
    //So we use strings as references.
    public func draw(_ renderer: RendererWrapped) {
        //let bullet = imageManager.image(named: "bullet.bmp")
        //let playerSprite = imageManager.image(named: "oryx_16bit_scifi_vehicles_105.bmp")
        //let enemySprite = imageManager.image(named: "oryx_16bit_scifi_vehicles_189.bmp")
        var dest = Frame<Int>.init(origin: .zero, size: Size(24, 24))
        for eachBullet in bullets {
            if (eachBullet.isAlive) {
                dest.origin = eachBullet.pos
                renderer.draw(Resources.bullet, rect: dest)
            }
        }
        enemies.forEach { (eachEnemy:inout Enemy) in
            if (eachEnemy.isAlive) {
                dest.origin = eachEnemy.pos
                renderer.draw(Resources.oryx_16bit_scifi_vehicles_189, rect: dest)
            }
        }
        
        dest.origin = player.pos
        renderer.draw(Resources.oryx_16bit_scifi_vehicles_105, rect: dest)
    }
}

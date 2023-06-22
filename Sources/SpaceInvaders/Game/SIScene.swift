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

struct ResourceIds {
    var oryx_16bit_scifi_vehicles_105:UInt64 = 0
    var oryx_16bit_scifi_vehicles_189:UInt64 = 0
    var bullet:UInt64 = 0
}

public class SIScene : IScene, IUpdate, IDrawable, IEventListener, IResourceCache {

    var enemies = EntityPool<Enemy>()
    var player:Player! = Player()
    var bullets:[Bullet] = []
    var collisionNodes:[CollisionNode2D] = []
    var bounds:Rect<Int> = Rect(x: 0, y: 0, width: 800, height: 600)
    var isAwake = false
    var resourceIds = ResourceIds()
    
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
    
    
    public func invalidateCache(_ client:RendererClient) {
        resourceIds.bullet = 0
        resourceIds.oryx_16bit_scifi_vehicles_105 = 0
        resourceIds.oryx_16bit_scifi_vehicles_189 = 0
    }

    public func loadResources(_ renderer:RendererClient) throws {
        let results = try renderer.loadResources([
            Resources.bullet,
            Resources.oryx_16bit_scifi_vehicles_105,
            Resources.oryx_16bit_scifi_vehicles_189])
        resourceIds.bullet = results[0]
        resourceIds.oryx_16bit_scifi_vehicles_105 = results[1]
        resourceIds.oryx_16bit_scifi_vehicles_189 = results[2]
    }

    public func unloadResources(_ renderer:RendererClient) {
        let items = [resourceIds.bullet, resourceIds.oryx_16bit_scifi_vehicles_105, resourceIds.oryx_16bit_scifi_vehicles_189]
        renderer.unloadResources(items)
        invalidateCache(renderer)
    }
    
    var commandRepeater:CommandRepeater = CommandRepeater()
    
    var keyCommands:[InputCommand] = []
    public func onEvents(_ events: [SDL_Event]) {
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
        
        if (keyCommands.count > 0) {
            let list = InputCommandList(clientId: 0, deviceId: 0, commands: keyCommands)
            commandRepeater.onCommand(list)
        }
        logic(delta)
        
        commandRepeater.newTick()
        if (keyCommands.count > 0) {
            keyCommands.removeAll(keepingCapacity: true)
        }
    }
    
    var state = 0 // 0 none, 1 logic, 2 drawn
    public func logic(_ delta: UInt64) {
        enemies.insertPending()
        enemies.forEach { (eachEnemy:inout Enemy) in
            eachEnemy.isAlive = true
            if (eachEnemy.isAlive) {
                eachEnemy.logic(delta)
            }
        }
        
        player.logic(delta)
        
        for eachBullet in bullets {
            if (eachBullet.isAlive) {
                eachBullet.logic(self, delta)
            }
        }
        state = 1
    }
    
    //Can't use texture backed resources
    //So we use ids/strings as references.
    var didLoad = false
    public func draw(_ delta:UInt64, _ renderer: RendererClient) {
        if (didLoad == false) {
            try? loadResources(renderer)
            didLoad = true
        }
        //if (state == 2) { return }
        var dest = Rect<Int>.init(origin: .zero, size: Size(24, 24))
        for eachBullet in bullets {
            if (eachBullet.isAlive) {
                dest.origin = eachBullet.pos
                renderer.draw(eachBullet.uuid, resourceIds.bullet, dest)
            }
        }
        enemies.forEach { (eachEnemy:inout Enemy) in
            if (eachEnemy.isAlive) {
                dest.origin = eachEnemy.pos
                renderer.draw(eachEnemy.uuid, resourceIds.oryx_16bit_scifi_vehicles_189, dest)
                return;
            }
        }
        
        dest.origin = player.pos
        renderer.draw(player.uuid, resourceIds.oryx_16bit_scifi_vehicles_105, dest, SDLColor.white, 1, player.rot, player.size.center())
        state = 2
    }
}

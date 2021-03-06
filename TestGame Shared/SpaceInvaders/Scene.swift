//
//  Scene.swift
//  TestGame
//
//  Created by Isaac Paul on 6/16/22.
//

import Foundation

public class Scene {
    
    var engine:Engine
    init(_ engine:Engine) {
        self.engine = engine
    }
    
    open func awake() {
        
    }
    
    open func logic() {
        
    }
    
    open func draw(_ renderer:SDLRenderer, _ imageManager:SimpleImageManager) {
        
    }
}

public class SIScene : Scene {
    var enemies = EntityPool<Enemy>()
    var player:Player! = Player()
    var bullets:Arr<Bullet> = Arr<Bullet>()
    var collisionNodes:Arr<CollisionNode2D> = Arr<CollisionNode2D>()
    var bounds:Frame<Int> = Frame(x: 0, y: 0, width: 800, height: 600)
    
    override init(_ engine:Engine) {
        super.init(engine)
        player.scene = self
        player.awake()
    }
    
    public override func awake() {
        bullets.removeAll()
        let startPosX = 40
        let spacingX = 40
        let startPosY = 40
        let spacingY = 40
        let start = Point(startPosX, startPosY)
        enemies.create([Enemy(start.offset(0, 0)), Enemy(start.offset(spacingX * 1, 0)), Enemy(start.offset(spacingX * 2, 0)), Enemy(start.offset(spacingX * 3, 0)), Enemy(start.offset(0, spacingY)), Enemy(start.offset(spacingX * 1, spacingY)), Enemy(start.offset(spacingX * 2, spacingY)), Enemy(start.offset(spacingX * 3, spacingY))])
        
        player.pos = Point(250, 400)
    }
    
    public override func logic() {
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
    
    public override func draw(_ renderer: SDLRenderer, _ imageManager: SimpleImageManager) {
        let bullet = imageManager.image(named: "bullet.bmp")
        let playerSprite = imageManager.image(named: "oryx_16bit_scifi_vehicles_105.bmp")
        let enemySprite = imageManager.image(named: "oryx_16bit_scifi_vehicles_189.bmp")
        var bulletBox = Frame<Int>.init(origin: .zero, size: Size(24, 24))
        for eachBullet in bullets {
            if (eachBullet.isAlive) {
                bulletBox.origin = eachBullet.pos
                bullet?.draw(renderer, bulletBox.sdlRect())
            }
        }
        enemies.forEach { (eachEnemy:inout Enemy) in
            if (eachEnemy.isAlive) {
                bulletBox.origin = eachEnemy.pos
                enemySprite?.draw(renderer, bulletBox.sdlRect())
            }
        }
        
        bulletBox.origin = player.pos
        playerSprite?.draw(renderer, bulletBox.sdlRect())
    }
}

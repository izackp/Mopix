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
        enemies.create([Enemy(Point(100, 100)), Enemy(Point(200, 100)), Enemy(Point(300, 100)), Enemy(Point(400, 100)), Enemy(Point(100, 200)), Enemy(Point(200, 200)), Enemy(Point(300, 200)), Enemy(Point(400, 200))])
        
        player.pos = Point(250, 500)
    }
    
    
    
    public override func logic() {
        enemies.forEach { (eachEnemy:inout Enemy) in
            if (eachEnemy.isAlive) {
                eachEnemy.logic()
            }
        }
        
        //player.logic()
        
        for eachBullet in bullets {
            if (eachBullet.isAlive) {
                eachBullet.logic(self)
            }
        }
    }
}

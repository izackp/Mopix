//
//  Bullet.swift
//  TestGame
//
//  Created by Isaac Paul on 6/16/22.
//

import Foundation

class Bullet {
    init (_ pos: Point<Int>, _ vec:Vector<Int>) {
        self.pos = pos
        self.vec = vec
    }
    var pos: Point<Int>
    var vec: Vector<Int>
    var collisionNode:CollisionNode2D = CollisionNode2D(x: 0, y: 0, width: 10, height: 10)
    var isAlive = false
    
    func logic(_ scene:SIScene) {
        pos = pos + vec
        collisionNode.x = pos.x
        collisionNode.y = pos.y
        if (scene.bounds.collides(collisionNode) == false) {
            //destroy self
            isAlive = false
            return
        }
        scene.enemies.forEach({ (eachEnemy:inout Enemy) in
            if (eachEnemy.isAlive == false) {
                return
            }
            if (collisionNode.collides(eachEnemy.collisionNode)) {
                isAlive = false
            }
        })
    }
}

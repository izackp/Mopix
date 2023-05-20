//
//  Enemy.swift
//  TestGame
//
//  Created by Isaac Paul on 6/16/22.
//

import GameEngine

class Enemy {
    init (_ pos: Point<Int>) {
        self.pos = pos
    }
    var pos: Point<Int>
    var numSteps = 0
    var direction = 1
    var collisionNode = CollisionNode2D(x: 0, y: 0, width: 24, height: 24)
    var isAlive = false
    
    func logic(_ delta: UInt64) {
        let moveSpeed = 1 * Int(delta >> 2)
        pos.x += moveSpeed * direction
        numSteps += moveSpeed * direction
        
        if (numSteps > 40) {
            direction = -1
            let diff = (numSteps - 40) * -1
            numSteps += diff
            pos.x += diff
        } else if (numSteps < -40) {
            direction = 1
            let diff = (numSteps + 40) * -1
            numSteps += diff
            pos.x += diff
        }
    }
}

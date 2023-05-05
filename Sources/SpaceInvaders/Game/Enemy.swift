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
    
    func logic() {
        if (numSteps == 10) {
            direction = -1
        } else if (numSteps == -10) {
            direction = 1
        }
        let moveSpeed = 2
        pos.x += moveSpeed * direction
        numSteps += direction
    }
}

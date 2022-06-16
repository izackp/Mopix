//
//  Enemy.swift
//  TestGame
//
//  Created by Isaac Paul on 6/16/22.
//

import Foundation

class Enemy {
    init (_ pos: Point<Int>) {
        self.pos = pos
    }
    var pos: Point<Int>
    var numSteps = 0
    var direction = 1
    var collisionNode:CollisionNode2D = CollisionNode2D(x: 0, y: 0, width: 10, height: 10)
    var isAlive = false
    
    func logic() {
        if (numSteps == 10) {
            direction = -1
        } else if (numSteps == -10) {
            direction = 1
        }
        let moveSpeed = 10
        pos.x += moveSpeed * direction
    }
}
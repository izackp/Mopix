//
//  CollisionNode2D.swift
//  TestGame
//
//  Created by Isaac Paul on 6/16/22.
//

import GameEngine

typealias CollisionNode2D = Rect<Int>

extension CollisionNode2D {
    func collides(_ other:CollisionNode2D) -> Bool {
        if (self.right < other.left ||
            self.left > other.right ||
            self.top > other.bottom ||
            self.bottom < other.top) {
            return false
        }
        return true
    }
}

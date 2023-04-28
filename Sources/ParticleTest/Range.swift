//
//  Range.swift
//  TestGame
//
//  Created by Isaac Paul on 3/29/23.
//

import Foundation
import Xorswift
import GameEngine

var gen = XorshiftGenerator()

public extension ClosedRange where Bound == Float  {
    func random() -> Float {
        return Float.random(in: self, using: &gen)
    }
}

public extension ClosedRange where Bound == Int  {
    func random() -> Int {
        return Int.random(in: self, using: &gen)
    }
}

public extension ClosedRange where Bound == ARGB32  {
    func random() -> ARGB32 {
        let lb = self.lowerBound
        let up = self.upperBound
        let red = UInt8.random(in:lb.r ... up.r, using: &gen)
        let green = UInt8.random(in:lb.g ... up.g, using: &gen)
        let blue = UInt8.random(in:lb.b ... up.b, using: &gen)
    
        return ARGB32(a: 255, r: red, g: green, b: blue)
    }
}

public extension ClosedRange where Bound == Vector<Float>  {
    func random() -> Vector<Float> {
        let lb = self.lowerBound
        let up = self.upperBound
        let x = Float.random(in:lb.x ... up.x, using: &gen)
        let y = Float.random(in:lb.y ... up.y, using: &gen)
    
        return Vector<Float>(x, y)
    }
}

public extension ClosedRange where Bound == Float  {
    func diff() -> Float {
        let lb = self.lowerBound
        let up = self.upperBound
    
        return up - lb
    }
}


public extension ClosedRange where Bound == Vector<Float>  {
    func diff() -> Vector<Float> {
        let lb = self.lowerBound
        let ub = self.upperBound
        let x = ub.x - lb.x
        let y = ub.y - lb.y
    
        return Vector<Float>(x, y)
    }
}


//
//  Particle.swift
//  TestGame
//
//  Created by Isaac Paul on 4/7/23.
//

import GameEngine
import ChunkedPool

public struct ParticleAction {
    public var pos:Vector<Float> = Vector(0, 0)
    public var endGravity:Float = 0
    public var endVector:Vector<Float> = Vector(0, 0)
    public var colorStart:ARGB32 = ARGB32.black
    public var colorDiff:ARGB32Diff = ARGB32Diff(start: 0, dest: 0)

    public func action(_ target:inout Particle, _ elapsedRatio:Double) {
        let ratio = Float(elapsedRatio)
        let x = endVector.x * ratio
        let y = endVector.y * ratio
        //let variance = (abs(Float(colorDiff.diffB))/255)
        //let idk = (endGravity) * variance
        let otherY = endGravity * ratio * ratio
        var end = y + otherY
        var endx = x
        if (end > 300) {
            let thing = ((end - 300) * 0.2)
            end = 300 - thing
            endx -= thing
            target.pos = Vector<Float>(endx, end) + pos
            target.color = ARGB32.darkRed
        } else {
            target.pos = Vector<Float>(endx, end) + pos
            target.color = colorDiff.colorForElapsedRatio(colorStart, elapsedRatio)
        }
        if (elapsedRatio == 1.0) {
            target.completed = true
        }
    }
}

public struct Particle : IReusable {
    public var pos:Vector<Float> = Vector.zero
    public var color:ARGB32 = ARGB32.white //TODO: Was Int
    public var completed = false

    public var ID: ContiguousHandle
    
    public var isAlive: Bool
    //public var completed: Bool
    //private var _canceled: Bool = false

    public init() {
        ID = ContiguousHandle(index: 0)
        isAlive = false
        completed = false
    }
    
    public mutating func initHook() {
        assert(!isAlive, "unexpected")
        pos = Vector.zero
        color = ARGB32.white
        completed = false
    }
    
    public mutating func clean() {
        pos = Vector.zero
        color = ARGB32.white
        completed = false
    }
    
    @inline(__always) public mutating func cleanOnComplete() -> Bool {
        if (isAlive && completed) {
            clean()
            isAlive = false
            return true
        }
        return false
    }
}

public class ParticleClass : IReusable {
    public var pos:Vector<Float> = Vector.zero
    public var color:ARGB32 = ARGB32.white //TODO: Was Int
    public var completed = false

    public var ID: ContiguousHandle
    
    public var isAlive: Bool
    //public var completed: Bool
    //private var _canceled: Bool = false

    required public init() {
        ID = ContiguousHandle(index: 0)
        isAlive = false
        completed = false
    }
    
    public func initHook() {
        assert(!isAlive, "unexpected")
        pos = Vector.zero
        color = ARGB32.white
        completed = false
    }
    
    public func clean() {
        pos = Vector.zero
        color = ARGB32.white
        completed = false
    }
    
    @inline(__always) public func cleanOnComplete() -> Bool {
        if (isAlive && completed) {
            clean()
            isAlive = false
            return true
        }
        return false
    }
}

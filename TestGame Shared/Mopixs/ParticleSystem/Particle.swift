//
//  Particle.swift
//  TestGame
//
//  Created by Isaac Paul on 4/7/23.
//

import Foundation
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
    
    public mutating func cleanOnComplete() -> Bool {
        if (isAlive && completed) {
            clean()
            isAlive = false
            return true
        }
        return false
    }
}

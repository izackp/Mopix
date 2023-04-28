//
//  Tween.swift
//  TestGame
//
//  Created by Isaac Paul on 3/30/23.
//

//Note: It could be possible to move a lot of this to a base class, but we wouldnt be able to use a struct

import ChunkedPool

public struct Tween : SomeTween, ITweenFlex {
    
    public init() {
        tracker = Tracker(0)
        ID = ContiguousHandle(index: 0)
        isAlive = false
        completed = false
    }
    
    public var ID: ContiguousHandle
    
    public var isAlive: Bool
    public var completed: Bool
    

    //public Func<double, double> modifier
    public var modifier: ((Double)->(Double))? = nil
    public var action: ((Double)->Void)? = nil
    public var onComplete: ((Bool)->Void)? = nil
    public var tracker:Tracker
    private var _canceled:Bool = false


    public mutating func initHook() {
        assert(!isAlive, "unexpected")
        tracker = Tracker(0)
    }

    public mutating func clean() {
        action = nil
        onComplete = nil
        _canceled = false
        completed = false
        modifier = nil
    }

    public mutating func setDuration(_ time:Double) {
        tracker = .init(time)
    }

    public mutating func cancelAnimation() {
        _canceled = true
    }

    public mutating func processFrame(_ delta:Double) -> Bool {
        if (_canceled) {
            onComplete?(true)
            return true
        }

        let elapsedRatio = tracker.progress(delta)
        completed = elapsedRatio == 1.0
        let moddedRatio = modifier?(elapsedRatio) ?? elapsedRatio
        action?(moddedRatio)

        if (completed) {
            onComplete?(false)
        }
        return completed
    }
}

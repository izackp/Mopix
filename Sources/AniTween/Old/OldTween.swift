//
//  OldTween.swift
//  TestGame
//
//  Created by Isaac Paul on 4/4/23.
//

import Foundation
public class OldTween<T> where T : AnyObject  {
    public var target:T! = nil //obj?
    public var tracker:Tracker
    public var modifier: ((Double)->(Double))? = nil
    public var action: ((T, Double)->Void)? = nil
    public var onComplete: ((T, Bool)->Void)? = nil
    public var ID:Int = 0
    public var isAlive:Bool = false
    public var completed:Bool = false
    private var _canceled:Bool = false

    public init() {
        tracker = .init(0)
    }

    public func clean() {
        action = nil
        target = nil
        _canceled = false
        completed = false
        modifier = nil
    }

    public func duration(_ time:TimeInterval) -> OldTween<T> {
        tracker = Tracker(time)
        return self
    }

    public func processFrame(_ delta:Double) -> Bool {
        if (_canceled) {
            onComplete?(target, false)
            return true
        }

        var elapsedRatio = tracker.progress(delta)
        elapsedRatio = modifier?(elapsedRatio) ?? elapsedRatio
        action?(target, elapsedRatio)
        
        let complete = elapsedRatio == 1.0
        if (complete) {
            completed = true
            onComplete?(target, complete)
        }
        return complete
    }

    public func cancelAnimation() {
        _canceled = true //TODO: Should remove from tweener immediately>
    }
}

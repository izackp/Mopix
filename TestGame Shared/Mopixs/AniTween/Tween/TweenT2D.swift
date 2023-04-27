//
//  TweenT2D.swift
//  TestGame
//
//  Created by Isaac Paul on 3/30/23.
//

import Foundation

public protocol ITransformable2D {
    var pos:Vector<Float> { get set }
    var size:Vector<Float> { get set }
    var color:ARGB32 { get set }
    var alpha:Float { get set }
}

public struct TweenT2D : ITween, IReusable {
    
    public var ID: ContiguousHandle
    
    public var isAlive: Bool
    public var completed: Bool
    
    public var modifier: ((Double)->(Double))? = nil
    public var onComplete: ((Bool)->Void)? = nil
    public var tracker:Tracker
    private var _canceled:Bool = false

    public var target:ITransformable2D! = nil

    public init() {
        tracker = Tracker(0)
        ID = ContiguousHandle(index: 0)
        isAlive = false
        completed = false
    }
    
    public mutating func initHook() {
        assert(!isAlive, "unexpected")
        tracker = Tracker(0)
    }

    public mutating func clean() {
        onComplete = nil
        _canceled = false
        completed = false
        modifier = nil
        
        target = nil
    }

    public mutating func setDuration(_ time:TimeInterval ) {
        tracker = .init(time)
    }

    public mutating func cancelAnimation() {
        _canceled = true
    }

    public mutating func processFrame(_ delta:Double) -> Bool {
        //ref var target = ref TargetPtr.FetchRef()
        if (_canceled) {
            onComplete?(false)
            return true
        }

        var elapsedRatio = tracker.progress(delta)
        elapsedRatio = modifier?(elapsedRatio) ?? elapsedRatio
        
        //Never worked?
        //action?.Invoke(elapsedRatio);

        completed = elapsedRatio == 1.0
        if (completed) {
            onComplete?(completed) //TODO: Do we really want to call this from a thread?
        }
        return completed
    }
}

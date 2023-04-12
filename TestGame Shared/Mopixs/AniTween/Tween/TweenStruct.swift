//
//  TweenStruct.swift
//  TestGame
//
//  Created by Isaac Paul on 3/30/23.
//

import Foundation

//public delegate void ActionRef<T>(ref T target, double elapsedRatio)
//public delegate void ActComplete<T>(ref T target, bool didFinish)

public struct TweenStruct<T> : SomeTween where T : IReusable {
//public struct TweenStruct<T> : ITween, IReusable where T : struct, IReusable {

    public var ID: ContiguousHandle
    
    public var isAlive: Bool
    public var completed: Bool
    

    //public Func<double, double> modifier
    public var modifier: ((Double)->(Double))? = nil
    public var action: ((inout T, Double)->Void)? = nil
    public var onComplete: ((Bool)->Void)? = nil
    public var tracker:Tracker
    public var targetPtr:PoolRef<T>! = nil
    private var _canceled:Bool = false
    
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
        ID = ContiguousHandle(index: 0)
        action = nil
        
        onComplete = nil
        _canceled = false
        completed = false
        modifier = nil
        
        targetPtr = nil//PoolRef(handle: ContiguousHandle(index: -1), _pool: nil)
        
    }

    public mutating func setDuration(_ time:TimeInterval ) {
        tracker = .init(time)
    }

    public mutating func cancelAnimation() {
        _canceled = true
    }
    
    
    
    struct ActionHandler {
        var elapsedRatio:Double = 0
        var itemIndex:Int = 0
        
    }
    
    var actionHandler:ActionHandler = ActionHandler()
    
    //var handler:((_ ptr:inout UnsafeMutableBufferPointer<T>)->Void)? = nil
    
    

    public mutating func processFrame(_ delta:Double) -> Bool {
        //ref var target = ref TargetPtr.FetchRef()
        if (_canceled) {
            onComplete?(false)
            return true
        }

        var elapsedRatio = tracker.progress(delta)
        elapsedRatio = modifier?(elapsedRatio) ?? elapsedRatio
        if let _ = action {
            /*
             targetPtr.with { item in
                 action(&item, elapsedRatio)
             }
             */
            let pool = targetPtr._pool
            let index = targetPtr.handle
            let chunkIndex = Int(index.chunkIndex())
            let itemIndex = Int(index.subIndex())
            actionHandler.itemIndex = itemIndex
            actionHandler.elapsedRatio = elapsedRatio
            if let chunk = pool.data[chunkIndex] {
                chunk.data.withUnsafeMutableBufferPointer { (ptr:inout UnsafeMutableBufferPointer<T>) in
                    onIteration(ptr: &ptr)
                }
            }
        }

        completed = elapsedRatio == 1.0
        if (completed) {
            onComplete?(completed) //TODO: Do we really want to call this from a thread?
        }
        return completed
    }
    
    func onIteration(ptr:inout UnsafeMutableBufferPointer<T>) {
        guard let buffer = ptr.baseAddress else { return }
        let ptr:UnsafeMutablePointer<T> = buffer.advanced(by: actionHandler.itemIndex)
        action?(&ptr.pointee, actionHandler.elapsedRatio)
    }
/*
    public ref T Target() {
        return ref TargetPtr.FetchRef()
    }

    public bool ContainsTarget(ContiguousHandle ptr) {
        return TargetPtr.Handle == ptr
    }*/
}

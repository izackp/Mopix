//
//  TweenStruct.swift
//  TestGame
//
//  Created by Isaac Paul on 3/30/23.
//

import ChunkedPool

public struct TweenStruct<T> : SomeTween where T : IReusable {

    public var ID: ContiguousHandle
    
    public var isAlive: Bool
    public var completed: Bool
    
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
        
        targetPtr = nil
        
    }

    public mutating func setDuration(_ time:Double ) {
        tracker = .init(time)
    }

    public mutating func cancelAnimation() {
        _canceled = true
    }
    
    struct ActionHandler {
        var elapsedRatio:Double = 0
        var itemIndex:Int = 0
    }
    
    var actionHandler:ActionHandler = ActionHandler() //No idea why but it's faster.
    
    public mutating func processFrame(_ delta:Double) -> Bool {
        //ref var target = ref TargetPtr.FetchRef()
        if (_canceled) {
            onComplete?(false)
            return true
        }

        var elapsedRatio = tracker.progress(delta)
        elapsedRatio = modifier?(elapsedRatio) ?? elapsedRatio
        if let _ = action {
            let pool = targetPtr._pool
            let index = targetPtr.handle
            let chunkIndex = Int(index.chunkIndex())
            let itemIndex = Int(index.itemIndex())
            actionHandler.itemIndex = itemIndex
            actionHandler.elapsedRatio = elapsedRatio
            if let chunk = pool.data[chunkIndex] {
                
                chunk.data.withUnsafeMutableBufferPointer { (ptr:inout UnsafeMutableBufferPointer<T>) in
                    onIteration(ptr: &ptr)
                }
                /*
                if let action = action {
                    chunk.data.withUnsafeMutableBufferPointer { (ptrBuff:inout UnsafeMutableBufferPointer<T>) in
                        guard let buffer = ptrBuff.baseAddress else { return }
                        let ptr:UnsafeMutablePointer<T> = buffer.advanced(by: actionHandler.itemIndex)
                        action(&ptr.pointee, elapsedRatio)
                    }
                }*/
                
                //about 3-5 ms slower
                /*
                if let action = action {
                    chunk.with(UInt16(itemIndex)) { item in
                        action(&item, elapsedRatio)
                    }
                }*/
                /*
                if let action = action {
                    chunk.withPtr(UInt16(itemIndex)) { item in
                        onIteration2(ptr: item)
                    }
                }*/
                /*
                if let action = action {
                    chunk.with(UInt16(itemIndex)) { item in
                        onIteration3(ptr: &item)
                    }
                }*/
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
    func onIteration2(ptr:UnsafeMutablePointer<T>) {
        action?(&ptr.pointee, actionHandler.elapsedRatio)
    }
    func onIteration3(ptr:inout T) {
        action?(&ptr, actionHandler.elapsedRatio)
    }
}

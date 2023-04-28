//
//  Tweener.swift
//  TestGame
//
//  Created by Isaac Paul on 3/30/23.
//

import ChunkedPool
import Foundation

public protocol ITween {
    mutating func processFrame(_ deltaTime:Double) -> Bool
    var completed:Bool { get set }
    mutating func setDuration(_ time:Double)
}

public protocol ITweenFlex {
    var modifier: ((Double)->(Double))? { get set }
    var action: ((Double)->Void)? { get set }
    var onComplete: ((Bool)->Void)? { get set }
}


public protocol SomeTween: IReusable & ITween {
    
}

extension SomeTween {
    public mutating func cleanOnComplete() -> Bool {
        if (isAlive && completed) {
            clean()
            isAlive = false
            return true
        }
        return false
    }
}

public class Tweener<T> where T : SomeTween {

    public let _pool:ChunkedPool<T>

    public init(_ pool:ChunkedPool<T>? = nil) {
        if let pool = pool {
            _pool = pool
        } else {
            _pool = ChunkedPool<T>()// ChunkedPool<T>.Instance
        }
    }

    public func processFrame(_ deltaTime:Double) {
        processFrameSync(deltaTime)
        //processFrameParallelFor(deltaTime)
    }
    
    private func processFrameParallelFor(_ deltaTime:Double) {
        let pool:ChunkedPool<T> = _pool
        //let info = ProcessInfo.processInfo
        let threads = 4//info.activeProcessorCount * 3
        DispatchQueue.concurrentPerform(iterations: threads) { (index) in
            Tweener.processFramePiece(pool, deltaTime, threads, index)
        }
        
        //NOTE: We get ~10ms by avoiding locks and cleaning in a single thread instead of 13-15ms with occasional spikes to 20ms
        _pool.iteratePool { item in
            return item.cleanOnComplete()
        }
    }
    
    private static func processFramePiece(_ pool:ChunkedPool<T>, _ deltaTime:Double, _ parts:Int = 1, _ index:Int = 0) {
        
        //NOTE: Seems worse off with iterate pool
        pool.iteratePool(deltaTime, parts, index) { item, deltaTime in
            let _ = item.processFrame(deltaTime)
        }
    }

    public func processFrameSync(_ deltaTime:Double) {
        let time = CFAbsoluteTimeGetCurrent()
        _pool.iteratePool { item in
            return item.processFrame(deltaTime)
        }
        let processTime = CFAbsoluteTimeGetCurrent() - time
        print("processFrame Tween Time: \(String(format: "%.3fms", processTime * 1000))")
    }
    
    public func isComplete() -> Bool {
        return _pool.countTotalItems == 0
    }

    public func runningTweens() -> Int{
        return _pool.countTotalItems
    }

    public func popTween(_ block: ( _ item:inout T)->()) -> ContiguousHandle?  {
        return _pool.rent(block)
    }
    
    public func animate(_ duration:TimeInterval, _ modifier:((Double) -> Double)? = nil, _ action: @escaping ( _ elapsedRatio:Double)->(), _ onComplete: ((Bool)->Void)? = nil) -> ContiguousHandle? where T : ITweenFlex {
        return _pool.rent { tween in
            tween.setDuration(duration)
            tween.modifier = modifier
            tween.action = action
            tween.onComplete = onComplete
        }
    }
    
    //MARK: - Debugging
    public func debugInfo() -> String {
        return "cc: \(_pool.chunksCreated) - cd: \(_pool.chunksDeleted)"
    }

}

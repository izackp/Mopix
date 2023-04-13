//
//  Tweener.swift
//  TestGame
//
//  Created by Isaac Paul on 3/30/23.
//

import Foundation
public protocol ITween {
    mutating func processFrame(_ deltaTime:Double) -> Bool
    var completed:Bool { get set }
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

    let _pool:ChunkedPool<T>

    init(_ pool:ChunkedPool<T>? = nil) {
        if let pool = pool {
            _pool = pool
        } else {
            _pool = ChunkedPool<T>()// ChunkedPool<T>.Instance
        }
    }

    public func processFrame(_ deltaTime:Double) {
        processFrameSync(deltaTime)
        //processFrameAsync2(deltaTime)
        //processFrameParallelFor(deltaTime: deltaTime)
    }

    private func processFrameAsync2(_ deltaTime:Double) {
        //let info = ProcessInfo.processInfo
        let threads = 4//info.activeProcessorCount
        let semaphore = DispatchSemaphore(value: 0)
        let pool:ChunkedPool<T> = _pool
        Task {
            await withTaskGroup(of: Void.self) { group in
                for i in 0 ..< threads {
                    group.addTask {
                        return await Tweener.processFrame2Async(pool, deltaTime, threads, i)
                    }
                }
            }
            semaphore.signal()
        }
        semaphore.wait() //Apparently not safe
        cleanCompleted() //NOTE: We get ~10ms to by avoiding locks and cleaning in a single thread instead of 13-15ms with occasional spikes to 20ms
    }
    
    private static func processFrame2Async(_ pool:ChunkedPool<T>, _ deltaTime:Double, _ parts:Int = 1, _ index:Int = 0) async {
        return processFrame2(pool, deltaTime, parts, index)
    }
    
    //We can make an interface that will resolve the chunk each time or do it by chunks like now
    private func processFrameParallelFor(deltaTime:Double ) {
        let pool:ChunkedPool<T> = _pool
        //let info = ProcessInfo.processInfo
        let threads = 4//info.activeProcessorCount * 3
        DispatchQueue.concurrentPerform(iterations: threads) { (index) in
            Tweener.processFrame2(pool, deltaTime, threads, index)
            //print(index)
        }
        
        cleanCompleted()
    }
    
    private static func processFrame2(_ pool:ChunkedPool<T>, _ deltaTime:Double, _ parts:Int = 1, _ index:Int = 0) {
        
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
        print("processFrame Tween Time: \(toStrSmart(processTime))")
    }
    
    //Faster when we can garuentee the tween is a class
    public func processFrameSyncClass(_ deltaTime:Double) {
        let time = CFAbsoluteTimeGetCurrent()
        let chunks = _pool.data.count
        for w in 0 ..< chunks {
            guard let eachChunk = _pool.data[w] else { continue }
            let chunkData:ContiguousArray<T> = eachChunk.data
            
            let len = chunkData.count
            for t in 0..<len {
                let eachItem = chunkData[t]
                if (eachItem.isAlive) {
                    var item = eachItem
                    let completed = item.processFrame(deltaTime)
                    if (completed) {
                        item.clean()
                        item.isAlive = false
                        _pool.returnCleanedItem(eachChunk, UInt16(w), UInt16(t))
                    }
                }
            }
        }
        
        let processTime = CFAbsoluteTimeGetCurrent() - time
        print("processFrame Tween Time: \(toStrSmart(processTime))")
        
        cleanCompleted()
    }
    
    func cleanCompleted() {
        //let time = CFAbsoluteTimeGetCurrent()
        _pool.iteratePool { item in
            return item.cleanOnComplete()
        }
        
        //let cleanTime = CFAbsoluteTimeGetCurrent() - time
        //print("cleanTime Tween Time: \(toStrSmart(cleanTime))")
    }

    public func debugInfo() -> String {
        //return $"Processed: {numProcessed} - Completed: {numComplete}"
        return "cc: \(_pool.chunksCreated) - cd: \(_pool.chunksDeleted)"
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
}

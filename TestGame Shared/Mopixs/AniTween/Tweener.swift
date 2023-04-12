//
//  Tweener.swift
//  TestGame
//
//  Created by Isaac Paul on 3/30/23.
//

import Foundation
public protocol ITween {
    mutating func processFrame(_ deltaTime:Double) -> Bool
    //bool ContainsTarget(THandle ptr)
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
        //processFrameSync(deltaTime)
        processFrameAsync2(deltaTime)
        //processFrameParallelFor(deltaTime: deltaTime)
    }

    public func processFrameAsync2(_ deltaTime:Double) {
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
        cleanCompletedNew()
    }
    
    public static func processFrame2Async(_ pool:ChunkedPool<T>, _ deltaTime:Double, _ parts:Int = 1, _ index:Int = 0) async {
        return processFrame2(pool, deltaTime, parts, index)
    }
    
    public static func processFrame2(_ pool:ChunkedPool<T>, _ deltaTime:Double, _ parts:Int = 1, _ index:Int = 0) {
        
        let totalChunks = pool.data.count
        let splitParts = totalChunks / parts
        let begin = splitParts * index
        var end = splitParts * (index + 1)
        if (index == parts - 1) {
            end = totalChunks
        }

        for i in begin ..< end {
            guard let eachChunk = pool.data[i] else { continue }
            //var chunkData = eachChunk.data
            eachChunk.data.withUnsafeMutableBufferPointer { (ptr:inout UnsafeMutableBufferPointer<T>) in
                guard let buffer = ptr.baseAddress else { return }
                let len = ptr.count
                for t in 0 ..< len {
                    let ptr:UnsafeMutablePointer<T> = buffer.advanced(by: t)
                    if (ptr.pointee.isAlive) {
                        var _ = ptr.pointee.processFrame(deltaTime)
                    }
                }
            }
        }
    }

    public func processFrameSync(_ deltaTime:Double) {
        let time = CFAbsoluteTimeGetCurrent()
        let chunks = _pool.data.count
        for i in 0 ..< chunks {
            //guard var eachChunk = data[i] else { continue }
            //var chunkData = eachChunk.data
            _pool.data[i]?.data.withUnsafeMutableBufferPointer { (ptr:inout UnsafeMutableBufferPointer<T>) in
                guard let buffer = ptr.baseAddress else { return }
                let len = ptr.count
                for t in 0 ..< len {
                    let ptr:UnsafeMutablePointer<T> = buffer.advanced(by: t)
                    if (ptr.pointee.isAlive) {
                        var _ = ptr.pointee.processFrame(deltaTime)
                    }
                }
            }
        }
        
        let processTime = CFAbsoluteTimeGetCurrent() - time
        //print("processFrame Tween Time: \(toStrSmart(processTime))")
        //time = CFAbsoluteTimeGetCurrent()
        cleanCompletedNew()
        //let cleanTime = CFAbsoluteTimeGetCurrent() - time
        //print("cleanTime Tween Time: \(toStrSmart(cleanTime))")
    }

    private func cleanCompleted() {
        let chunks = _pool.data.count
        for w in 0 ..< chunks {
            guard let eachChunk = _pool.data[w] else { continue }
            //var chunkData = eachChunk.data
            eachChunk.data.withUnsafeMutableBufferPointer { (ptr:inout UnsafeMutableBufferPointer<T>) in
                guard let buffer = ptr.baseAddress else { return }
                let len = ptr.count
                for t in 0 ..< len {
                    let ptr:UnsafeMutablePointer<T> = buffer.advanced(by: t)
                    if (ptr.pointee.cleanOnComplete()) {
                        _pool.returnCleanedItem(eachChunk, UInt16(w), UInt16(t))
                    }
                }
            }
            /*
            let chunkData = eachChunk.data
            let len = UInt16(chunkData.count)
            for t in 0 ..< len {
                eachChunk.with(t) { eachTween in
                    if (eachTween.isAlive && eachTween.completed) {
                        _pool.cleanAndReturn(eachChunk, &eachTween, UInt16(w), t)
                    }
                }
            }*/
        }
    }

    private func cleanCompletedNew() {
        let chunks = UInt16(_pool.data.count)
        for w in 0 ..< chunks {
            _pool.modChunk(w) { chunk in
                cleanChunk(chunk)
            }
        }
    }

    public func cleanChunk(_ chunk:Chunk<T>) -> Int {
        
        var countAdjust = 0
        chunk.data.withUnsafeMutableBufferPointer { (ptr:inout UnsafeMutableBufferPointer<T>) in
            guard let buffer = ptr.baseAddress else { return }
            let len = ptr.count
            for t in 0 ..< len {
                let ptr:UnsafeMutablePointer<T> = buffer.advanced(by: t)
                if (ptr.pointee.cleanOnComplete()) {
                    countAdjust -= 1
                    chunk.returnCleaned(UInt16(t)) //asdf
                }
            }
        }
        /*
        let len = UInt16(chunkData.count)
        for t in 0..<len {
            chunk.returnItemIf(t) { eachTween in
                let shouldReturn = (eachTween.isAlive && eachTween.completed)
                if (shouldReturn) {
                    countAdjust -= 1
                }
                return shouldReturn
            }
        }*/
        return countAdjust
    }

    //We can make an interface that will resolve the chunk each time or do it by chunks like now
    public func processFrameParallelFor(deltaTime:Double ) {
        let pool:ChunkedPool<T> = _pool
        let info = ProcessInfo.processInfo
        let threads = 4//info.activeProcessorCount * 3
        DispatchQueue.concurrentPerform(iterations: threads) { (index) in
            Tweener.processFrame2(pool, deltaTime, threads, index)
            //print(index)
        }
        
        cleanCompleted()
    }

    public func debugInfo() -> String {
        //return $"Processed: {numProcessed} - Completed: {numComplete}"
        return "cc: \(_pool.chunksCreated) - cd: \(_pool.chunksDeleted)"
    }

    public func processCompleted() {

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

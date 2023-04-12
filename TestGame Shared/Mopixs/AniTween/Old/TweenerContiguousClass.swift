//
//  TweenerContiguousClass.swift
//  TestGame
//
//  Created by Isaac Paul on 4/4/23.
//

import Foundation

public class TweenerContiguousClass<T> where T : AnyObject {
    var _tweenPool = ContiguousObjectPool<T>(initialCapacity: Helper.NUM_VIEWS + 200000)
    var _tweenList:[OldTween<T>]? = nil
    //System.Diagnostics.Stopwatch watch = new System.Diagnostics.Stopwatch()

    public init() {
        _tweenList = _tweenPool.poolData
    }

    public func processFrame(_ deltaTime:Double) {
        //var totalTweens = _tweenList?.count ?? 0
        let threads = 4
        guard let tweenList = _tweenList else { return }
        DispatchQueue.concurrentPerform(iterations: threads) { (index) in
            TweenerContiguousClass.processFrame2(tweenList, _tweenPool, deltaTime, threads, index)
        }
        /*
        var result = Parallel.For(0, totalTweens, (i, state) => {
           let eachTween = _tweenList[i]
            if (eachTween.isAlive) {
                var isComplete = eachTween.processFrame(deltaTime)
                if (isComplete) {
                    //Stopwatch watch = new Stopwatch()
                    //watch.Restart()
                    _tweenPool.returnItem(eachTween)
                    //var elapsed = watch.Elapsed.TotalMilliseconds
                    //Utility.Benchmarks.returned.AddSample(elapsed)
                }
            }
        })*/
        /*
        for (int i = totalTweens - 1 i >= 0 i -= 1) {
            Tween<T> eachTween = _tweenList[i]
            
            var didComplete = eachTween.ProcessFrame(deltaTime)
            if (didComplete) {
                _tweenList.RemoveAt(i)
                _tweenPool.Return(eachTween)
            }
        }*/
    }
    
    public static func processFrame2(_ tweenList:[OldTween<T>], _ tweenPool:ContiguousObjectPool<T>, _ deltaTime:Double, _ parts:Int = 1, _ index:Int = 0) {
        
        let totalChunks = tweenList.count
        let splitParts = totalChunks / parts
        let begin = splitParts * index
        var end = splitParts * (index + 1)
        if (index == parts - 1) {
            end = totalChunks
        }
        
        /* Regular arrays have no guarentee to be contigous
        var tweenList2 = tweenList //TODO: Not sure if copy happens
        tweenList2.withUnsafeMutableBufferPointer { (ptr:inout UnsafeMutableBufferPointer<OldTween<T>>) in
            guard let buffer = ptr.baseAddress else { return }
            for t in begin ..< end {
                let ptr:UnsafeMutablePointer<OldTween<T>> = buffer.advanced(by: t)
                var eachTween = ptr.pointee //ok because oldtween is class
                if (eachTween.isAlive) {
                    let isComplete = eachTween.processFrame(deltaTime)
                    if (isComplete) {
                        tweenPool.returnItem(&eachTween)
                    }
                }
            }
        }*/
        
        for i in begin ..< end {
            var eachTween = tweenList[i]
            if (eachTween.isAlive) {
                let isComplete = eachTween.processFrame(deltaTime)
                 if (isComplete) {
                     //Stopwatch watch = new Stopwatch()
                     //watch.Restart()
                     tweenPool.returnItem(&eachTween)
                     //var elapsed = watch.Elapsed.TotalMilliseconds
                     //Utility.Benchmarks.returned.AddSample(elapsed)
                 }
            }
        }
    }

    public func isComplete() -> Bool {
        return _tweenPool.isInUse() == false
    }

    public func popTween(target:T) -> OldTween<T>? {
        //Helper.MeasureBegin()
        guard let tween = _tweenPool.rent() else { return nil }
        tween.target = target
        //var result = Helper.MeasureEnd()
        //Utility.Benchmarks.rent.AddSample(result)
        return tween
    }

    public func totalTweens() -> Int {
        return _tweenPool.totalRented()
    }

    public func cancelAnimationsForTarget(_ target:T) {
        _tweenList?.forEachItem { (eachTween:inout OldTween<T>) in
            if (eachTween.target === target) {
                eachTween.cancelAnimation()
            }
        }
    }
}

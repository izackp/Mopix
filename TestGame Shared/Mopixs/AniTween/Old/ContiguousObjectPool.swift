//
//  ContiguousObjectPool.swift
//  TestGame
//
//  Created by Isaac Paul on 4/4/23.
//

import Foundation

//Hoping its contiguous just by instantiating all objs in sequence
public class ContiguousObjectPool<T> where T : AnyObject {

    private var _lock = pthread_rwlock_t()
    public var poolData:[OldTween<T>] = []
    private var _availableIndexes:[Int] = []
    var indexSize = 0
    var initialSize = 0

    public init(initialCapacity:Int) {
        initialSize = initialCapacity
        _availableIndexes = Array(count: initialCapacity, element: 0)
        poolData = Array(unsafeUninitializedCapacity: initialCapacity, initializingWith: { buffer, initializedCount in
            for i in 0..<initialCapacity {
                let tween = OldTween<T>()
                tween.ID = i
                buffer[i] = tween
                _availableIndexes[i] = i
            }
            initializedCount = initialCapacity
        })
        indexSize = initialCapacity
    }

    public func returnItem(_ obj:inout OldTween<T>) {
        obj.clean()
        obj.isAlive = false
        pthread_rwlock_wrlock(&_lock)
        _availableIndexes[indexSize] = obj.ID
        indexSize += 1
        pthread_rwlock_unlock(&_lock)
    }

    public func rent() -> OldTween<T>? {
        pthread_rwlock_wrlock(&_lock)
        if (indexSize <= 0) {
            pthread_rwlock_unlock(&_lock)
            return nil
        }
        indexSize -= 1
        let nextIndex = _availableIndexes[indexSize]
        let tween = poolData[nextIndex]
        pthread_rwlock_unlock(&_lock)
        tween.isAlive = true
        return tween
    }

    public func totalRented() -> Int {
        return poolData.count - indexSize
    }

    public func isInUse() -> Bool {
        return (indexSize < poolData.count)
    }
}

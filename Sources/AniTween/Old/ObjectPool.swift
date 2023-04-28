//
//  ObjectPool.swift
//  TestGame
//
//  Created by Isaac Paul on 4/4/23.
//

import Foundation

public protocol IInitializable { init() }

extension Array {
    mutating func popExpected() -> Element {
        let result = self.last!
        self.removeLast()
        return result
    }
    
    mutating func pop() -> Element? {
        if let result = self.last {
            self.removeLast()
            return result
        }
        return nil
    }
}

public class ObjectPool<T> where T : IInitializable {
    private var _lock = pthread_rwlock_t()
    private var _poolData:[T] = []

    public init(initialCapacity:Int) {
        for _ in 0 ..< initialCapacity {
            _poolData.append(T.init())
        }
        pthread_rwlock_init(&_lock, nil)
    }

    public func returnItem(_ obj:T) {
        pthread_rwlock_wrlock(&_lock)
        _poolData.append(obj)
        pthread_rwlock_unlock(&_lock)
    }

    public func retrieve() -> T {
        pthread_rwlock_wrlock(&_lock)
        let result = _poolData.pop()
        pthread_rwlock_unlock(&_lock)
        return result ?? T.init()
    }
}

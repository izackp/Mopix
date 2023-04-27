//
//  PoolRef.swift
//  TestGame
//
//  Created by Isaac Paul on 4/19/23.
//

import Foundation

//Pool safety and convienence
public struct PoolManualRef<T> where T : IReusable {
    public let handle:ContiguousHandle
    private let _pool:ChunkedPool<T>
    
    public init(handle: ContiguousHandle, _pool: ChunkedPool<T>) {
        self.handle = handle
        self._pool = _pool
    }

    public func with(_ block: ( _ item:inout T)->()) {
        _pool.with(handle, block)
    }

    public func returnToPool() {
        _pool.returnItem(handle)
    }
}

public class PoolRef<T> where T : IReusable {
    public let handle:ContiguousHandle
    public let _pool:ChunkedPool<T>
    
    public init(handle: ContiguousHandle, _pool: ChunkedPool<T>) {
        self.handle = handle
        self._pool = _pool
    }
    
    public func with(_ block: ( _ item:inout T)->()) {
        _pool.with(handle, block)
    }

    deinit {
        _pool.returnItem(handle)
    }
}

public class PoolRefClass<T> where T : IReusable {
    public let handle:ContiguousHandle
    public let _pool:ChunkedPool<T>
    public let item:T
    
    public init(handle: ContiguousHandle, _pool: ChunkedPool<T>, item:T) {
        self.handle = handle
        self._pool = _pool
        self.item = item
    }

    deinit {
        //_pool.returnItem(handle)
    }
}

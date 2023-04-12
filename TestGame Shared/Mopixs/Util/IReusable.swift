//
//  IReusable.swift
//  TestGame
//
//  Created by Isaac Paul on 1/26/23.
//

import Foundation
public struct ContiguousHandle {
    var index:UInt32
    //static implicit operator uint(ContiguousHandle handle) => handle.Index;
    //public static explicit operator ContiguousHandle(uint i) => new ContiguousHandle() { Index = i };
    //public static explicit operator int(ContiguousHandle handle) => (int)handle.Index;
    //public static explicit operator ContiguousHandle(int i) => new ContiguousHandle() { Index = (uint)i };
    public func chunkIndex() -> UInt16 {
        let result = UInt16(index >> 16)
        return result
    }
    public func subIndex() -> UInt16 {
        let result = UInt16(index & 0xFFFF)
        return result
    }

    public static func buildHandle(chunkIndex:UInt16, index:UInt16) -> ContiguousHandle {
        let finalIndex = UInt32(chunkIndex) << 16 | UInt32(index)
        return ContiguousHandle(index: finalIndex)
    }
}

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

//Necessary functions to exist in the struct
public protocol IReusable: IInitializable {
    init()
    mutating func initHook()
    mutating func clean()
    
    var ID:ContiguousHandle { get set }
    var isAlive:Bool { get set }
}

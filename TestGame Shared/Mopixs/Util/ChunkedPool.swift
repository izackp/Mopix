//
//  ChunkedPool.swift
//  TestGame
//
//  Created by Isaac Paul on 1/26/23.
//

import Foundation
public class ChunkedPool<T> where T : IReusable {

    //public static readonly ChunkedPool<T> Instance = new ChunkedPool<T>()
    /*
     Not yet sure if I should make it like this or have them specifically store in the top level app/gameengine
    class var shared : ChunkedPool<T> {
         let store_key = String(describing: T.self)
         if let singleton = singletons_store[store_key] {
             return singleton as! ChunkedPool<T>
         } else {
             let new_singleton = ChunkedPool<T>()
             singleton_store[store_key] = new_singleton
             return new_singleton
         }
     }
     */
    let maxSize = 65535
    let minAmtOfChunks = 1 //Minimum amount of chunks to keep alive
        
    public var unusedIndex = 0 //UInt16
    public var data:[Chunk<T>?] = [] //Nullable; //List vs Array?
       
        //object _myLock = new object(); //Note: Might be able to reduce contention with multiple locks when accessing chunks.
        //Ex: even and odd numbers get their own lock. My brain hurts when I try to think of how to make this work tho, so eh
        //The ideal solution would be to remove the lock and just have 1 pool per thread
        //The problem with that is how do you know which pool to return an item to when you're done with it...
        //I suppose its all in all just possible to set a IsComplete flag... It would work for my specific use case, but how about others?

        
    var _availableIndexes:[UInt16] = [] //confusing 0..<UnusedIndex == used indexes; UnusedIndex..<Capacity == free indexes //Used like a stack
    var _chunkSize:UInt16 = 0
    var _freeChunk:Chunk<T>? = nil//Nullable; //Instead of dealing with some kind of magic indexing we will just have a pool of chunks for reuse; Prevents unnecessary deleting and creating
    var _count:Int = 0
    var _chunkCreateCount:Int = 0
    var _chunkDeleteCount:Int = 0
        
    var chunkSize:UInt16 {
        get { return _chunkSize }
    }

    init(capacity:UInt16 = 10, chunkSize:UInt16 = 65535) {
        assert(capacity > 1); //We scale up by * 1.5 so 1 * 1.5 ends up being one...
        _chunkSize = chunkSize
        //super.init()
        for i in 0..<capacity {
            data.append(Chunk<T>(chunkSize, i))
        }
        initData(0, capacity);
    }

    func initData(_ start:UInt16, _ max:UInt16) {
        for i in start..<max {
            _availableIndexes.append(i)
        }
    }
    
    public func countLive() -> Int {
        var count = 0
        let chunks = data.count
        for i in 0 ..< chunks {
            guard let eachChunk = data[i] else { continue }
            eachChunk.data.withUnsafeBufferPointer { (ptr:UnsafeBufferPointer<T>) in
                guard let buffer = ptr.baseAddress else { return }
                let len = ptr.count
                for t in 0 ..< len {
                    let partPtr:UnsafePointer<T> = buffer.advanced(by: t)
                    let eachParticle = partPtr.pointee
                    if (eachParticle.isAlive) {
                        count += 1
                    }
                }
            }
        }
        return count
    }
    
    public func rentRef(_ block: ( _ item:inout T)->()) -> PoolRef<T>? {
        //lock(_myLock) {
        let unusedIndex2 = unusedIndex
            if (unusedIndex2 == data.count) {
                expandArrays()
            }
            let chunkIndex = _availableIndexes[unusedIndex2]
            let chunkIndexInt = Int(chunkIndex)
            var chunk = data[chunkIndexInt]
            if (chunk == nil) {
                if (_freeChunk != nil) {
                    chunk = _freeChunk
                    _freeChunk = nil
                    chunk!.updateId(chunkIndex)
                } else {
                    chunk = Chunk<T>(_chunkSize, chunkIndex)
                    _chunkCreateCount += 1
                }
                data[chunkIndexInt] = chunk
            }
        
            if (chunk!.oneAwayFromFull()) {
                unusedIndex += 1
            }
            _count += 1
            if let result = try? chunk!.rent(block) {
                let handle = ContiguousHandle.buildHandle(chunkIndex: chunkIndex, index: result)
                return PoolRef(handle: handle, _pool: self)
            } else {
                return nil
            }
            //ref var instance = ref chunk.Rent()
        //}
    }

    public func rent(_ block: ( _ item:inout T)->()) -> ContiguousHandle? {
        //lock(_myLock) {
        let unusedIndex2 = unusedIndex
            if (unusedIndex2 == data.count) {
                expandArrays()
            }
            let chunkIndex = _availableIndexes[unusedIndex2]
            let chunkIndexInt = Int(chunkIndex)
            var chunk = data[chunkIndexInt]
            if (chunk == nil) {
                if (_freeChunk != nil) {
                    chunk = _freeChunk
                    _freeChunk = nil
                    chunk!.updateId(chunkIndex)
                } else {
                    chunk = Chunk<T>(_chunkSize, chunkIndex)
                    _chunkCreateCount += 1
                }
                data[chunkIndexInt] = chunk
            }
        
            if (chunk!.oneAwayFromFull()) {
                unusedIndex += 1
            }
            _count += 1
            if let result = try? chunk!.rent(block) {
                let handle = ContiguousHandle.buildHandle(chunkIndex: chunkIndex, index: result)
                return handle
            } else {
                return nil
            }
            //ref var instance = ref chunk.Rent()
        //}
    }

    public func returnItem(_ index:ContiguousHandle) {
        let chunkIndex = index.chunkIndex();
        let itemIndex = index.subIndex();
        guard let chunk = data[Int(chunkIndex)] else { return }
        chunk.data.withUnsafeMutableBufferPointer { inner in
            //TODO: not sure if faster...
            guard let item = inner.baseAddress?.advanced(by: Int(itemIndex)) else { return }
            item.pointee.clean()
            item.pointee.isAlive = false
            
            returnCleanedItem(chunk, chunkIndex, itemIndex)
        }/*
        chunk.with(itemIndex) { item in
            cleanAndReturn(chunk, &item, chunkIndex, itemIndex);
        }*/
    }

    public func returnItem(_ item:inout T) {
        let handle = item.ID
        let chunkIndex = handle.chunkIndex()
        let itemIndex = handle.subIndex()
        guard let chunk = data[Int(chunkIndex)] else { return }

        cleanAndReturn(chunk, &item, chunkIndex, itemIndex)
    }

    /// <summary>Access a chunk with the goal of modifying its contents.</summary>
    /// <param name="chunkIndex">Index of the chunk.</param>
    /// <param name="apply">Code to apply to a chunk which should return the number of items added(+) or removed(-). -3 means 3 items are removed.
    /// If 3 items are removed and 3 items are added then return 0. -3 + 3 == 0.</param>
    public func modChunk(_ chunkIndex:UInt16, _ apply:( _ chunk:Chunk<T>)->(Int)) {
        guard let chunk = data[Int(chunkIndex)] else { return }
        //lock (_myLock) {
            var returnToStack = chunk.isFull()
            let countAdjust = apply(chunk)

            returnToStack = returnToStack && chunk.isFull() == false

            afterChunkModified(chunk, chunkIndex, returnToStack)

            _count += countAdjust;
        //}
    }
    
    public func with(_ index:ContiguousHandle, _ block: ( _ item:inout T)->()) {
        let chunkIndex = Int(index.chunkIndex())
        let itemIndex = Int(index.subIndex())
        guard let chunk = data[chunkIndex] else { return }
        chunk.data.withUnsafeMutableBufferPointer { inner in
            block(&inner[itemIndex])
        }
        //data[]?.with(, block)
    }

    public var count:Int {
        get { return unusedIndex } //chunkCount * chunkSize - UnusedIndex of last chunk
    }

    public var countTotalItems:Int {
        get { return _count }
    }

    public func cleanAndReturn(_ chunk:Chunk<T>, _ item:inout T, _ chunkIndex:UInt16, _ itemIndex:UInt16) {
        item.clean()
        item.isAlive = false
        
        returnCleanedItem(chunk, chunkIndex, itemIndex);
    }

    func returnCleanedItem(_ chunk:Chunk<T>, _ chunkIndex:UInt16, _ itemIndex:UInt16) {
        //lock(_myLock) {
            let returnToStack = chunk.isFull()
            chunk.returnCleaned(itemIndex) //asdf
            
            afterChunkModified(chunk, chunkIndex, returnToStack)
            _count -= 1
        //}
    }

    func afterChunkModified(_ chunk:Chunk<T>, _ chunkIndex:UInt16, _ returnToStack:Bool) {
        let shouldDeleteChunk = chunk.count() == 0 && count > minAmtOfChunks
        if (shouldDeleteChunk) {
            let index = Int(chunkIndex)
            _freeChunk = data[index]
            data[index] = nil //Delete the chunk
        }
        if (returnToStack) {
            unusedIndex -= 1
            _availableIndexes[unusedIndex] = chunkIndex
        }
    }

    func expandArrays() {
        if (unusedIndex == maxSize) {
            return
        }
        let dataSize = _availableIndexes.count
        var newSize = (dataSize >> 1) + dataSize; //x1.5 //avoiding floats for determinism
        if (newSize > maxSize) {
            newSize = maxSize;
        }
        //Array.Resize(ref Data, (int)newSize);
        //Array.Resize(ref _availableIndexes, (int)newSize);
        for i in dataSize..<newSize {
            data.append(Chunk<T>(chunkSize, UInt16(i)))
        }
        initData(UInt16(dataSize), UInt16(newSize))
    }
        
    //MARK: - Debug
    public var chunksCreated:Int {
        get {
            let result = _chunkCreateCount
            _chunkCreateCount = 0
            return result
        }
    }

    public var chunksDeleted:Int {
        get {
            let result = _chunkDeleteCount
            _chunkDeleteCount = 0
            return result
        }
    }
}

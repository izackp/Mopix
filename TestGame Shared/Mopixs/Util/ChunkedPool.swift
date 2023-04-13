//
//  ChunkedPool.swift
//  TestGame
//
//  Created by Isaac Paul on 1/26/23.
//

import Foundation

//NOTE: T can be a class, but it seems to be slower
//Decided against putting an ID inside of chunk. Say we do use the max amount of chunks thats 65535*4 more bytes.. (262kb which.. isn't bad)
public class ChunkedPool<T> where T : IReusable {

    let maxSize = 65535 //Currently our IDs are split between the pool index and the chunk index. So a chunk size of 256 limits us to maximum amount of 256 * 65535 = 16,776,960
    let minAmtOfChunks = 1 //Minimum amount of chunks to keep alive
        
    private var _unusedIndex = 0 //UInt16
    public var data:[Chunk<T>?] = []
       
    //object _myLock = new object() //Note: Might be able to reduce contention with multiple locks when accessing chunks.
    //The ideal solution would be to remove the lock and just have 1 pool per thread
        
    private var _availableIndexes:[UInt16] = [] //confusing // 0..<UnusedIndex == used indexes // UnusedIndex..<Capacity == free indexes // Used like a stack
    private var _chunkSize:UInt16 = 0
    private var _freeChunk:Chunk<T>? = nil//Nullable //Instead of dealing with some kind of magic indexing we will just have a pool of chunks for reuse Prevents unnecessary deleting and creating
    private var _count:Int = 0 //Book keeping that for debugging... I'm not sure if to keep as it makes some api complicated
    private var _chunkCreateCount:Int = 0
    private var _chunkDeleteCount:Int = 0
    
    
    private var _lock = pthread_rwlock_t()
        
    var chunkSize:UInt16 {
        get { return _chunkSize }
    }

    init(capacity:UInt16 = 10, chunkSize:UInt16 = 256) {
        assert(capacity > 1) //We scale up by * 1.5 so 1 * 1.5 ends up being one...
        _chunkSize = chunkSize
        pthread_rwlock_init(&_lock, nil)
        //super.init()
        initData(0, capacity)
    }

    func initData(_ start:UInt16, _ max:UInt16) {
        data.reserveCapacity(Int(max))
        _availableIndexes.reserveCapacity(Int(max))
        for i in start..<max {
            data.append(Chunk<T>(chunkSize, i))
            _availableIndexes.append(i)
        }
    }
    
    public func rentRef(_ block: ( _ item:inout T)->()) -> PoolRef<T>? {
        if let result = rent(block) {
            return PoolRef(handle: result, _pool: self)
        }
        return nil
    }
    
    public func rentRefClass(_ block: ( _ item:inout T)->()) -> PoolRefClass<T>? where T : AnyObject {
        //lock(_myLock) {
            let (chunk, chunkIndex) = getNextAvailableChunk()
            if let (result, ref) = try? chunk.rentClass(block) {
                let handle = ContiguousHandle.buildHandle(chunkIndex: chunkIndex, index: result)
                return PoolRefClass(handle: handle, _pool: self, item:ref)
            } else {
                return nil
            }
        //}
    }

    public func rent(_ block: ( _ item:inout T)->()) -> ContiguousHandle? {
        //lock(_myLock) {
            let (chunk, chunkIndex) = getNextAvailableChunk()
            if let result = try? chunk.rent(block) {
                let handle = ContiguousHandle.buildHandle(chunkIndex: chunkIndex, index: result)
                return handle
            } else {
                return nil
            }
        //}
    }
    
    private func getNextAvailableChunk() -> (Chunk<T>, UInt16) {
        if (_unusedIndex == data.count) {
            expandArrays()
        }
        let chunkIndex = _availableIndexes[_unusedIndex]
        let chunk = chunkForIndex(chunkIndex)
    
        if (chunk.oneAwayFromFull()) {
            _unusedIndex += 1
        }
        _count += 1
        return (chunk, chunkIndex)
    }
    
    private func chunkForIndex(_ index:UInt16) -> Chunk<T> {
        let indexInt = Int(index)
        if let chunk = data[indexInt] {
            return chunk
        }
        let newChunk = freshChunk(index)
        data[indexInt] = newChunk
        return newChunk
    }
    
    private func freshChunk(_ index:UInt16) -> Chunk<T> {
        if let chunk = _freeChunk {
            _freeChunk = nil
            chunk.updateId(index)
            return chunk
        } else {
            let chunk = Chunk<T>(_chunkSize, index)
            _chunkCreateCount += 1
            return chunk
        }
    }

    @inline(__always) public func returnItem(_ index:ContiguousHandle) {
        let chunkIndex = index.chunkIndex()
        let itemIndex = index.subIndex()
        guard let chunk = data[Int(chunkIndex)] else { return }
        chunk.with(itemIndex) { item in
            cleanAndReturn(chunk, &item, chunkIndex, itemIndex)
        }
    }

    public func returnItem(_ item:inout T) {
        let handle = item.ID
        let chunkIndex = handle.chunkIndex()
        let itemIndex = handle.subIndex()
        guard let chunk = data[Int(chunkIndex)] else { return }

        cleanAndReturn(chunk, &item, chunkIndex, itemIndex)
    }
    
    public func iteratePool(_ block:( _ item:inout T)->(Bool)) {
        let chunks = data.count
        for w in 0 ..< chunks {
            guard let eachChunk = data[w] else { continue }
            let wasFull = eachChunk.isFull()
            var countAdjust = 0
            eachChunk.data.forEachUnchecked { (eachItem:inout T, t) in
                if (eachItem.isAlive) {
                    if (block(&eachItem)) {
                        eachItem.clean()
                        eachItem.isAlive = false
                        eachChunk.returnCleaned(UInt16(t))
                        countAdjust -= 1
                    }
                }
            }
            let returnToStack = wasFull && eachChunk.isFull() == false
            afterChunkModified(eachChunk, UInt16(w), returnToStack)

            _count += countAdjust
        }
    }
    
    public func iteratePool<R>(_ some:R, _ parts:Int = 1, _ index:Int = 0, _ block:( _ item:inout T, _ other:R)->()) {
        let totalChunks = data.count
        let splitParts = totalChunks / parts
        let begin = splitParts * index
        var end = splitParts * (index + 1)
        if (index == parts - 1) {
            end = totalChunks
        }

        for w in begin ..< end {
            guard let eachChunk = data[w] else { continue }
            eachChunk.data.forEachUnchecked { (eachItem:inout T, t) in
                if (eachItem.isAlive) {
                    block(&eachItem, some)
                }
            }
        }
    }
    
    public func iteratePoolOld<R>(_ some:R, _ parts:Int = 1, _ index:Int = 0, _ block:( _ item:inout T, _ other:R)->(Bool)) {
        let totalChunks = data.count
        let splitParts = totalChunks / parts
        let begin = splitParts * index
        var end = splitParts * (index + 1)
        if (index == parts - 1) {
            end = totalChunks
        }

        for w in begin ..< end {
            guard let eachChunk = data[w] else { continue }
            let wasFull = eachChunk.isFull()
            var countAdjust = 0
            eachChunk.data.forEachUnchecked { (eachItem:inout T, t) in
                if (eachItem.isAlive) {
                    if (block(&eachItem, some)) {
                        eachItem.clean()
                        eachItem.isAlive = false
                        eachChunk.returnCleaned(UInt16(t))
                        countAdjust -= 1
                    }
                }
            }
            
            let returnToStack = wasFull && eachChunk.isFull() == false
            pthread_rwlock_wrlock(&_lock)
            afterChunkModified(eachChunk, UInt16(w), returnToStack)

            _count += countAdjust //Note: we can avoid lock in some cases if we drop this count
            pthread_rwlock_unlock(&_lock)
        }
    }

    /// <summary>Access a chunk with the goal of modifying its contents.</summary>
    /// <param name="chunkIndex">Index of the chunk.</param>
    /// <param name="apply">Code to apply to a chunk which should return the number of items added(+) or removed(-). -3 means 3 items are removed.
    /// If 3 items are removed and 3 items are added then return 0. -3 + 3 == 0.</param>
    public func modChunk(_ chunkIndex:UInt16, _ apply:( _ chunk:Chunk<T>)->(Int)) {
        guard let chunk = data[Int(chunkIndex)] else { return }
        //lock (_myLock) {
            let wasFull = chunk.isFull()
            let countAdjust = apply(chunk)

            let returnToStack = wasFull && chunk.isFull() == false

            afterChunkModified(chunk, chunkIndex, returnToStack)

            _count += countAdjust
        //}
    }
    
    @inline(__always) public func with(_ index:ContiguousHandle, _ block: ( _ item:inout T)->()) {
        let chunkIndex = Int(index.chunkIndex())
        let itemIndex = Int(index.subIndex())
        guard let chunk = data[chunkIndex] else { return }
        chunk.data.withUnsafeMutableBufferPointer { inner in
            block(&inner[itemIndex])
        }
        //data[]?.with(, block)
    }

    public var count:Int {
        get { return _unusedIndex } //chunkCount * chunkSize - UnusedIndex of last chunk
    }

    @inline(__always) public func cleanAndReturn(_ chunk:Chunk<T>, _ item:inout T, _ chunkIndex:UInt16, _ itemIndex:UInt16) {
        item.clean()
        item.isAlive = false
        
        returnCleanedItem(chunk, chunkIndex, itemIndex)
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
            _unusedIndex -= 1
            _availableIndexes[_unusedIndex] = chunkIndex
        }
    }

    func expandArrays() {
        if (_unusedIndex == maxSize) {
            return
        }
        let dataSize = _availableIndexes.count
        var newSize = (dataSize >> 1) + dataSize //x1.5 //avoiding floats for determinism
        if (newSize > maxSize) {
            newSize = maxSize
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
    
    public var countTotalItems:Int {
        get { return _count }
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
}

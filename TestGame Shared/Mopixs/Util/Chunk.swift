//
//  Chunk.swift
//  TestGame
//
//  Created by Isaac Paul on 1/26/23.
//

//T == struct
public class Chunk<T> where T : IReusable {
    public var data:ContiguousArray<T>
    var _availableIndexes:ContiguousArray<UInt16>
    public var unusedIndex:UInt16 = 0
    //public var ID:UInt16 = 0

    public let cMaxSize = 65535

    init(_ size: UInt16, _ chunkIndex: UInt16) {
        let count = Int(size)
        /*
        self.data = ContiguousArray()
        self.data.reserveCapacity(count)
        
        for i in 0..<count {
            self.data.append(T())
        }*/
        
        //let builder()
        
        self.data = ContiguousArray(unsafeUninitializedCapacity: count, initializingWith: { buffer, initializedCount in
            guard let buffer = buffer.baseAddress else { return }
            for i in 0 ..< count {
                let ptr:UnsafeMutablePointer<T> = buffer.advanced(by: i)
                ptr.initialize(to: T())
            }
            initializedCount = count
        })
        //ContiguousArray(repeating: T(), count: Int(size))
        _availableIndexes = ContiguousArray<UInt16>(repeating: 0, count: count)
        //ID = chunkIndex
        initData(chunkIndex)
    }

    private func initData(_ chunkIndex:UInt16) {
        for i in 0 ..< data.count {
            data[i].initHook()
            data[i].ID = ContiguousHandle.buildHandle(chunkIndex: chunkIndex, index: UInt16(i))
            _availableIndexes[i] = UInt16(i)
        }
    }
    
    public func assertStuff() {
        let count = countLive()
        let result = unusedIndex == count
        assert(result)
        if (!result) {
            print("assert \(result) \(unusedIndex) == \(count)")
        }
    }
    
    public func countLive() -> Int {
        var liveCount = 0
        data.forEachUnchecked { (eachItem:inout T, t) in
            if (eachItem.isAlive) {
                liveCount += 1
            }
        }
        return liveCount
    }

    public func updateId(_ chunkIndex:UInt16) {
        assert(unusedIndex == 0)
        //ID = chunkIndex
        for i in 0 ..< data.count {
            data[i].ID = ContiguousHandle.buildHandle(chunkIndex: chunkIndex, index: UInt16(i))
            _availableIndexes[i] = UInt16(i)
        }
    }
    

    public func rent(_ block: ( _ item:inout T)->()) throws -> UInt16 {
        if (unusedIndex == data.count) {
            throw GenericError("Exceeded chunk size")
        }
        let index = _availableIndexes[Int(unusedIndex)]
        let indexInt = Int(index)
        data[indexInt].isAlive = true
        block(&data[indexInt])
        let result = index
        unusedIndex += 1
        return result
    }
    
    public func rentClass(_ block: ( _ item:inout T)->()) throws -> (UInt16, T) {
        if (unusedIndex == data.count) {
            throw GenericError("Exceeded chunk size")
        }
        let index = _availableIndexes[Int(unusedIndex)]
        let indexInt = Int(index)
        var ref = data[indexInt]
        ref.isAlive = true
        block(&ref)
        let result = index
        unusedIndex += 1
        return (result, ref)
    }
    
    @inline(__always) public func with(_ index:UInt16, _ block: ( _ item:inout T)->()) {
        data.withUnsafeMutableBufferPointer { block(&$0[Int(index)]) }
        //block(&data[Int(index)])
    }
    
    @inline(__always) public func with<S>(_ index:UInt16, _ block: ( _ item:inout T)->(S)) -> S {
        return data.withUnsafeMutableBufferPointer { return block(&$0[Int(index)]) } //Significantly faster in high iterations
        //return block(&data[Int(index)])
    }

    public func withPtr(_ index:UInt16, _ block: ( _ ptr:UnsafeMutablePointer<T>)->()) {
        data.withUnsafeMutableBufferPointer {
            guard let addr = $0.baseAddress else { return }
            block(addr.advanced(by: Int(index)))
        }
    }
    
    public func withPtr<R>(_ index:UInt16, _ block: ( _ ptr:UnsafeMutablePointer<T>)->(R)) -> R {
        var result:R! = nil
        data.withUnsafeMutableBufferPointer {
            guard let addr = $0.baseAddress else { return }
            result = block(addr.advanced(by: Int(index)))
        }
        return result
    }

    @inline(__always) subscript(index:UInt16) -> T {
        get {
            return data[Int(index)]
        }
        set(newElm) {
            data[Int(index)] = newElm
        }
    }

    public func returnCleaned(_ index:UInt16) {
        unusedIndex -= 1
        _availableIndexes[Int(unusedIndex)] = index
    }

    public func isFull() -> Bool {
        return unusedIndex == data.count
    }
    
    public func oneAwayFromFull() -> Bool {
        return unusedIndex == data.count - 1
    }

    public func count() -> Int {
        return Int(unusedIndex)
    }
}

//
//  Chunk.swift
//  TestGame
//
//  Created by Isaac Paul on 1/26/23.
//

//T == struct
public class Chunk<T> where T : IReusable {
    //public int chunkIndex = 0 //4 Bytes
    public var unusedIndex:UInt16 = 0 //4 Bytes
    public var data:ContiguousArray<T> //8 Bytes
    var _availableIndexes:ContiguousArray<UInt16> //8 Bytes

    public let cMaxSize = 65535
    
    /*init(size: UInt16, chunkIndex: UInt16) {
        //chunkIndex = index
        data = ContiguousArray(repeating: T(), count: Int(size))
        _availableIndexes = ContiguousArray<UInt16>(repeating: 0, count: Int(size))
        InitData(chunkIndex)
    }*/
    init(_ size: UInt16, _ chunkIndex: UInt16) { //}, _ data:ContiguousArray<T>) {
        //chunkIndex = index
        self.data = ContiguousArray(repeating: T(), count: Int(size))
        _availableIndexes = ContiguousArray<UInt16>(repeating: 0, count: Int(size))
        initData(chunkIndex)
    }

    private func initData(_ chunkIndex:UInt16) {
        for i in 0 ..< data.count {
            data[i].initHook()
            data[i].ID = ContiguousHandle.buildHandle(chunkIndex: chunkIndex, index: UInt16(i))
            _availableIndexes[i] = UInt16(i)
        }
    }

    public func updateId(_ chunkIndex:UInt16) {
        assert(unusedIndex == 0)
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

    /*
    public func returnItem(_ index:UInt16) {
        with(index) {item in
            item.clean()
            item.isAlive = false
        }
        unusedIndex -= 1
        _availableIndexes[Int(unusedIndex)] = index
    }*/
    /*
    public func returnItemIf(_ index:UInt16, condition: ( _ item:inout T)->(Bool)) {
        var exit = false
        with(index) {item in
            if (condition(&item)) {
                item.clean()
                item.isAlive = false
            } else {
                exit = true
            }
        }
        if (exit) { return }
        unusedIndex -= 1
        _availableIndexes[Int(unusedIndex)] = index
    }*/

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

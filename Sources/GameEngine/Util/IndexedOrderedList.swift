//
//  IndexedOrderedList.swift
//  
//
//  Created by Isaac Paul on 10/4/23.
//

public class IndexedOrderedList<T> {
    public init() {
        self._list = []
        self._index = [:]
    }
    
    public init(list: [T], getId:(T) -> (Int)) {
        self._list = list
        var index:[Int:T] = [:]
        for eachItem in list {
            index[getId(eachItem)] = eachItem
        }
        self._index = index
    }
    
    public init(list: [T], idList: [Int]) throws {
        let count = list.count
        if (count != idList.count) { throw GenericError("id list must be the same size as list") }
        
        self._list = list
        var index:[Int:T] = [:]
        for i in 0..<count {
            index[idList[i]] = list[i]
        }
        self._index = index
    }
    
    var _list:[T] = []
    var _index:[Int:T] = [:]
    
    var list: [T] {
        get {
            return _list
        }
    }
    
    var count: Int {
        get {
            return _list.count
        }
    }
    
    func updateList(_ list:[T], getId:(T) -> (Int)) {
        _list = list
        _index.removeAll(keepingCapacity: true)
        
        list.forEachUnchecked { eachItem, i in
            _index[getId(eachItem)] = eachItem
        }
    }
    
    subscript(index:Int) -> T? {
        return _index[index]
    }
}

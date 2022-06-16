//
//  EntityPool.swift
//  TestGame
//
//  Created by Isaac Paul on 6/16/22.
//

import Foundation

struct EntityPool<T> {
    var items:Arr<T> = Arr<T>()
    var pendingItems:Arr<T> = Arr<T>()
    
    mutating func create(_ newItem:T) {
        pendingItems.append(newItem)
    }
    
    mutating func create(_ newItemList:[T]) {
        pendingItems.reserveCapacity(newItemList.count)
        pendingItems.append(contentsOf: newItemList)
    }
    
    //TODO: Check if faster or slower; hopefully avoids copy of structs
    mutating func forEach(_ action:(inout T)->()) {
        for i in 0..<items.count {
            action(&items[i])
        }
    }
}
//
//  Dictionary+Shortcuts.swift
//  
//
//  Created by Isaac Paul on 4/22/23.
//

extension Dictionary {
    mutating func fetchOrInsert(_ key:Key, _ builder:()throws->(Value)) rethrows -> Value {
        if let item = self[key] {
            return item
        }
        
        let newItem = try builder()
        self[key] = newItem
        return newItem
    }
}

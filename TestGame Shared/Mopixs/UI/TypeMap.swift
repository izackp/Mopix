//
//  TypeMap.swift
//  TestGame
//
//  Created by Isaac Paul on 8/10/22.
//

import Foundation


protocol Initializable {
    init()
}

class TypeMap {
    static let shared = TypeMap()
    
    var typeList:[Initializable.Type] = []
    
    func register(_ type:Initializable.Type) {
        
        let idk = type.init()
        print(String(describing: idk))
        let mirror = Mirror(reflecting: idk)
        for case let (label?, value) in mirror.children {
            print (label, value)
        }
        if let _ = typeList.firstIndex(where: {$0 == type}) {
            return
        } else {
            typeList.append(type)
        }
    }
}

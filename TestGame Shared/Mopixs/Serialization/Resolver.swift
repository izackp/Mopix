//
//  Resolver.swift
//  TestGame
//
//  Created by Isaac Paul on 8/9/22.
//

import Foundation

private enum InternalCodingKeys: String, CodingKey {
    case _type
    case _id
}

//Needed to work around array serialization as root object
struct Resolver<T> : Codable {
    let result:[T]
    
    init(_ result:[T]) {
        self.result = result
    }
    
    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        var elements:[T] = []
        while (container.isAtEnd == false) {
            let idk = try container.decodeElementInArray(T.self)
            elements.append(idk)
        }
        
        self.result = elements
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        for eachItem in result {
            try container.encodeElementInArray(eachItem)
        }
    }
}

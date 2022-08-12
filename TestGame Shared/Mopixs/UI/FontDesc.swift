//
//  FontDesc.swift
//  TestGame
//
//  Created by Isaac Paul on 8/9/22.
//

import Foundation

public struct FontDesc : Codable, Hashable {
    
    public var family:String
    public var weight:UInt16
    public var size:Float
    
    public static let defaultFont = FontDesc(family: "Roboto", weight: 100, size: 21)
    
    init(family: String, weight: UInt16, size: Float) {
        self.family = family
        self.weight = weight
        self.size = size
    }
    /*
    init(_ dictionary: [String : Any]) throws {
        family = try dictionary.expect("family")
        weight = try dictionary.expect("weight")
        size = try dictionary.expect("size")
    }
    
    func toDictionary() -> [String : Any] {
        return [
            "family":family,
            "weight":weight,
            "size":size
        ]
    }*/
}

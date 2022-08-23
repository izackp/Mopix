//
//  SmartColor.swift
//  TestGame
//
//  Created by Isaac Paul on 7/28/22.
//

import Foundation

public extension SmartColor {
    static var white:SmartColor = 0xFFFFFFFF
    static var idk:SmartColor = 0x9999FFFF
    static var pink:SmartColor = 0xFF3B69FF
    static var black:SmartColor = 0x000000FF
}

public class SmartColor: ExpressibleByIntegerLiteral, ExpressibleByStringLiteral, ExpressibleByInteger, ExpressibleByString, Codable {
    
    public typealias StringLiteralType = String
    public typealias IntegerLiteralType = UInt32

    var rawValue: UInt32? = nil
    var name:String? = nil //TODO: Use id
    
    public required init(integerLiteral value: UInt32) {
        name = nil
        rawValue = value
    }
    
    public required init(_ value: Int64) throws {
        name = nil
        rawValue = UInt32(value)
    }
    
    public required init(_ value: String) throws {
        name = value
        rawValue = nil
    }
    
    required public init(stringLiteral name:String) {
        self.name = name
        rawValue = nil
    }
}

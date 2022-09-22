//
//  SmartColor.swift
//  TestGame
//
//  Created by Isaac Paul on 7/28/22.
//

import Foundation

public extension SmartColor {
    static var white:SmartColor = 0xFFFFFFFF
    static var green:SmartColor = 0xFF00FF00
    static var red:SmartColor = 0xFFFF0000
    static var blue:SmartColor = 0xFF0000FF
    static var idk:SmartColor = 0xFF9999FF
    static var pink:SmartColor = 0xFFFF3B69
    static var black:SmartColor = 0xFF000000
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
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let value = self.rawValue {
            try container.encode(value)
        } else if let name = self.name {
            try container.encode(name)
        } else {
            throw GenericError("Invalid SmartColor; missing name or value")
        }
    }
}

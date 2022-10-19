//
//  SmartColor.swift
//  TestGame
//
//  Created by Isaac Paul on 7/28/22.
//

import Foundation

public extension SmartColor {
    static var white = SmartColor(0xFFFFFFFF, name: "white")
    static var green = SmartColor(0xFF00FF00, name: "green")
    static var red = SmartColor(0xFFFF0000, name: "red")
    static var blue = SmartColor(0xFF0000FF, name: "blue")
    static var idk = SmartColor(0xFF9999FF, name: "idk")
    static var pink = SmartColor(0xFFFF3B69, name: "pink")
    static var black = SmartColor(0xFF000000, name: "black")
    static var clear = SmartColor(0x00000000, name: "clear")
}

public class SmartColor: ExpressibleByIntegerLiteral, ExpressibleByStringLiteral, ExpressibleByInteger, ExpressibleByString, Codable, Equatable, CustomDebugStringConvertible {
    
    public static func == (lhs: SmartColor, rhs: SmartColor) -> Bool {
        //if (lhs === rhs) { return true }
        if (lhs.rawValue == rhs.rawValue) { return true }
        if let lhsName = lhs.name,
           let rhsName = rhs.name,
           (lhsName == rhsName) { return true }
        return false
    }
    
    
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
    public init(_ value:UInt32, name:String) {
        self.rawValue = value
        self.name = name
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
    
    public var debugDescription: String {
        get {
            if let name = name {
                return name
            }
            return String(format:"%02X", rawValue ?? 0)
        }
    }
    
    //TODO: This wont work. We need to resolve the color earlier
    public func withAlpha(_ alpha:Float) -> SmartColor {
        if (alpha == 1) { return self }
        if let value = self.rawValue {
            let onlyAlpha = 0xFF000000 & value
            let modded = Float(onlyAlpha) * alpha
            let asInt = UInt32(modded) + (0x00FFFFFF & value)
            return SmartColor(integerLiteral: asInt)
        }
        return self
    }
    
    public func isClear() -> Bool {
        if let value = self.rawValue {
            let onlyAlpha = 0xFF000000 & value
            return onlyAlpha == 0
        }
        return name == "clear"
    }
}

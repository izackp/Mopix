//
//  LabeledColor.swift
//  TestGame
//
//  Created by Isaac Paul on 7/28/22.
//

import Foundation
import SDL2Swift

public typealias SDLColor = SDL2Swift.Color

enum ColorTruth : UInt32{
    case white = 0xFFFFFFFF
    case green = 0xFF00FF00
    case red = 0xFFFF0000
    case blue = 0xFF0000FF
    case idk = 0xFF9999FF
    case pink = 0xFFFF3B69
    case black = 0xFF000000
    case clear = 0x00000000
}

public extension LabeledColor {
    static var white = LabeledColor(.white, name: "white")
    static var green = LabeledColor(.green, name: "green")
    static var red = LabeledColor(.red, name: "red")
    static var blue = LabeledColor(.blue, name: "blue")
    static var idk = LabeledColor(.idk, name: "idk")
    static var pink = LabeledColor(.pink, name: "pink")
    static var black = LabeledColor(.black, name: "black")
    static var clear = LabeledColor(.clear, name: "clear")
}

public class LabeledColor: ExpressibleByIntegerLiteral, ExpressibleByInteger, ExpressibleByStringWithContext, Codable, Equatable, CustomDebugStringConvertible {
    
    public typealias IntegerLiteralType = UInt32

    var rawValue: UInt32
    var name:String? = nil
    
    public required init(integerLiteral value: UInt32) {
        name = nil
        rawValue = value
    }
    
    public required init(_ value: Int64) throws {
        name = nil
        rawValue = UInt32(value)
    }
    
    public required init(_ value: String, _ context:[CodingUserInfoKey : Any]) throws {
        guard let labeledColors = context[CodingUserInfoKey(rawValue: "labeledColors")!] as? LabeledColorMap else {
            throw GenericError("Using labeled colors without passing LabeledColorMap class to deserializer.")
        }
        name = value
        let color = try labeledColors.expectRawColor(value)
        rawValue = color
    }
    
    public required init(_ value: String, _ mapping:LabeledColorMap) throws {
        name = value
        let color = try mapping.expectRawColor(value)
        rawValue = color
    }
    
    public init(_ value:UInt32, name:String) {
        self.rawValue = value
        self.name = name
    }
    
    init(_ value:ColorTruth, name:String) {
        self.rawValue = value.rawValue
        self.name = name
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let name = self.name {
            try container.encode(name)
        }
        let value = self.rawValue
        try container.encode(value)
    }
    
    public var debugDescription: String {
        get {
            if let name = name {
                return name
            }
            return String(format:"%02X", rawValue)
        }
    }
    
    public func withAlpha(_ alpha:Float) -> LabeledColor {
        if (alpha == 1) { return self }
        let onlyAlpha = 0xFF000000 & rawValue
        let modded = Float(onlyAlpha) * alpha
        let asInt = UInt32(modded) + (0x00FFFFFF & rawValue)
        return LabeledColor(integerLiteral: asInt)
    }
    
    public func isClear() -> Bool {
        let onlyAlpha = 0xFF000000 & rawValue
        return onlyAlpha == 0
    }
    
    public func sdlColor() -> SDLColor {
        return SDLColor(rawValue: rawValue)
    }
    
    public static func == (lhs: LabeledColor, rhs: LabeledColor) -> Bool {
        if (lhs.rawValue == rhs.rawValue) { return true }
        if let lhsName = lhs.name,
           let rhsName = rhs.name,
           (lhsName == rhsName) { return true }
        return false
    }
    
}

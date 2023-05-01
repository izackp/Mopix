//
//  ARGB32.swift
//  TestGame
//
//  Created by Isaac Paul on 3/21/23.
//

import Foundation
//https://github.com/svhawks/ARKitEnvironmentMapper/blob/master/ARKitEnvironmentMapper/Classes/PixelFormats.swift
public struct ARGB32: RawRepresentable, Equatable, Hashable, Codable, Comparable, ExpressibleByIntegerLiteral {
    
    static let white =      ARGB32(a: 255, r: 255, g: 255, b: 255)
    static let black =      ARGB32(a: 0,   r: 0,   g: 0,   b: 0)
    static let darkRed =    ARGB32(a: 255, r: 128, g: 0,   b: 0)
    static let darkGreen =  ARGB32(a: 255, r: 0,   g: 128, b: 0)
    static let darkYellow = ARGB32(a: 255, r: 128, g: 128, b: 0)
    static let darkBlue =   ARGB32(a: 255, r: 0,   g: 0,   b: 128)
    static let darkMagenta = ARGB32(a: 255, r: 128, g: 0,  b: 128)
    static let darkCyan =   ARGB32(a: 255, r: 0,   g: 128, b: 128)
    static let gray =       ARGB32(a: 255, r: 192, g: 192, b: 192)
    static let darkGray =   ARGB32(a: 255, r: 128, g: 128, b: 128)
    static let red =        ARGB32(a: 255, r: 255, g: 0,   b: 0)
    static let green =      ARGB32(a: 255, r: 0,   g: 255, b: 0)
    static let yellow =     ARGB32(a: 255, r: 255, g: 255, b: 0)
    static let blue =       ARGB32(a: 255, r: 0,   g: 0,   b: 255)
    static let magenta =    ARGB32(a: 255, r: 255, g: 0,   b: 255)
    static let cyan =       ARGB32(a: 255, r: 0,   g: 255, b: 255)
    
    public init(integerLiteral value: UInt32) {
        a = UInt8(value >> 24)
        r = UInt8(value >> 16)
        g = UInt8(value >> 8)
        b = UInt8(value)
    }
    
    public init(a: UInt8, r: UInt8, g: UInt8, b: UInt8) {
        self.r = r
        self.g = g
        self.b = b
        self.a = a
    }
    
    public typealias IntegerLiteralType = UInt32
    
    public static func < (lhs: ARGB32, rhs: ARGB32) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
    
    
    public var rawValue: UInt32 {
        get {
            var color:UInt32 = 0
            color = (UInt32(a) << 24)
            color = color | (UInt32(r) << 16)
            color = color | (UInt32(g) << 8)
            color = color | (UInt32(b) << 0)
            return color
        }
    }
    
    let r:UInt8
    let g:UInt8
    let b:UInt8
    let a:UInt8
    
    public init(rawValue: UInt32) {
        a = UInt8(rawValue >> 24)
        r = UInt8((rawValue >> 16) & 0xFF)
        g = UInt8((rawValue >> 8) & 0xFF)
        b = UInt8(rawValue & 0xFF)
    }
    
    public func diff(_ other:ARGB32) -> ARGB32Diff {
        return ARGB32Diff(start: self, dest: other)
    }
}

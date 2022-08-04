//
//  SmartColor.swift
//  TestGame
//
//  Created by Isaac Paul on 7/28/22.
//

import Foundation

public extension SmartColor {
    static var white:SmartColor = 0xFFFFFFFF
    static var idk = SmartColor(integerLiteral: 0x9999FFFF)
    static var pink = SmartColor(integerLiteral: 0xFF3B69FF)
    static var black = SmartColor(integerLiteral: 0x000000FF)
}

public class SmartColor: ExpressibleByIntegerLiteral {
    var rawValue: UInt32? = nil
    public typealias IntegerLiteralType = UInt32
    
    var name:String? = nil //TODO: Use id
    
    public required init(integerLiteral value: UInt32) {
        self.rawValue = value
    }
    
    init(name:String) {
        self.name = name
        rawValue = nil
    }
    
    func sdlColor() -> SDLColor {
        return SDLColor(rawValue: rawValue!)
    }
    
    func getRawColor(_ theme:Int) {
        
    }
}

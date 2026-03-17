//
//  UnderlineStyle.swift
//  TestGame
//
//  Created by Isaac Paul on 10/30/22.
//

import Foundation

public struct UnderlineStyle : OptionSet, Hashable, Codable {
    public let rawValue: Int32
    
    public init(rawValue: Int32) {
        self.rawValue = rawValue
    }

    static let single               = UnderlineStyle(rawValue: 1)
    static let thick                = UnderlineStyle(rawValue: 1 << 1)
    static let double               = UnderlineStyle(rawValue: 1 << 2)
    static let patternDot           = UnderlineStyle(rawValue: 1 << 3)
    static let patternDash          = UnderlineStyle(rawValue: 1 << 4)
    static let patternDashDot       = UnderlineStyle(rawValue: 1 << 5)
    static let patternDashDotDot    = UnderlineStyle(rawValue: 1 << 6)
}

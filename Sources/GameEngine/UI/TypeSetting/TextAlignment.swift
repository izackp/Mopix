//
//  TextAlignment.swift
//  TestGame
//
//  Created by Isaac Paul on 10/19/22.
//

import Foundation

public enum TextAlignment : Int, Codable, ExpressibleByString {
    public init(_ value: String) throws {
        switch (value) {
            case "center":
                self = .center
            case "start":
                self = .start
            case "end":
                self = .end
            case "left":
                self = .left
            case "right":
                self = .right
            default:
                self = .center
        }
    }
    
    case center
    case start
    case end
    case left
    case right
}

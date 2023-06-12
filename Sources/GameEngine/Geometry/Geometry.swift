//
//  Geometry.swift
//  TestGame
//
//  Created by Isaac Paul on 4/12/22.
//

import Foundation
import SDL2

public extension BinaryFloatingPoint {
    func lerp(_ older:Self, _ percent:Float) -> Self {
        let diff = self - older
        let result = Float(diff) * percent
        return Self(result)
    }

    func lerp(_ older:Self, _ percent:Double) -> Self {
        let diff = self - older
        let result = Double(diff) * percent
        return Self(result)
    }
}

public extension BinaryInteger {
    func lerp(_ older:Self, _ percent:Float) -> Self {
        let diff = self - older
        let result = Float(diff) * percent
        return Self(result) + older
    }
}


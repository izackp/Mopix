//
//  Geometry.swift
//  TestGame
//
//  Created by Isaac Paul on 4/12/22.
//

import Foundation
import SDL2

public extension Float {
    func lerpAngle(_ older:Self, _ percent:Float) -> Self {
        let diff = self - older
        var delta = diff.wrap(360)
        if (delta > 180) {
            delta -= 360
        }
        return older + delta * Self(percent)
    }
    func lerpAngle(_ older:Self, _ percent:Double) -> Self {
        let diff = self - older
        var delta = diff.wrap(360)
        if (delta > 180) {
            delta -= 360
        }
        return older + delta * Self(percent)
    }
    func wrap(_ max:Self) -> Self {
        let something = self - floorf(self / max) * max
        return something.clamp(0.0, max)
    }
}

public extension Double {
    func lerpAngle(_ older:Self, _ percent:Float) -> Self {
        let diff = self - older
        var delta = diff.wrap(360)
        if (delta > 180) {
            delta -= 360
        }
        return older + delta * Self(percent)
    }
    func lerpAngle(_ older:Self, _ percent:Double) -> Self {
        let diff = self - older
        var delta = diff.wrap(360)
        if (delta > 180) {
            delta -= 360
        }
        return older + delta * Self(percent)
    }
    func wrap(_ max:Self) -> Self {
        let something = self - floor(self / max) * max
        return something.clamp(0.0, max)
    }
}

public extension BinaryFloatingPoint {
    func lerp(_ older:Self, _ percent:Float) -> Self {
        let diff = self - older
        let result = Float(diff) * percent
        return Self(result) + older
    }

    func lerp(_ older:Self, _ percent:Double) -> Self {
        let diff = self - older
        let result = Double(diff) * percent
        return Self(result) + older
    }
    
    func clamp(_ min:Self, _ max:Self) -> Self {
        if (self < 0) { return 0.0 }
        if (self >= max) { return max }
        return self
    }
}

public extension BinaryInteger {
    func lerp(_ older:Self, _ percent:Float) -> Self {
        let diff = self - older
        let result = Float(diff) * percent
        return Self(result) + older
    }
}


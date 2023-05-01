//
//  Utility.swift
//  TestGame
//
//  Created by Isaac Paul on 3/29/23.
//

import Foundation
import GameEngine

public class Helper {
    static let NUM_VIEWS = 1000000
}

public func cartesianToPolar_Degrees(_ x:Double, _ y:Double) -> (Double, Double) {
    let angle = atan2( y, x ) * 180.0 / Double.pi
    let magnitude = Double(distance_FlipCode(Int(x * 1000), Int(y * 1000))) * 0.001//Math.Sqrt( x * x + y * y );
    return (angle, magnitude)
}

func distance_FlipCode(_ aa:Int, _ bb:Int) -> Int {
    var a = aa
    var b = bb
    if (a < 0) { a = -a }
    if (b < 0) { b = -b }

    if (a > b) {
        let c = a
        a = b
        b = c
    }

    var approx = (b * 1007) + (a * 441)
    if (b < (a << 4)) {
        approx -= (b * 40)
    }

    return ((approx + 512) >> 10)
}

public func polarToCartesian_Degrees(_ angle:Float, _ magnitude:Float) -> Vector<Float> {
    let radians = angle * Float.pi / 180.0;
    let x = cosf( radians ) * magnitude
    let y = sinf( radians ) * magnitude
    return Vector<Float>(x, y)
}

public func polarToCartesian_Degrees(_ angle:Double, _ magnitude:Double) -> Vector<Double> {
    let radians = angle * Double.pi / 180.0;
    let x = cos( radians ) * magnitude
    let y = sin( radians ) * magnitude
    return Vector<Double>(x, y)
}

//
//  ARGB32Diff.swift
//  TestGame
//
//  Created by Isaac Paul on 3/29/23.
//

import Foundation

public struct ARGB32Diff: Equatable, Hashable, Codable {
    
    let diffR:Int16
    let diffG:Int16
    let diffB:Int16
    let diffA:Int16

    let startR:UInt8
    let startG:UInt8
    let startB:UInt8
    let startA:UInt8

    //Color _startColor
    
    init(start:ARGB32, dest:ARGB32) {
        //_startColor = start
        startR = start.r
        startG = start.g
        startB = start.b
        startA = start.a
        diffR = (Int16(dest.r) - Int16(startR))
        diffG = (Int16(dest.g) - Int16(startG))
        diffB = (Int16(dest.b) - Int16(startB))
        diffA = (Int16(dest.a) - Int16(startA))
    }

    public func colorForElapsedRatio(_ elapsedRatio:Double) -> ARGB32 {
        var argb = colorForElapsedRatioInt(elapsedRatio)
        var elapsedColor = ARGB32(rawValue: argb)
        return elapsedColor
    }

    public func colorForElapsedRatioInt(_ elapsedRatio:Double) -> UInt32 {
        var r:UInt32 = UInt32(Double(startR) + Double(diffR) * elapsedRatio)
        var g:UInt32 = UInt32(Double(startG) + Double(diffG) * elapsedRatio)
        var b:UInt32 = UInt32(Double(startB) + Double(diffB) * elapsedRatio)
        var a:UInt32 = UInt32(Double(startA) + Double(diffA) * elapsedRatio)
        var argb = a << 24 + r << 16 + g << 8 + b
        return argb
    }
}

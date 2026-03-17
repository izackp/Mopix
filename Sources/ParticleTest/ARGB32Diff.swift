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
/*
    let startR:UInt8
    let startG:UInt8
    let startB:UInt8
    let startA:UInt8*/

    //Color _startColor
    
    init(start:ARGB32, dest:ARGB32) {
        diffR = (Int16(dest.r) - Int16(start.r))
        diffG = (Int16(dest.g) - Int16(start.g))
        diffB = (Int16(dest.b) - Int16(start.b))
        diffA = (Int16(dest.a) - Int16(start.a))
    }

    public func colorForElapsedRatio(_ start:ARGB32, _ elapsedRatio:Double) -> ARGB32 {
        let argb = colorForElapsedRatioInt(start, elapsedRatio)
        let elapsedColor = ARGB32(rawValue: argb)
        return elapsedColor
    }

    public func colorForElapsedRatioInt(_ start:ARGB32, _ elapsedRatio:Double) -> UInt32 {
        let ratio:Double
        if (elapsedRatio > 1) {
            ratio = 1
        } else if (elapsedRatio < 0) {
            ratio = 0
        } else {
            ratio = elapsedRatio
        }
        
        let r:UInt32 = UInt32(Double(start.r) + Double(diffR) * ratio)
        let g:UInt32 = UInt32(Double(start.g) + Double(diffG) * ratio)
        let b:UInt32 = UInt32(Double(start.b) + Double(diffB) * ratio)
        let a:UInt32 = UInt32(Double(start.a) + Double(diffA) * ratio)
        let argb = a << 24 + r << 16 + g << 8 + b
        return argb
    }
}

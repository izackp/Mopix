//
//  Tracker.swift
//  TestGame
//
//  Created by Isaac Paul on 3/30/23.
//

import Foundation
public struct Tracker
{
    var elapsedRatio:Double
    let modifier:Double

    init(_ targetTime:TimeInterval) {
        elapsedRatio = 0.0
        if (targetTime <= 0.0) {
            modifier = 0.0
            return
        }
        let step = 1.0/targetTime
        modifier = abs(step) //Dividing is slow, so I'm overoptimizing
        
    }

    init(_ milliseconds:Int) {
        elapsedRatio = 0.0
        let ms = Double(milliseconds)
        if (ms <= 0.0) {
            modifier = 0.0
            return
        }
        let step = 1.0/ms
        modifier = abs(step) //Dividing is slow, so I'm overoptimizing
    }

    //TODO: Utimately decide on how to pass delta time from the main loop
    //It makes sense for it have its own type.
    public mutating func progress(_ deltaTime:Double) -> Double {
        elapsedRatio += deltaTime * modifier
        
        if (elapsedRatio > 1.0) {
            elapsedRatio = 1.0
        }
        return elapsedRatio
    }
}

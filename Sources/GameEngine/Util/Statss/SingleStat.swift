//
//  SingleStat.swift
//
//
//  Created by Isaac Paul on 4/22/23.
//

import Foundation

public class SingleStat {
    var average:Double = 0
    var highest:Double = 0
    var lowest:Double = 999 //No Double.max ??
    var last:Double = 0
    
    public func measure(_ block:() throws ->()) rethrows {
        let time = CFAbsoluteTimeGetCurrent()
        try block()
        let elapsed = CFAbsoluteTimeGetCurrent() - time
        insertSample(elapsed)
    }
    
    public func measure<T>(_ block:() throws ->(T)) rethrows -> T {
        let time = CFAbsoluteTimeGetCurrent()
        let result = try block()
        let elapsed = CFAbsoluteTimeGetCurrent() - time
        insertSample(elapsed)
        return result
    }
    
    public func measureOptional<T>(_ block:() throws ->(T?)) rethrows -> T? {
        let time = CFAbsoluteTimeGetCurrent()
        let result = try block()
        let elapsed = CFAbsoluteTimeGetCurrent() - time
        insertSample(elapsed)
        return result
    }
    
    public func insertSample(_ value:Double) {
        average = approxRollingAverage(avg: average, input: value, numSamples: 60)
        if (highest < value) {
            highest = value
        }
        if (lowest > value) {
            lowest = value
        }
        last = value
    }
}

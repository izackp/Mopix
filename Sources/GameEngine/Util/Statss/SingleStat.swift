//
//  SingleStat.swift
//
//
//  Created by Isaac Paul on 4/22/23.
//

import SDL2

public class SingleStat {
    var average:Double = 0
    var highest:Double = 0
    var lowest:Double = 999 //No Double.max ??
    var last:Double = 0
    var limit:Double = 0
    var limitBreak:Double = 0

    func toSeconds(_ time:UInt64) -> Double {
        return Double(time) / Double(SDL_GetPerformanceFrequency())
    }
    
    public func measure(_ block:() throws ->()) rethrows {
        let time = SDL_GetPerformanceCounter()
        try block()
        let elapsed = SDL_GetPerformanceCounter() - time
        insertSample(elapsed)
    }
    
    public func measure<T>(_ block:() throws ->(T)) rethrows -> T {
        let time = SDL_GetPerformanceCounter()
        let result = try block()
        let elapsed = SDL_GetPerformanceCounter() - time
        insertSample(elapsed)
        return result
    }
    
    public func measureOptional<T>(_ block:() throws ->(T?)) rethrows -> T? {
        let time = SDL_GetPerformanceCounter()
        let result = try block()
        let elapsed = SDL_GetPerformanceCounter() - time
        insertSample(elapsed)
        return result
    }
    
    public func insertSample(_ value:UInt64) {
        let result = toSeconds(value)
        insertSample(result)
    }

    public func insertSample(_ value:Double) {
        average = approxRollingAverage(avg: average, input: value, numSamples: 60)
        if (highest < value) {
            highest = value
        }
        if (lowest > value) {
            lowest = value
        }
        if (value > limit && limit != 0) {
            limitBreak += 1
        }
        last = value
    }
}

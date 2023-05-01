//
//  Math.swift
//  
//
//  Created by Isaac Paul on 4/22/23.
//

func approxRollingAverage(avg: Double, input: Double, numSamples:Double) -> Double {
    var result = avg - avg/numSamples
    result += input/numSamples
    return result
}

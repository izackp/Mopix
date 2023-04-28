//
//  StopWatch.swift
//  
//
//  Created by Isaac Paul on 4/22/23.
//

import Foundation
func toStrSmart(_ value:Double) -> String {
    if (value > 0.1) {
        return String(format: "%.3fs ", value)
    }
    return String(format: "%.3fms", value * 1000)
}

public class StopWatch {
    var lastTime:Double
    init() {
        lastTime = CFAbsoluteTimeGetCurrent()
    }
    
    public func reset() -> Double {
        let time = lastTime
        lastTime = CFAbsoluteTimeGetCurrent()
        return lastTime - time
    }
}

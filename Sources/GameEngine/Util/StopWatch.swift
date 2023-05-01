//
//  StopWatch.swift
//  
//
//  Created by Isaac Paul on 4/22/23.
//

import SDL2

func toStrSmart(_ value:Double) -> String {
    if (value > 0.1) {
        return String(format: "%.3fs ", value)
    }
    return String(format: "%.3fms", value * 1000)
}

public class StopWatch {
    var lastTime:UInt64
    init() {
        lastTime = SDL_GetPerformanceCounter()
    }
    
    public func reset() -> Double {
        let time = lastTime
        lastTime = SDL_GetPerformanceCounter()
        return Double(lastTime - time) / Double(SDL_GetPerformanceFrequency())
    }
}

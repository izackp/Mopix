//
//  Stats.swift
//
//
//  Created by Isaac Paul on 4/22/23.
//

import SDL2

public class Stats {
    
    var stats:[String: SingleStat] = [:]
    var enabled:Bool = true
    var shouldPrint:Bool = true
    var printDelay:UInt64 = 10
    var lastPrint:UInt64 = 0
    
    public func measure(_ name:String, _ block:() throws ->()) rethrows {
        if (enabled) {
            let stat = stats.fetchOrInsert(name, {SingleStat()})
            try stat.measure(block)
        } else {
            try block()
        }
    }
    
    public func measure<T>(_ name:String, _ block:() throws -> (T)) rethrows -> T {
        if (enabled) {
            let stat = stats.fetchOrInsert(name, {SingleStat()})
            return try stat.measure(block)
        } else {
            return try block()
        }
    }
    
    public func measuredIt<T>(_ name:String, _ block:@escaping () throws -> (T?)) -> AnyIterator<Result<T, Error>> {
        return AnyIterator {
            do {
                let result:T?
                if (self.enabled == false) {
                    result = try block()
                } else {
                    let stat = self.stats.fetchOrInsert(name, {SingleStat()})
                    result = try stat.measureOptional() {
                        return try block()
                    }
                }
                if let result = result {
                    return .success(result)
                }
            } catch {
                return .failure(error)
            }
            return nil
        }
    }
    
    public func measureOptional<T>(_ name:String, _ block:() throws -> (T?)) rethrows -> T? {
        if (enabled) {
            let stat = stats.fetchOrInsert(name, {SingleStat()})
            return try stat.measure(block)
        } else {
            return try block()
        }
    }
    
    public func insertSample(_ name:String, _ value:Double) {
        if (enabled) {
            let stat = stats.fetchOrInsert(name, {SingleStat()})
            stat.insertSample(value)
        }
    }
    
    public func printStats() {
        if (enabled == false || shouldPrint == false) { return }
        let currentTime = SDL_GetPerformanceCounter() / SDL_GetPerformanceFrequency()
        let delta = currentTime - lastPrint
        if (delta < printDelay) { return }
        lastPrint = currentTime
        print("Stats:")
        var kvpList = stats.map({$0})
        kvpList.sort(by: {
            return $0.key.compare($1.key) == .orderedAscending
        })
        for kvp in kvpList {
            let values = kvp.value
            let average = toStrSmart(values.average)
            let highest = toStrSmart(values.highest)
            let lowest = toStrSmart(values.lowest)
            let last = toStrSmart(values.last)
            print("  Avg: \(average) High: \(highest) Low: \(lowest) Last: \(last) - \(kvp.key)")
        }
        stats.removeAll(keepingCapacity: true)
    }
    
    public func lastStats() -> String {
        var desc = "Stats:"
        var kvpList = stats.map({$0})
        kvpList.sort(by: {
            return $0.key.compare($1.key) == .orderedAscending
        })
        for kvp in kvpList {
            let values = kvp.value
            let last = toStrSmart(values.last)
            desc += "\n  \(last) - \(kvp.key)"
        }
        //stats.removeAll(keepingCapacity: true)
        return desc
    }
}

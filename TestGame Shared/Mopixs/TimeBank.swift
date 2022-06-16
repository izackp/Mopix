//
//  TimeBank.swift
//  TestGame
//
//  Created by Isaac Paul on 4/12/22.
//

import Foundation


//Regulator
public class TickBank {
    var _startTime:UInt64
    var _startTick:UInt64
    var _ticks:UInt64 //relative to start
    var _timePerTick:UInt64 //relative to start
    var _timeBank:UInt64
    
    public init(startTime:UInt64, timePerTick:UInt64, startingTick:UInt64) {
        _startTime = startTime
        _startTick = startingTick
        _timePerTick = timePerTick
        _ticks = 0
        _timeBank = 0
    }
    
    public func matchServer(serverTick:UInt64, rtt:UInt64) {
        
    }

    public func withdrawsAvailable() -> Float {
        return Float(_timeBank) / Float(_timePerTick)
    }

    public func deposit(time:UInt64) {
        _timeBank += time
    }

    public func withdraw() -> Bool {
        if (_timeBank >= _timePerTick) {
            _timeBank -= _timePerTick
            _ticks += 1
            return true
        }
        return false
    }
    
    public func withdrawAll() -> UInt64 {
        let amount = _timeBank / _timePerTick
        let total = amount * _timePerTick
        _timeBank -= total
        _ticks += amount
        return amount
    }

    public func withdraw(amount:UInt64) -> Bool {
        let total = amount * _timePerTick
        if (_timeBank >= total) {
            _timeBank -= total
            _ticks += amount
            return true
        }
        return false
    }
}

//
//  IntervalBank.swift
//  TestGame
//
//  Created by Isaac Paul on 4/12/22.
//

import Foundation

public class IntervalBank {
    var _totalSaved:Int32
    var _cost:Int32
    var _save:Int32

    //Works like a fraction
    //1 withdraw per tick 1, 1
    //2 withdraws per tick 2, 1
    //0.333 withdraws per tick 1, 3
    
    public init(save:Int32, cost:Int32) {
        _cost = cost
        _save = save
        _totalSaved = 0
    }

    public func update(save:Int32, cost:Int32) {
        _cost = cost
        _totalSaved = (Int32)(saveCount() * Float(save))
        _save = save
    }

    public func withdrawsAvailable() -> Float {
        return Float(_totalSaved) / Float(_cost)
    }

    public func saveCount() -> Float {
        return Float(_totalSaved) / Float(_save)
    }

    public func deposit() {
        _totalSaved += _save
    }

    public func withdraw() -> Bool {
        if (_totalSaved >= _cost) {
            _totalSaved -= _cost
            return true
        }
        return false
    }

    public func withdraw(amount:Int32) -> Bool {
        let total = amount * _cost
        if (_totalSaved >= total) {
            _totalSaved -= total
            return true
        }
        return false
    }
}

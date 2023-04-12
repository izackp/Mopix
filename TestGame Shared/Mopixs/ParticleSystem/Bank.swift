//
//  Bank.swift
//  TestGame
//
//  Created by Isaac Paul on 3/20/23.
//

import Foundation
public struct Bank {
    var _totalSaved:Int
    var _cost:Int
    var _save:Int

    //Works like a fraction
    //1 withdraw per tick 1, 1
    //2 withdraws per tick 2, 1
    //0.333 withdraws per tick 1, 3
    init(save:Int, cost:Int) {
        _cost = cost
        _save = save
        _totalSaved = 0
    }

    mutating func update(_ save:Int, _ cost:Int) {
        _cost = cost
        _totalSaved = Int(saveCount() * Float(save))
        _save = save
    }

    public func withdrawsAvailable() -> Float {
        return Float(_totalSaved) / Float(_cost)
    }

    public func saveCount() -> Float {
        return Float(_totalSaved) / Float(_save)
    }

    mutating func deposit() {
        _totalSaved += _save
    }

    public mutating func withdraw() -> Bool {
        if (_totalSaved >= _cost) {
            _totalSaved -= _cost
            return true
        }
        return false
    }

    public mutating func withdraw(_ amount:Int) -> Bool {
        let total = amount * _cost
        if (_totalSaved >= total) {
            _totalSaved -= total
            return true
        }
        return false
    }
}

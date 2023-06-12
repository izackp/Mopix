//
//  Line1D.swift
//  
//
//  Created by Isaac Paul on 6/12/23.
//

public struct Line1D<T: Codable & Numeric>: Equatable, Codable {
    public init(begin: T, length: T) {
        self.begin = begin
        self.length = length
    }
    
    public var begin:T
    public var length:T
    
    //var log = false

    public var beginFree:T {
        get { begin }
        set {
            let diff = (newValue - begin)
            begin += diff
            length -= diff
        }
    }

    public var beginFixed:T {
        get { begin }
        set { begin = newValue }
    }

    public var end:T {
        get { begin + length }
    }

    public var endFree:T {
        get { end }
        set { length = newValue - begin }
    }

    public var endFixed:T {
        get { end }
        set { begin = newValue - length }
    }
}

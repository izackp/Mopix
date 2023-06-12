//
//  Inset.swift
//  
//
//  Created by Isaac Paul on 6/12/23.
//

public struct Inset<T: Codable & Numeric>: Equatable, Codable   {
    public init(left: T, top: T, right: T, bottom: T) {
        self.left = left
        self.top = top
        self.right = right
        self.bottom = bottom
    }
    
    public var left:T
    public var top:T
    public var right:T
    public var bottom:T
    
    public static var zero: Inset<T> {
        get {
            return Inset(left: 0, top: 0, right: 0, bottom: 0)
        }
    }
}

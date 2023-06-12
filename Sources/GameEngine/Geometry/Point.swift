//
//  Point.swift
//  
//
//  Created by Isaac Paul on 6/12/23.
//

public struct Point<T: Codable & Numeric & Hashable>: Equatable, Codable, Hashable {
    public var x:T
    public var y:T
    
    public init(_ x:T, _ y:T) {
        self.x = x
        self.y = y
    }
    
    public static var zero: Point<T> {
        get {
            return Point(0, 0)
        }
    }
    
    public func offset(_ x: T, _ y: T) -> Point<T> {
        return Point(self.x + x, self.y + y)
    }
    
    public static func - (left: Point<T>, right: Point<T>) -> Point<T> {
        return Point<T>(left.x - right.x, left.y - right.y)
    }
    
    public static func + (left: Point<T>, right: Point<T>) -> Point<T> {
        return Point<T>(left.x + right.x, left.y + right.y)
    }
    
    public static func - (left: Point<T>, right: Vector<T>) -> Point<T> {
        return Point<T>(left.x - right.x, left.y - right.y)
    }
    
    public static func + (left: Point<T>, right: Vector<T>) -> Point<T> {
        return Point<T>(left.x + right.x, left.y + right.y)
    }
}


public extension Point where T: BinaryInteger {
    func lerp(_ older:Point<T>, _ percent:Float) -> Point<T>{
        let newX = x.lerp(older.x, percent)
        let newY = y.lerp(older.y, percent)
        return Point<T>(newX, newY)
    }
}

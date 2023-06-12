//
//  Vector.swift
//  
//
//  Created by Isaac Paul on 6/12/23.
//

public struct Vector<T: Codable & Numeric>: Equatable{
    public var x:T
    public var y:T
    
    public init(_ x:T, _ y:T) {
        self.x = x
        self.y = y
    }
    
    public static var zero: Vector<T> {
        get {
            return Vector(0, 0)
        }
    }
    
    public static func - (left: Vector<T>, right: Vector<T>) -> Vector<T> {
        return Vector<T>(left.x - right.x, left.y - right.y)
    }
    
    public static func + (left: Vector<T>, right: Vector<T>) -> Vector<T> {
        return Vector<T>(left.x + right.x, left.y + right.y)
    }
    
    public static func * (left: Vector<T>, right: Vector<T>) -> Vector<T> {
        return Vector<T>(left.x * right.x, left.y * right.y)
    }
    
    public static func - (left: Vector<T>, right: T) -> Vector<T> {
        return Vector<T>(left.x - right, left.y - right)
    }
    
    public static func + (left: Vector<T>, right: T) -> Vector<T> {
        return Vector<T>(left.x + right, left.y + right)
    }
    
    public static func * (left: Vector<T>, right: T) -> Vector<T> {
        return Vector<T>(left.x * right, left.y * right)
    }
}

public extension Vector where T : FloatingPoint {
    static func / (left: Vector<T>, right: Vector<T>) -> Vector<T> {
        return Vector<T>(left.x / right.x, left.y / right.y)
    }
    
    static func / (left: Vector<T>, right: T) -> Vector<T> {
        return Vector<T>(left.x / right, left.y / right)
    }
}

public extension Vector where T: BinaryInteger {
    func lerp(_ older:Vector<T>, _ percent:Float) -> Vector<T>{
        let newX = x.lerp(older.x, percent)
        let newY = y.lerp(older.y, percent)
        return Vector<T>(newX, newY)
    }
}

//TODO: Not public?
extension Vector : Comparable where T == Float  {
    public static func < (lhs: Vector<T>, rhs: Vector<T>) -> Bool {
        return (lhs.x + lhs.y) < (rhs.x + rhs.y)
    }
    
    public static func > (lhs: Vector<T>, rhs: Vector<T>) -> Bool {
        return (lhs.x + lhs.y) > (rhs.x + rhs.y)
    }
}

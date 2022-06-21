//
//  Geometry.swift
//  TestGame
//
//  Created by Isaac Paul on 4/12/22.
//

import Foundation

public struct Inset<T: Numeric>: Equatable  {
    var left:T
    var top:T
    var right:T
    var bottom:T
}

public enum Edge {
    case Left
    case Top
    case Right
    case Bottom
    case Start
    case End
}


public struct Point<T: Numeric>: Equatable {
    var x:T
    var y:T
    
    init(_ x:T, _ y:T) {
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
    
    static func - (left: Point<T>, right: Point<T>) -> Point<T> {
        return Point<T>(left.x - right.x, left.y - right.y)
    }
    
    static func + (left: Point<T>, right: Point<T>) -> Point<T> {
        return Point<T>(left.x + right.x, left.y + right.y)
    }
    
    static func - (left: Point<T>, right: Vector<T>) -> Point<T> {
        return Point<T>(left.x - right.x, left.y - right.y)
    }
    
    static func + (left: Point<T>, right: Vector<T>) -> Point<T> {
        return Point<T>(left.x + right.x, left.y + right.y)
    }
}

public struct Vector<T: Numeric>: Equatable {
    var x:T
    var y:T
    
    init(_ x:T, _ y:T) {
        self.x = x
        self.y = y
    }
    
    public static var zero: Vector<T> {
        get {
            return Vector(0, 0)
        }
    }
    
    static func - (left: Vector<T>, right: Vector<T>) -> Vector<T> {
        return Vector<T>(left.x - right.x, left.y - right.y)
    }
    
    static func + (left: Vector<T>, right: Vector<T>) -> Vector<T> {
        return Vector<T>(left.x + right.x, left.y + right.y)
    }
}

public struct Size<T: Numeric>: Equatable {
    var width:T
    var height:T
    
    init(_ width:T, _ height:T) {
        self.width = width
        self.height = height
    }
    
    public static var zero: Size<T> {
        get {
            return Size(0, 0)
        }
    }
    
    public static var one: Size<T> {
        get {
            return Size(1, 1)
        }
    }
    
    func area() -> T {
        return width * height
    }
}


public struct Frame<T: Numeric>: Equatable {
    var origin:Point<T>
    var size:Size<T>
    
    init(x: T, y: T, width: T, height: T) {
        origin = Point(x, y)
        size = Size(width, height)
    }
    
    init(origin: Point<T>, size: Size<T>) {
        self.origin = origin
        self.size = size
    }
    
    init(min: Point<T>, max: Point<T>) {
        origin = min
        let newSize = max - min
        size = Size(newSize.x, newSize.y)
    }
    
    static var zero: Frame<T> {
        get {
            return Frame(origin: Point.zero, size: Size.zero)
        }
    }
    
    func toTuple() -> (T, T, T, T) {
        return (origin.x, origin.y, size.width, size.height)
    }
    
    var y : T {
        get { return origin.y }
        set { origin.y = newValue }
    }
    
    var x : T {
        get { return origin.x }
        set { origin.x = newValue }
    }

    var width : T {
        get { return size.width }
        set { size.width = newValue }
    }
    
    var height : T {
        get { return size.height }
        set { size.height = newValue }
    }
    
    var left : T {
        get { return origin.x }
        set {
            let diff = (newValue - left)
            x += diff
            width -= diff
        }
    }
    
    var top : T {
        get { return origin.y }
        set {
            let diff = (newValue - origin.y)
            origin.y += diff
            size.height -= diff
        }
    }

    var right : T {
        get { return origin.x + size.width }
        set {
            let diff = (newValue - right)
            size.width += diff
        }
    }

    var bottom : T {
        get { return (origin.y + size.height) }
        set {
            let diff = (newValue - bottom)
            size.height += diff
        }
    }
    
    public mutating func setValueForEdge(_ edge:Edge, _ value:T) {
        switch (edge) {
            case Edge.Top:
                top = value
                break;
            case Edge.Right:
                right = value
                break;
            case Edge.Bottom:
                bottom = value
                break;
            case Edge.Left:
                left = value
                break;
            case .Start:
                break
            case .End:
                break
        }
    }

    public func valueForEdge(_ edge:Edge) -> T
    {
        switch (edge)
        {
            case Edge.Top:
                return top
            case Edge.Right:
                return right
            case Edge.Bottom:
                return bottom
            case Edge.Left:
                return left
            //TODO: Start, End
            case .Start:
                return left
            case .End:
                return left
        }
    }
    
    func bounds() -> Frame<T> {
        return Frame(origin: Point.zero, size: size)
    }
}

//
//  Geometry.swift
//  TestGame
//
//  Created by Isaac Paul on 4/12/22.
//

import Foundation
import SDL2

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

public enum Edge: String, Codable, ExpressibleByString {
    public init(_ value: String) throws {
        self.init(rawValue:value)! //throw GenericError("String not convertible to edge: \(value)")
    }
    
    case Left
    case Top
    case Right
    case Bottom
    case Start
    case End
    /*
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try cont
        var allKeys = ArraySlice(container.allKeys)
        guard let onlyKey = allKeys.popFirst(), allKeys.isEmpty else {
            throw DecodingError.typeMismatch(Edge.self, DecodingError.Context.init(codingPath: container.codingPath, debugDescription: "Invalid number of keys found, expected one.", underlyingError: nil))
        }
        switch onlyKey {
        case .Left:
            let nestedContainer = try container.nestedContainer(keyedBy: Edge.LeftCodingKeys.self, forKey: .Left)
            self = Edge.Left
        case .Top:
            let nestedContainer = try container.nestedContainer(keyedBy: Edge.TopCodingKeys.self, forKey: .Top)
            self = Edge.Top
        case .Right:
            let nestedContainer = try container.nestedContainer(keyedBy: Edge.RightCodingKeys.self, forKey: .Right)
            self = Edge.Right
        case .Bottom:
            let nestedContainer = try container.nestedContainer(keyedBy: Edge.BottomCodingKeys.self, forKey: .Bottom)
            self = Edge.Bottom
        case .Start:
            let nestedContainer = try container.nestedContainer(keyedBy: Edge.StartCodingKeys.self, forKey: .Start)
            self = Edge.Start
        case .End:
            let nestedContainer = try container.nestedContainer(keyedBy: Edge.EndCodingKeys.self, forKey: .End)
            self = Edge.End
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case Left
        case Top
        case Right
        case Bottom
        case Start
        case End
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .Left:
            var nestedContainer = container.nestedContainer(keyedBy: Edge.LeftCodingKeys.self, forKey: .Left)
        case .Top:
            var nestedContainer = container.nestedContainer(keyedBy: Edge.TopCodingKeys.self, forKey: .Top)
        case .Right:
            var nestedContainer = container.nestedContainer(keyedBy: Edge.RightCodingKeys.self, forKey: .Right)
        case .Bottom:
            var nestedContainer = container.nestedContainer(keyedBy: Edge.BottomCodingKeys.self, forKey: .Bottom)
        case .Start:
            var nestedContainer = container.nestedContainer(keyedBy: Edge.StartCodingKeys.self, forKey: .Start)
        case .End:
            var nestedContainer = container.nestedContainer(keyedBy: Edge.EndCodingKeys.self, forKey: .End)
        }
    }*/
}

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

//TODO: Not public? 
extension Vector : Comparable where T == Float  {
    public static func < (lhs: Vector<T>, rhs: Vector<T>) -> Bool {
        return (lhs.x + lhs.y) < (rhs.x + rhs.y)
    }
    
    public static func > (lhs: Vector<T>, rhs: Vector<T>) -> Bool {
        return (lhs.x + lhs.y) > (rhs.x + rhs.y)
    }
}

public struct Size<T: Codable & Numeric>: Equatable, Codable  {
    public var width:T
    public var height:T
    
    public init(_ width:T, _ height:T) {
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

public extension Size<Int> {
    func asInt32() -> Size<Int32> {
        return Size<Int32>(Int32(width), Int32(height))
    }
}

extension Size where T : BinaryInteger {
    public func toInt() -> Size<Int> {
        return Size<Int>(Int(width), Int(height))
    }
}


public extension Size<DValue> {
    func aspectFitScale(_ toSize:Size<DValue>) -> Float {
        let scaleByWidth = Float(toSize.width) / Float(width)
        let scaleByHeight = Float(toSize.height) / Float(height)
        
        let finalScale = Float.minimum(scaleByWidth, scaleByHeight)
        return finalScale
    }
    
    func aspectFillScale(_ toSize:Size<DValue>) -> Float {
        let scaleByWidth = Float(toSize.width) / Float(width)
        let scaleByHeight = Float(toSize.height) / Float(height)
        
        let finalScale = Float.maximum(scaleByWidth, scaleByHeight)
        return finalScale
    }
    
    func aspectFitInto(_ other:Size<DValue>) -> Size<DValue> {
        let scale = aspectFitScale(other)
        return Size(Int16(Float(width)*scale), Int16(Float(height)*scale))
    }
    
    func aspectFillInto(_ other:Size<DValue>) -> Size<DValue> {
        let scale = aspectFillScale(other)
        return Size(Int16(Float(width)*scale), Int16(Float(height)*scale))
    }
    
    func aspectFitNoUpscale(_ toSize:Size<DValue>) -> Size<DValue>? {
        let shouldResize = (width > toSize.width || height > toSize.height)
        if (shouldResize) {
            return aspectFitInto(toSize)
        }
        return nil
    }
    
    func inverse() -> Size<DValue> {
        return Size(height, width)
    }
    
    func aspectRatio() -> Float {
        return Float(width) / Float(height)
    }
    
    func aspectCrop(_ ratio:Float, allowBestMatch:Bool = false) -> Frame<DValue> {
        let isHorizontal = ratio > 1
        let imageIsHorizontal = self.width > self.height
        var ratioToUse = ratio
        if (allowBestMatch) {
            ratioToUse = imageIsHorizontal != isHorizontal ? (1.0 / ratio) : ratio
        }
        let fHeight = Float(self.height)
        let fWidth = Float(self.width)
        
        if (fHeight * ratioToUse <= fWidth) {
            let width = fHeight * ratioToUse
            let offset = (fWidth - width) * 0.5
            let newCrop = Frame(x: Int16(offset/fWidth), y: 0, width: Int16((offset+width)/fWidth), height: 1)
            return newCrop
        }
        
        let height = fWidth * (1.0 / ratioToUse)
        let offset = (fHeight - height) * 0.5
        let newCrop = Frame(x: 0, y: Int16(offset/fHeight), width: 1, height: Int16((offset+height)/fHeight))
        return newCrop
    }
}

public extension SDL_Rect {
    
    public mutating func clip(_ other:Frame<DValue>) {
        if (top < other.top) {
            self.top = Int32(other.y)
        }
        if (self.left < other.left) {
            self.left = Int32(other.left)
        }
        if (bottom > other.bottom) {
            self.bottom = Int32(other.bottom)
        }
        if (self.right > other.right) {
            self.right = Int32(other.right)
        }
    }
}

extension Frame where T: BinaryInteger {
    public var center : Point<T> {
        get { return Point(origin.x + size.width / 2, origin.y + size.height / 2) }
        set {
            origin.x = newValue.x - size.width / 2
            origin.y = newValue.y - size.height / 2
        }
    }
    
    public var centerX : T {
        get { return origin.x + size.width / 2 }
        set {
            origin.x = newValue - size.width / 2
        }
    }
    
    public var centerY : T {
        get { return origin.y + size.height / 2 }
        set {
            origin.y = newValue - size.height / 2
        }
    }
    
    public mutating func clip(_ other:Frame<T>) {
        if (top < other.top) {
            self.top = other.y
        }
        if (self.left < other.left) {
            self.left = other.left
        }
        if (bottom > other.bottom) {
            self.bottom = other.bottom
        }
        if (self.right > other.right) {
            self.right = other.right
        }
    }
    
    public func to<A: Codable & Numeric & Equatable>(_ type:A.Type) -> Frame<A> {
        return Frame<A>(x: A(exactly: x)!, y: A(exactly: y)!, width: A(exactly: width)!, height: A(exactly: height)!)
    }
    
    public func containsPoint(_ point:Point<T>) -> Bool {
        if (point.x < origin.x) { return false }
        if (point.y < origin.y) { return false }
        if (point.x > right) { return false }
        if (point.y > bottom) { return false }
        return true
    }
}

//TODO: Change Name to Rect; What is the best way to name some of these properties?
//Currently (left, right, Top, Bottom) only effects the specific edge (width and height changes)
//We can make this more clear by using xMin, xMax, yMin, yMax..
//However, It doesn't match UI verbage. Or inset verbage.
public struct Frame<T: Codable & Numeric & Hashable>: Equatable, Codable, CustomDebugStringConvertible {
    public static func == (lhs: Frame<T>, rhs: Frame<T>) -> Bool {
        return lhs.x == rhs.x && lhs.y == rhs.y && lhs.width == rhs.width && lhs.height == rhs.height
    }
    
    public var debugDescription: String {
        get {
            return "\(x), \(y) - \(width), \(height)"
        }
    }
    
    
    public var origin:Point<T>
    public var size:Size<T>
    
    public init(x: T, y: T, width: T, height: T) {
        origin = Point(x, y)
        size = Size(width, height)
    }
    
    public init(origin: Point<T>, size: Size<T>) {
        self.origin = origin
        self.size = size
    }
    
    public init(min: Point<T>, max: Point<T>) {
        origin = min
        let newSize = max - min
        size = Size(newSize.x, newSize.y)
    }
    
    private enum CodingKeys: String, CodingKey {
        case x
        case y
        case width
        case height
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let x = try container.decode(T.self, forKey: .x)
        let y = try container.decode(T.self, forKey: .y)
        let width = try container.decode(T.self, forKey: .width)
        let height = try container.decode(T.self, forKey: .height)
        self.origin = Point(x, y)
        self.size = Size(width, height)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(x, forKey: .x)
        try container.encode(y, forKey: .y)
        try container.encode(width, forKey: .width)
        try container.encode(height, forKey: .height)
    }
    
    public static var zero: Frame<T> {
        get {
            return Frame(origin: Point.zero, size: Size.zero)
        }
    }
    
    public func toTuple() -> (T, T, T, T) {
        return (origin.x, origin.y, size.width, size.height)
    }
    
    public func offset(_ offset: Point<T>) -> Frame<T> {
        return Frame(x: x + offset.x, y: y + offset.y, width: width, height: height)
    }
    
    public var y : T {
        get { return origin.y }
        set { origin.y = newValue }
    }
    
    public var x : T {
        get { return origin.x }
        set { origin.x = newValue }
    }
    
    public var width : T {
        get { return size.width }
        set { size.width = newValue }
    }
    
    public var height : T {
        get { return size.height }
        set { size.height = newValue }
    }
    
    public var rightFixed : T {
        get { right }
        set {
            let diff = (newValue - right)
            origin.x += diff
        }
    }

    public var bottomFixed : T {
        get { bottom }
        set {
            let diff = (newValue - bottom)
            origin.y += diff
        }
    }

    public var left : T {
        get { return origin.x }
        set {
            let diff = (newValue - origin.x)
            x += diff
            width -= diff
        }
    }
    
    public var top : T {
        get { return origin.y }
        set {
            let diff = (newValue - origin.y)
            origin.y += diff
            size.height -= diff
        }
    }
    
    //680
    //100, 100 == 480 (680 - 200 = 480) 100 + 480 = 580
    //-100, 100 == 680 (680 - (-100 + 100) = 680) -100 + 680 = 580
    //TODO: Pretty confusing when I can just ignore the existing width and offset from x?
    public var right : T {
        get { return origin.x + size.width }
        set {
            let diff = (newValue - right)
            size.width += diff
        }
    }

    public var bottom : T {
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
    
    public mutating func offsetValueForEdge(_ edge:Edge, _ value:T) {
        switch (edge) {
            case Edge.Top:
                top += value
                break;
            case Edge.Right:
                right += value
                break;
            case Edge.Bottom:
                bottom += value
                break;
            case Edge.Left:
                left += value
                break;
            case .Start:
                break
            case .End:
                break
        }
    }
    
    public mutating func setValueForEdgeFixed(_ edge:Edge, _ value:T) {
        switch (edge) {
            case Edge.Top:
                y = value
                break;
            case Edge.Right:
                rightFixed = value
                break;
            case Edge.Bottom:
                bottomFixed = value
                break;
            case Edge.Left:
                x = value
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
                return y
            case Edge.Right:
                return right
            case Edge.Bottom:
                return bottom
            case Edge.Left:
                return x
            //TODO: Start, End
            case .Start:
                return x
            case .End:
                return x
        }
    }
    
    public func marginForEdge(_ edge:Edge, containerSize:Size<T>) -> T {
        switch (edge) {
        case .Left:
            return x
        case .Top:
            return y
        case .Right:
            return containerSize.width - right
        case .Bottom:
            return containerSize.height - bottom
        case .Start:
            return x
        case .End:
            return containerSize.width - right
        }
    }
    
    public mutating func setMarginForEdge(_ edge:Edge, value:T, container:Size<T>){
        switch (edge) {
        case .Left:
            left = value
        case .Top:
            top = value
        case .Right:
            right = container.width - value
        case .Bottom:
            bottom = container.height - value
        case .Start:
            left = value
        case .End:
            right = container.width - value
        }
    }
    
    func bounds() -> Frame<T> {
        return Frame(origin: Point.zero, size: size)
    }
}

extension Frame where T : BinaryInteger {
    public func toInt16() -> Frame<Int16> {
        return Frame<Int16>(x: Int16(x), y: Int16(y), width: Int16(width), height: Int16(height))
    }
}

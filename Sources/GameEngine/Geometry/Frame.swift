//
//  Frame.swift
//  
//
//  Created by Isaac Paul on 6/12/23.
//

extension Rect where T: BinaryInteger {
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
    
    public mutating func clip(_ other:Rect<T>) {
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
    
    public func to<A: Codable & Numeric & Equatable>(_ type:A.Type) -> Rect<A> {
        return Rect<A>(x: A(exactly: x)!, y: A(exactly: y)!, width: A(exactly: width)!, height: A(exactly: height)!)
    }
    
    public func containsPoint(_ point:Point<T>) -> Bool {
        if (point.x < origin.x) { return false }
        if (point.y < origin.y) { return false }
        if (point.x > right) { return false }
        if (point.y > bottom) { return false }
        return true
    }

    public func lerp(_ older:Rect<T>, _ percent:Float) -> Rect<T> {
        let newOrigin = origin.lerp(older.origin, percent)
        let newSize = size.lerp(older.size, percent)
        return Rect(origin: newOrigin, size: newSize)
    }

}

//TODO: Change Name to Rect; What is the best way to name some of these properties?
//Currently (left, right, Top, Bottom) only effects the specific edge (width and height changes)
//We can make this more clear by using xMin, xMax, yMin, yMax..
//However, It doesn't match UI verbage. Or inset verbage.
public struct Rect<T: Codable & Numeric & Hashable>: Equatable, Codable, CustomDebugStringConvertible {
    public static func == (lhs: Rect<T>, rhs: Rect<T>) -> Bool {
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
    
    public static var zero: Rect<T> {
        get {
            return Rect(origin: Point.zero, size: Size.zero)
        }
    }
    
    public func toTuple() -> (T, T, T, T) {
        return (origin.x, origin.y, size.width, size.height)
    }
    
    public func offset(_ offset: Point<T>) -> Rect<T> {
        return Rect(x: x + offset.x, y: y + offset.y, width: width, height: height)
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
    
    func bounds() -> Rect<T> {
        return Rect(origin: Point.zero, size: size)
    }
}

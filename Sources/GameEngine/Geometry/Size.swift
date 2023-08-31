//
//  Size.swift
//  
//
//  Created by Isaac Paul on 6/12/23.
//


public struct Size<T: Codable & Numeric & Hashable>: Equatable, Codable  {
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

public extension Size where T : BinaryInteger {
    func lerp(_ older:Size<T>, _ percent:Float) -> Size<T>{
        let newWidth = width.lerp(older.width, percent)
        let newHeight = height.lerp(older.height, percent)
        return Size<T>(newWidth, newHeight)
    }
    
    func to<A: Codable & Numeric & Equatable>(_ type:A.Type) -> Size<A> {
        return Size<A>(A(exactly: width)!, A(exactly: height)!)
    }
    
    func center() -> Point<T> {
        return Point(width >> 1, height >> 1)
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
    
    func aspectCrop(_ ratio:Float, allowBestMatch:Bool = false) -> Rect<DValue> {
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
            let newCrop = Rect(x: Int16(offset/fWidth), y: 0, width: Int16((offset+width)/fWidth), height: 1)
            return newCrop
        }
        
        let height = fWidth * (1.0 / ratioToUse)
        let offset = (fHeight - height) * 0.5
        let newCrop = Rect(x: 0, y: Int16(offset/fHeight), width: 1, height: Int16((offset+height)/fHeight))
        return newCrop
    }
}

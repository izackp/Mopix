//
//  ReadOnlyImage.swift
//  
//
//  Created by Isaac Paul on 10/4/23.
//


import SDL2
import SDL2Swift

public class ReadOnlyImage : ImageResource {
    public var id:UInt64
    var _data:PixelData
    
    public init(id: UInt64, data: PixelData) {
        self.id = id
        _data = data
    }
    
    public init(id: UInt64, _ size:Size<Int>) throws {
        self.id = id
        _data = try PixelData(size)
    }

    public func size() -> Size<Int> {
        return _data.size()
    }
    
    public func bounds() -> Rect<Int> {
        return Rect(origin: .zero, size: size())
    }
    
    func copyPixelData() throws -> PixelData {
        return try _data.copy()
    }
    
    func withPixelData<Result>(_ body:(_ pixelData:RawPixelData) throws -> (Result)) throws -> Result {
        return try _data.withPixelData(body)
    }
    
    func toMutable() throws -> EditedImage {
        let result = try EditedImage(from: self)
        return result
    }
    
    func toMutableByEditing(_ body:(_ pixelData:MutableRawPixelData) throws -> ()) throws -> EditedImage {
        let result = try toMutable()
        try result.editPixelData(body)
        return result
    }
    
    internal func getSurface() -> Surface {
        return _data._surface
    }
    
    internal func updatePixelData(_ data:PixelData) {
        _data = data
    }
}

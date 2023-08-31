//
//  PixelData.swift
//  
//
//  Created by Isaac Paul on 8/22/23.
//

import SDL2
import SDL2Swift

public class PixelData {
    internal var _surface:Surface
    
    public init(_ size:Size<Int>) throws {
        _surface = try Surface(rgb: (0, 0, 0, 0), size: (size.width, size.height))
    }
    
    public func size() -> Size<Int> {
        return _surface.size()
    }
    
    public func resize(_ size:Size<Int>) throws {
        //incrementEdit()
        let oldSurface = _surface
        let newSurface = try Surface(rgb: (0, 0, 0, 0), size: (size.width, size.height))
        
        try oldSurface.upperBlit(to: newSurface)
        _surface = newSurface
        /*
        try oldSurface.withPixelData { oldPixelData in
            let oldPxDataSize = oldPixelData.size()
            try self.surface.withMutablePixelData { pixelData in
                let newPxDataSize = pixelData.size()
                for y in 0 ..< Int(oldPxDataSize.height) {
                    if (y >= newPxDataSize.height) { break }
                    let destBuffer = pixelData.ptr
                    let oldDataPitch = (oldPixelData.pitch <= pixelData.pitch) ? oldPixelData.pitch : pixelData.pitch
                    
                    let srcStart = y * oldPixelData.pitch
                    let srcEnd = srcStart + oldDataPitch
                    let data = oldPixelData.ptr[srcStart ..< srcEnd]
                        
                    let destStart = y * pixelData.pitch
                    let destEnd = destStart + pixelData.pitch
                    let destSlice = UnsafeMutableRawBufferPointer(rebasing: pixelData.ptr[destStart ..< destEnd])
                    destSlice.copyBytes(from: data)
                }
            }
        }*/
    }
    
    public func drawPoint(_ x: Int32, _ y:Int32, _ color: UInt32) throws {
        try _surface.drawPoint(Int(x), Int(y), color)
    }
    
    public func fill(rect: SDL_Rect? = nil, color: Color) throws {
        try _surface.fill(rect: rect, color: color)
    }
    
    func withPixelData<Result>(_ body:(_ pixelData:RawPixelData) throws -> (Result)) throws -> Result {
        return try _surface.withPixelData(body)
    }
    
    func withMutablePixelData<Result>(_ body:(_ pixelData:MutableRawPixelData) throws -> (Result)) throws -> Result {
        return try _surface.withMutablePixelData(body)
    }
}

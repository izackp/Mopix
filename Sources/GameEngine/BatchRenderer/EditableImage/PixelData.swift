//
//  PixelData.swift
//  
//
//  Created by Isaac Paul on 8/22/23.
//

import SDL2
import SDL2Swift

//A wrapper for surface because I don't want to expose sdl2.
//Though it would make sense to call it surface
//Though it would be confusing inside of the codebase.
public class PixelData {
    internal var _surface:Surface
    
    public init(_ size:Size<Int>) throws {
        _surface = try Surface(rgb: (0, 0, 0, 0), size: (size.width, size.height))
    }
    
    public init(_ data:[UInt8], _ sourceFormat:SDL_PixelFormat, _ size:Size<Int>) throws {
        _surface = try Surface(data, sourceFormat, size.width, size.height)
    }
    
    internal init(_ surface:Surface) {
        _surface = surface
    }
    
    public func size() -> Size<Int> {
        return _surface.size()
    }
    
    public func copy() throws -> PixelData { //TODO: Shouldn't throw? // We can avoid every error but a failed allocation. Though swift typically doesn't care?
        
        let newSurface = try Surface(rgb: (0, 0, 0, 0), size: (_surface.width, _surface.height))
        try _surface.upperBlit(to: newSurface)
        return PixelData(newSurface)
    }
    
    public func resize(_ size:Size<Int>) throws {
        //incrementEdit()
        let oldSurface = _surface
        let newSurface = try Surface(rgb: (0, 0, 0, 0), size: (size.width, size.height))
        
        try oldSurface.upperBlit(to: newSurface)
        _surface = newSurface
        /* keeping around.. would like to make blitting non-throwing
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
    
    public func withPixelData<Result>(_ body:(_ pixelData:RawPixelData) throws -> (Result)) throws -> Result {
        return try _surface.withPixelData(body)
    }
    
    func withMutablePixelData<Result>(_ body:(_ pixelData:MutableRawPixelData) throws -> (Result)) throws -> Result {
        return try _surface.withMutablePixelData(body)
    }
}

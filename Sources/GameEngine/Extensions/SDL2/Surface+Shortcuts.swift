//
//  Surface+Shortcuts.swift
//  
//
//  Created by Isaac Paul on 4/25/23.
//

import SDL2
import SDL2Swift

public extension Surface {
    
    func size() -> Size<Int> {
        return Size(self.width, self.height)
    }
    
    func bounds() -> Rect<Int> {
        return Rect(origin: .zero, size: Size(self.width, self.height))
    }
    
    func withPixelData<Result>(_ body:(_ pixelData:PixelData) throws -> (Result)) throws -> Result {
        let pitch = self.pitch
        let numBytes = self.height * pitch
        let blank = try self.withUnsafeMutableBytes { (ptr:UnsafeMutableRawPointer) -> Result in
            let bufferPtr = UnsafeRawBufferPointer(start: ptr, count: numBytes)
            let pixelData = PixelData(ptr: bufferPtr, width: self.width, pitch: pitch)
            return try body(pixelData)
        }!
        return blank
    }
    
    func withMutablePixelData<Result>(_ body:(_ pixelData:PixelDataMutable) throws -> (Result)) throws -> Result {
        let pitch = self.pitch
        let numBytes = self.height * pitch
        let blank = try self.withUnsafeMutableBytes { (ptr:UnsafeMutableRawPointer) -> Result in
            let bufferPtr = UnsafeMutableRawBufferPointer(start: ptr, count: numBytes)
            let pixelData = PixelDataMutable(ptr: bufferPtr, width: self.width, pitch: pitch)
            return try body(pixelData)
        }!
        return blank
    }
    /*
    public func toSubTexture(page:Int, _ body:(_ ptr:UnsafeRawBufferPointer, _ size:Size<Int32>, _ pitch:Int) throws -> Allocation?) throws -> SubTexture {
        let pitch = self.pitch
        let numBytes = self.height * pitch
        let size = Size<Int32>(Int32(self.width), Int32(self.height))
        let texture = try self.withUnsafeMutableBytes { (ptr:UnsafeMutableRawPointer) -> SubTexture in
            let bufferPtr = UnsafeRawBufferPointer(start: ptr, count: numBytes)
            guard let alloc = try body(bufferPtr, size, pitch) else {
                throw GenericError("Couldnt save into new page.")
            }
            
            let frame = Rect(origin: alloc.rectangle.origin, size: size)
            return SubTexture(allocationId: alloc.id, texturePageIndex: page, sourceRect: frame)
        }!
        return texture
    }*/
}



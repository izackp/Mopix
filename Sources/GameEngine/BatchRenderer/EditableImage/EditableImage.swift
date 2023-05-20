//
//  EditableImage.swift
//  
//
//  Created by Isaac Paul on 5/9/23.
//

import SDL2
import SDL2Swift

//TODO: Make cached compositions drop on resource reset
public class EditableImage {
    var surface:Surface
    var editIteration:UInt = 0
    
    public init(_ size:Size<Int>) throws {
        self.surface = try Surface(rgb: (0, 0, 0, 0), size: (size.width, size.height))
    }
    
    public func size() -> Size<Int> {
        return self.surface.size()
    }
    
    public func bounds() -> Frame<Int> {
        return Frame(origin: .zero, size: size())
    }
    
    public func resize(_ size:Size<Int>) throws {
        incrementEdit()
        let oldSurface = self.surface
        let newSurface = try Surface(rgb: (0, 0, 0, 0), size: (size.width, size.height))
        
        try newSurface.upperBlit(to: oldSurface)
        self.surface = newSurface
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
    
    //TODO: I don't like this api..
    public func startEdit() {
        incrementEdit()
    }
    
    internal func incrementEdit() {
        if (editIteration == UInt.max) {
            editIteration = 0
        } else {
            editIteration += 1
        }
    }
    
    public func drawPoint(_ x: Int32, _ y:Int32, _ color: UInt32) throws {
        try surface.drawPoint(Int(x), Int(y), color)
    }
    
    public func fill(rect: SDL_Rect? = nil, color: Color) throws {
        incrementEdit()
        try surface.fill(rect: rect, color: color)
    }
    
    func applyChanges() {
        
    }
}

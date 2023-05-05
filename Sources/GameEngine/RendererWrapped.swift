//
//  RendererWrapped.swift
//  
//
//  Created by Isaac Paul on 4/25/23.
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

struct SurfaceBackedTexture {
    internal init(texture: Texture, editIteration:UInt) {
        self.texture = texture
        self.editIteration = editIteration
    }
    
    var editIteration:UInt = 0
    let texture:Texture
}

public class RendererWrapped {
    
    public init(renderer: Renderer, imageManager:SimpleImageManager) {
        self.renderer = renderer
        self.imageManager = imageManager
    }
    
    let imageManager:SimpleImageManager
    let renderer:Renderer
    var cache:[ObjectIdentifier:SurfaceBackedTexture] = [:]
    
    public func draw(_ imageUrl:VDUrl, rect:Frame<Int>, _ color:SDLColor = SDLColor.white, alpha:Float = 1) {
        let image = imageManager.image(imageUrl)
        image?.draw(renderer, rect.sdlRect(), color)
    }
    
    //TODO: Use texture atlas
    func textureFor(_ id:ObjectIdentifier, _ backingImage:EditableImage) throws -> Texture {
        if let existing = cache[id] {
            let texture = existing.texture
            if (existing.editIteration == backingImage.editIteration) {
                return texture
            }
            let backingSurface = backingImage.surface
            let attr = try texture.attributes()
            if (attr.width == backingSurface.width && attr.height == backingSurface.height) {
                try backingImage.surface.withPixelData { pixelData in
                    try texture.update(pixels: pixelData.ptr, pitch: pixelData.pitch)
                }
                
                cache[id]?.editIteration = backingImage.editIteration
                return texture
            }
        }
        let newTexture = try Texture(renderer: renderer, surface: backingImage.surface)
        cache[id] = SurfaceBackedTexture(texture: newTexture, editIteration: backingImage.editIteration)
        return newTexture
    }
    
    public func draw(_ image:EditableImage, rect:Frame<Int>) {
        let objId = ObjectIdentifier(image)
        
        do {
            let texture = try textureFor(objId, image)
            try renderer.copy(texture, destination: rect.sdlRect())
        } catch {
            
        }
    }
}

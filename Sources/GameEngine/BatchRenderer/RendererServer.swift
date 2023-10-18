//
//  RendererServer.swift
//  
//
//  Created by Isaac Paul on 5/9/23.
//

import SDL2
import SDL2Swift
import ChunkedPool

extension BitMaskOptionSet<Renderer.RendererFlip> {
    func hasValue() -> Bool {
        return self.contains(.horizontal) || self.contains(.vertical)
    }
}

public class RendererServer {
    
    public init(renderer: Renderer, imageManager:SimpleImageManager) {
        self.renderer = renderer
        self.imageManager = imageManager
        let resourceStore = ResourceStore(imageManager)
        self.resourceStore = resourceStore
        self.drawingInterpolator = DrawCmdInterpolator(renderer: renderer, resourceStore: resourceStore)
    }
    
    let imageManager:SimpleImageManager
    let resourceStore:ResourceStore
    let renderer:Renderer
    let drawingInterpolator:DrawCmdInterpolator
    
    public func draw(_ imageUrl:VDUrl, rect:Rect<Int>, _ color:SDLColor = SDLColor.white, alpha:Float = 1) {
        guard let image = imageManager.image(imageUrl) else { return }
        renderer.draw(image, rect.sdlRect(), color)
    }

    //TODO: Use texture atlas
    /*
    func textureFor(_ id:UInt64, _ backingImage:EditableImage) throws -> Texture {
        if let existing = cache[id] {
            let texture = existing.texture
            if (existing.editIteration == backingImage.editIteration) {
                return texture
            }
            let size = backingImage.size()
            let attr = try texture.attributes()
            if (attr.width == size.width && attr.height == size.height) {
                try backingImage.withPixelData { pixelData in
                    try texture.update(pixels: pixelData.ptr, pitch: pixelData.pitch)
                }
                
                cache[id]?.editIteration = backingImage.editIteration
                return texture
            }
        }
        let newTexture = try Texture(renderer: renderer, surface: backingImage.getSurface())
        cache[id] = SurfaceBackedTexture(texture: newTexture, editIteration: backingImage.editIteration)
        return newTexture
    }*/
    /*
    public func draw(_ image:EditableImage, rect:Rect<Int>) {
        let objId = ObjectIdentifier(image)
        
        do {
            let texture = try textureFor(objId, image)
            try renderer.copy(texture, destination: rect.sdlRect())
        } catch {
            
        }
    }*/
}


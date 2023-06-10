//
//  BatchRenderer.swift
//  
//
//  Created by Isaac Paul on 5/9/23.
//

import SDL2
import SDL2Swift

public typealias RendererServer = BatchRenderer

public class BatchRenderer {
    
    public init(renderer: Renderer, imageManager:SimpleImageManager) {
        self.renderer = renderer
        self.imageManager = imageManager
    }
    
    let imageManager:SimpleImageManager
    let renderer:Renderer
    var cache:[UInt64:SurfaceBackedTexture] = [:]
    
    var _idImageCache:[UInt64:Image] = [:]
    var _urlImageCache:[String:UInt64] = [:] //TODO: FIX: Also cached in image manager
    var _lastCmdList:[DrawCmdImage] = []
    var _futureCmdList:[DrawCmdImage] = []
    var _futureTime:UInt64 = 0
    
    //MARK: -
    //TODO: Add reference counting
    public func loadResource(_ url:VDUrl) throws -> UInt64 {
        let path = url.absoluteString //TODO: probably doesn't include host
        if let image = _urlImageCache[path] {
            return image
        }
        guard let image = imageManager.image(url) else { throw GenericError("No image")}
        var uuid:UInt64 = 0
        while true {
            uuid = Xoroshiro.shared.randomBytes()
            if (_idImageCache[uuid] == nil && uuid != 0) {
                break
            }
        }
        _idImageCache[uuid] = image
        return uuid
    }
    
    public func unloadResource(_ id:UInt64) {
        _idImageCache[id] = nil
    }
    
    //This looks a little dumb but the idea is that we will want to move this off thread in the future
    //Which does bring up more questions about how to manage that..
    public func loadResources(_ urlList:[VDUrl]) throws -> [UInt64] {
        let result = try urlList.map { (url:VDUrl) in
            try loadResource(url)
        }
        return result
    }
    
    public func unloadResources(_ idList:[UInt64]) {
        for eachId in idList {
            unloadResource(eachId)
        }
    }
    
    //TODO: The problem is that if we ever make changes we can update the image.. but if we update the image we no longer have a way to restore it.
    public func loadImage(_ backingImage:EditableImage) throws -> UInt64 {
        guard let image = imageManager.image(backingImage) else { throw GenericError("No image")}
        var uuid:UInt64 = 0
        while true {
            uuid = Xoroshiro.shared.randomBytes()
            if (_idImageCache[uuid] == nil && uuid != 0) {
                break
            }
        }
        _idImageCache[uuid] = image

        return uuid
    }
    
    public func updateImage(_ id:UInt64, _ backingImage:EditableImage) throws {
        if let existing = _idImageCache[id] {
            //if (existing.editIteration == backingImage.editIteration) { return }
            try imageManager.updateImage(existing, backingImage)
            return
        }
        throw GenericError("Image id \(id) doesn't exist")
    }
    
    /*
    public func updateImage(_ backingImage:EditableImage, _ id:UInt64) throws {
        if let existing = cache[id] {
            let texture = existing.texture
            if (existing.editIteration == backingImage.editIteration) {
                return
            }
            let backingSurface = backingImage.surface
            let attr = try texture.attributes() //TODO: Subtexture has size attrs too
            if (attr.width == backingSurface.width && attr.height == backingSurface.height) {
                try backingImage.surface.withPixelData { pixelData in
                    try texture.update(pixels: pixelData.ptr, pitch: pixelData.pitch)
                }
                
                cache[id]?.editIteration = backingImage.editIteration
                return
            }
        }
        let newTexture = try Texture(renderer: renderer, surface: backingImage.surface)
        cache[id] = SurfaceBackedTexture(texture: newTexture, editIteration: backingImage.editIteration)
    }*/
    
    //MARK: -
    public func draw(_ imageUrl:VDUrl, rect:Frame<Int>, _ color:SDLColor = SDLColor.white, alpha:Float = 1) {
        let image = imageManager.image(imageUrl)
        image?.draw(renderer, rect.sdlRect(), color)
    }

    public func draw(_ command:DrawCmdImage) {
        guard let image = self._idImageCache[command.resourceId] else { return }
        let source = image.getSource()
        renderer.draw(source, command.dest.sdlRect(), command.color)
    }

    //TODO: Sort
    //TODO: interpolate
    public func receiveCmds(_ list:[DrawCmdImage]) {
        var oldList = self._lastCmdList
        self._lastCmdList = _futureCmdList
        oldList.removeAll(keepingCapacity: true)
        oldList.append(contentsOf: list)
        self._futureCmdList = oldList
    }

    func draw(_ time:UInt64) {
        let interpolated = _futureCmdList.map() {
            let id = $0.animationId
            if (id == 0) {
                return $0
            }
            let matching = _lastCmdList.first(where: { $0.animationId == id })
            if let matching = matching {
                return $0.lerp(matching, time)
            } else {
                return $0
            }
        }

        for eachItem in interpolated {
            draw(eachItem)
        }
    }

    //TODO: Use texture atlas
    func textureFor(_ id:UInt64, _ backingImage:EditableImage) throws -> Texture {
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
    /*
    public func draw(_ image:EditableImage, rect:Frame<Int>) {
        let objId = ObjectIdentifier(image)
        
        do {
            let texture = try textureFor(objId, image)
            try renderer.copy(texture, destination: rect.sdlRect())
        } catch {
            
        }
    }*/
}


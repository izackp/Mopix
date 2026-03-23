//
//  ResourceStore.swift
//  
//
//  Created by Isaac Paul on 10/4/23.
//

public class ResourceStore {
    public init(_ imageManager:AtlasLoader) {
        self.imageManager = imageManager
    }
    let imageManager:AtlasLoader
    
    
    var _idImageCache:[UInt64:AtlasImage] = [:] //Not a cache but a lookup table
    var _idDroppableImageTbl:[UInt64:AtlasImage] = [:] //Not a cache but a lookup table
    var _idDataCache:[UInt64:ReadOnlyImage] = [:] //Not a cache but a lookup table
    var _urlImageCache:[String:UInt64] = [:] //TODO: FIX: Also cached in image manager
    var _urlEditableImageCache:[String:ReadOnlyImage] = [:] //TODO: FIX: Also cached in image manager
    var _editableImageHashToId:[UInt64:UInt64] = [:]
    
    //TODO: Inline; Copy from RendererClient
    func idExists(_ id:UInt64) -> Bool {
        if (id == 0) {
            return true
        }
        if (_idImageCache[id] != nil) {
            return true
        }
        return false
    }
    
    func genId() -> UInt64 {
        var uuid:UInt64 = 0
        while true {
            uuid = Xoroshiro.shared.randomBytes()
            if (!idExists(uuid)) {
                break
            }
        }
        return uuid
    }
    
    public func didLoseImageContext() { //Graphics api lost our textures
        
    }
    
    public func fetchResource(_ id:UInt64) throws -> AtlasImage {
        guard let resource = _idImageCache[id] else {
            throw GenericError("No resource with id: \(id)")
        }
        resource.ticksSinceLastUse = 0
        return resource
    }

    public func increaseTicks() {
        for eachResource in _idImageCache.values {
            eachResource.ticksSinceLastUse += 1
        }
    }
    
    let cacheSize:UInt = 1000 * 1000 * 32 //32mb
    
    public func cleanUnusedResources() {
        //NOTE: I have a better idea.
        //When we create a resource we possibly create a texture page
        //instead we check if creating that texture page pushes us over
        //if it does then we remove garbage until we're able to fit the new resource
        let atlas = imageManager.atlas
        let usedBytes = imageManager.atlas.usedVRam()
        if (usedBytes < cacheSize) { return }
        let mapped = _idDroppableImageTbl.map({ ($0.key, $0.value.ticksSinceLastUse) })
        let resources = mapped.sorted {
            $0.1.compare($1.1) == .orderedDescending
        }
        let origNumTextures = atlas.listPages.count
        for eachResource in resources {
            unloadResource(eachResource.0)
            let numTextures = atlas.listPages.count
            if (numTextures < origNumTextures) {
                break
            }
        }
    }
    
    //MARK: - Manual
    //TODO: Add reference counting
    public func loadResourceRaw(_ url:VDUrl) throws -> UInt64 {
        let path = url.absoluteString //TODO: probably doesn't include host
        if let image = _urlImageCache[path] {
            return image
        }
        guard let image = imageManager.image(url) else { throw GenericError("No image")}
        let uuid:UInt64 = genId()
        _idImageCache[uuid] = image
        return uuid
    }
    
    public func loadResourceRaw(_ data:PixelData) throws -> UInt64 {
        //let surface = data._surface
        //let newTexture = try Texture(renderer: renderer, surface: surface)
        //cache[uuid] = SurfaceBackedTexture(texture: newTexture, editIteration: 0)
        //return newTexture
        guard let image = imageManager.image(data) else { throw GenericError("No image")}
        let uuid:UInt64 = genId()
        _idImageCache[uuid] = image
        return uuid
    }
    
    public func loadResourceRaw(_ url:VDUrl, _ choosenId:UInt64) throws -> UInt64 {
        let path = url.absoluteString //TODO: probably doesn't include host
        if let image = _urlImageCache[path] {
            return image
        }
        guard let image = imageManager.image(url) else { throw GenericError("No image")}
        
        let uuid:UInt64
        if (idExists(choosenId)) {
            uuid = genId()
        } else {
            uuid = choosenId
        }
        _idImageCache[uuid] = image
        return uuid
    }
    
    public func loadResourceRaw(_ data:PixelData, _ choosenId:UInt64) throws -> UInt64 {
        //let surface = data._surface
        //let newTexture = try Texture(renderer: renderer, surface: surface)
        //cache[uuid] = SurfaceBackedTexture(texture: newTexture, editIteration: 0)
        //return newTexture
        guard let image = imageManager.image(data) else { throw GenericError("No image")}
        
        let uuid:UInt64
        if (idExists(choosenId)) {
            uuid = genId()
        } else {
            uuid = choosenId
        }
        _idImageCache[uuid] = image
        return uuid
    }
    
    
    public func unloadResource(_ id:UInt64) {
        _idImageCache[id] = nil
    }
    
    public func unloadResources(_ idList:[UInt64]) {
        for eachId in idList {
            unloadResource(eachId)
        }
    }
    
    //MARK: - Managed
    public func loadResource(_ url:VDUrl) throws -> Image {
        let id = try loadResourceRaw(url)
        guard let imageAtlas = _idImageCache[id] else { throw GenericError("No image cached")}
        
        return Image(id: id, size: imageAtlas.size.to(UInt.self))
    }

    public func loadResource(_ image:PixelData) throws -> ReadOnlyImage {
        let id = try loadResourceRaw(image)
        return ReadOnlyImage(id: id, data: image)
    }
    
    public func loadResourceAsEditable(_ url:VDUrl) throws -> ReadOnlyImage {
        //let path = url.absoluteString //TODO: probably doesn't include host
        guard let result = imageManager.imageAndPixels(url) else { throw GenericError("No image")}
        let uuid:UInt64 = genId()
        _idImageCache[uuid] = result.image
        return ReadOnlyImage(id: uuid, data: result.data)
    }
    
    public func loadResources(_ urlList:[VDUrl]) -> [Result<Image, Error>] {
        let results:[Result<Image, Error>] = urlList.map { eachUrl in
            do {
                let image = try loadResource(eachUrl)
                return .success(image)
            } catch {
                return .failure(error)
            }
        }
        return results
    }
    
    public func loadResource(_ url:VDUrl, _ choosenId:UInt64) throws -> Image {
        let id = try loadResourceRaw(url, choosenId)
        guard let imageAtlas = _idImageCache[id] else { throw GenericError("No image cached")}
        
        return Image(id: id, size: imageAtlas.size.to(UInt.self))
    }

    public func loadResource(_ image:PixelData, _ choosenId:UInt64) throws -> ReadOnlyImage {
        let id = try loadResourceRaw(image, choosenId)
        return ReadOnlyImage(id: id, data: image)
    }
    
    public func loadResourceAsEditable(_ url:VDUrl, _ choosenId:UInt64) throws -> ReadOnlyImage {
        guard let result = imageManager.imageAndPixels(url) else { throw GenericError("No image")}
        let uuid:UInt64
        if (idExists(choosenId)) {
            uuid = genId()
        } else {
            uuid = choosenId
        }
        _idImageCache[uuid] = result.image
        return ReadOnlyImage(id: uuid, data: result.data)
    }
    
    public func loadResources(_ urlList:[VDUrl], _ choosenId:[UInt64]) -> [Result<Image, Error>] {
        assert(urlList.count == choosenId.count, "Unexpected choosenId size")
        let results:[Result<Image, Error>] = urlList.enumerated().map { (index, eachUrl) in
            do {
                let image = try loadResource(eachUrl, choosenId[index])
                return .success(image)
            } catch {
                return .failure(error)
            }
        }
        return results
    }
    
    
    public func toImage(_ id:ImageFlyWeight) throws -> Image {
        if let image = _idImageCache[id.id] {
            return Image(id: id.id, size: image.size.to(UInt.self))
        }
        throw GenericError("Image: \(id) does not exist")
    }
    
    public func toEditableImage(_ id:ImageFlyWeight) throws -> ReadOnlyImage {
        throw GenericError("Not yet implemented")
    }
    
    public func unloadResource(_ id:ImageResource) {
        _idImageCache[id.id] = nil
        
    }
    
    public func unloadResources(_ idList:[ImageResource]) {
        for eachItem in idList {
            _idImageCache[eachItem.id] = nil
        }
    }
    
    //Note: if we every support remote rendering, we would need to store the image update via diff
    //Also to support editable image we need to return a readonly version so we don't have duplicate images in memory, but we also have a way to recover
    
    //Problem 2: We have 2 ways to use this.. as a single source of truth or as if we copied and created a new image
    public func updateImage(_ image:EditedImage) throws -> ReadOnlyImage {
        let id = image.id
        if let existing = _idImageCache[id], let existingROI = _idDataCache[id] {
            //if (existing.editIteration == backingImage.editIteration) { return }
            try imageManager.updateImage(existing, image._data)
            existingROI.updatePixelData(image._data)
            return existingROI
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
}


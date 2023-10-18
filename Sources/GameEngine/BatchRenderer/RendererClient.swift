//
//  RendererClient.swift
//  
//
//  Created by Isaac Paul on 5/22/23.
//

import SDL2Swift

//The seperation just allows my brain to work for some reason
//I probably can make this a protocol but we're doing this for now
/*
 So the issue here is we have UIRenderContext which is very similar.
 We need to make RendererClient capable of the same things, to remove it.
 * We add clip info for every draw command
 * We add functionality creating textures out of other textures
 
 Issue 2 is animations. Seems pretty inefficient to animate things twice which
 is what would happen if we have interpolation mixed with our normal animation stuff
 I like the server / Client seperation we have, but I don't think its possible
 to keep it and merge the animation functionality. However it doesn't mean we can't
 reimplement it without the optimization, and if we do use it performance won't matter
 much since the server would be on a remote machine.
 
 is this separation useful? probably not. Why?
 * We can deterministically just run the game on the server and accept input remotely
 * Size of the draw commands could exceed the size of an image file (video streaming) maybe?
   - The greater the framerate over tick rate the less likely this is true.
   - Might be a fun experiement in the future
   - 'Dumb' clients might be a pretty interesting idea. Essentially, you can play any game because
 the client is dumb. Lets say user has 70ms ping, + 1 frame buffer, so a possible delay from input to screen at about 102ms.. You might not need to simulate the game world, but the input delay costs are huge. At less than 40ms.. it turns into something viable. Might be an interesting concept for lan plan..
 */
//Right now everything is using handles
//We don't have to use handles..
//I think we're going to have gen handles locally instead of on server
//Currently we can't do any drawing until we have a handle
//However, there are cases where we can't wait for a handle.
//Image Composition + alpha blending. We can compose an image for a UI view for example
//And we will need to render it immediately. Who can say if that image will be reused next frame
// Also this allows us to guarantee unique ids
//Except in special circumstances I don't want the main engine to even care about whether an image is loaded


/*
 We need to keep a weak reference of all images
 * Keep images alive long enough to be fetched between rollbacks
   A: Track resource usage? No; Images that aren't used but a reference is still needed will be destroyed during a rollback
   B: delay unload requests: Keep a reference around of the image and a time frame. Drop the reference after x time.
 * Remove images that are no longer needed
 */
public enum DrawItem {
    case image(cmd:DrawCmdImage)
    case atlas(x:Int, y:Int, index:Int)
    case square(_ dest:Rect<Int16>, _ color:SDLColor, _ alpha:Float = 1)
}

public struct QueuedUnload {
    let resource:ImageResource
    var ticks:Int
}

enum ResourceError : Error {
    case newId(_ id:UInt64)
}


//How to keep things around on the server?
//
public class RendererClient: IDraw, IResourceContainer {
    
    var cmdList:[DrawCmdImage] = []
    let server:RendererServer
    var cacheList = WeakArray<IResourceCache>()
    public var defaultTime:UInt64 = 0
    public var maxTicksForRollback = 10
    
    //var _lastUsed:[UInt64:Int] = [:] //Store last used id
    var _pinnedIDs:Set<UInt64> = Set() //ids that we dont remove
    private var _toUnload:[QueuedUnload] = []
    var errorForId:[UInt64:Error] = [:]
    var _resourceForId:[UInt64:ImageResource] = [:]
    
    public var _windowSize:Size<Int16> = Size(0, 0)
    public var windowSize:Size<Int16> {
        get {
            return _windowSize
        }
    }

    public init(_ cmdList: [DrawCmdImage] = [], _ server:RendererServer) {
        self.cmdList = cmdList
        self.server = server
    }

    public func addResourceCache(_ cache: IResourceCache) throws {
        //TODO: Assert unique
        //TODO: Maybe not a protocol but a class.. so we can hold onto it and clean it up automatically if it the owner goes out of scope
        cacheList.append(cache)
        try cache.loadResources(self)
        cacheList.clean() //Removes broken weak refs
    }
    
    public func removeResourceCache(_ cache: IResourceCache) {
        cacheList.remove(element: cache)
        cache.unloadResources(self)
        cacheList.clean() //Removes broken weak refs
    }

    func reloadCache() throws {
        cacheList.clean()
        for eachItem in cacheList {
            eachItem?.invalidateCache(self)
            try eachItem?.loadResources(self)
        }
    }
    
    func idExists(_ id:UInt64) -> Bool {
        if (id != 0 && _resourceForId[id] != nil) {
            return false
        }
        return true
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
    
    //MARK: -
    public func draw(_ id:UInt64,
                     _ resourceId:UInt64,
                     _ rect:Rect<Int>,
                     _ color:SDLColor = SDLColor.white,
                     _ z:Int = 1,
                     _ rotation:Float = 0,
                     _ rotationPoint:Point<Int> = .zero,
                     _ alpha:Float = 1,
                     _ clipping:Rect<Int> = Rect.zero,
                     _ relTime:UInt64 = 0) {
       // _lastUsed[resourceId] = 0
        let time = relTime + defaultTime
        cmdList.append(DrawCmdImage(animationId: id, resourceId: resourceId, dest: rect, z: z, alpha:alpha, rotation:rotation, rotationPoint:rotationPoint, clippingRect: clipping, time:time))
    }
    
    public func draw(_ image:DrawCmdImage) {
        //_lastUsed[image.resourceId] = 0
        let time = image.time + defaultTime
        var imgCopy = image
        imgCopy.time = time
        
        cmdList.append(imgCopy)
    }
    
    public func finishDrawing() {
        _toUnload.forEachUncheckedMut { (eachItem:inout QueuedUnload, index:Int) in
            eachItem.ticks -= 1
        }
        _toUnload.removeAll(where: { $0.ticks <= 0 } )
        /*
        for (key, value) in _lastUsed {
            if (value >= maxTicksForRollback) {
                _lastUsed[key] = nil
                unloadResourceRaw(key)
                continue
            }
            _lastUsed[key] = value + 1
        }*/
    }
    

    //MARK: - LOADING
    //So.. These shouldn't throw.. considering the engine wont care mostly..
    //Maybe the engine does care? and needs pixel data or size of an image.
    //await try -> id
    //FW
    
    public func loadResourceAsync(_ url: VDUrl) async throws -> Image {
        let image = try server.resourceStore.loadResource(url)
        return image
    }
    
    public func loadResourceWithPixelDataAsync(_ url: VDUrl) async throws -> ReadOnlyImage {
        let image = try server.resourceStore.loadResourceAsEditable(url)
        return image
    }
    
    public func loadResourceAsync(_ image: PixelData) async throws -> ReadOnlyImage {
        let id = try server.resourceStore.loadResource(image)
        return id
    }
    
    public func loadResourcesAsync(_ urlList: [VDUrl]) async -> [Result<Image, Error>] {
        return server.resourceStore.loadResources(urlList)
    }
    
    public func loadResourceAsync(_ url: VDUrl, _ choosenId: UInt64) async throws -> Image {
        let image = try server.resourceStore.loadResource(url, choosenId)
        return image
    }
    
    public func loadResourceWithPixelDataAsync(_ url: VDUrl, _ choosenId: UInt64) async throws -> ReadOnlyImage {
        let image = try server.resourceStore.loadResourceAsEditable(url, choosenId)
        return image
    }
    
    public func loadResourceAsync(_ image: PixelData, _ choosenId: UInt64) async throws -> ReadOnlyImage {
        let id = try server.resourceStore.loadResource(image, choosenId)
        return id
    }
    
    public func loadResourcesAsync(_ urlList: [VDUrl], _ choosenId: [UInt64]) async -> [Result<Image, Error>] {
        return server.resourceStore.loadResources(urlList, choosenId)
    }
    
    public func loadResource(_ url:VDUrl) -> ImageFlyWeight {
        let uuid = genId()
        let flyWeight = ImageFlyWeight(id: uuid)
        Task {
            do {
                let serverImg = try await loadResourceAsync(url)
                //if (result.id != uuid) { errorForId[uuid] = ResourceError.newId(result.id) }
                if (serverImg.id != uuid) {
                    flyWeight._id = uuid //shouldn't happen
                }
            } catch {
                errorForId[uuid] = error
            }
        }
        return flyWeight
    }
    
    public func loadResource(_ data:PixelData) -> ReadOnlyImage {
        let uuid = genId()
        let img = ReadOnlyImage(id: uuid, data: data)
        _resourceForId[uuid] = img
        Task {
            do {
                let serverImg = try await loadResourceAsync(data)
                //if (result.id != uuid) { errorForId[uuid] = ResourceError.newId(result.id) }
                if (serverImg.id != uuid) {
                    img.id = uuid //shouldn't happen
                }
            } catch {
                errorForId[uuid] = error
            }
        }
        return img
    }
    
    public func loadResources(_ urlList:[VDUrl]) throws -> [ImageFlyWeight] {
        let result = urlList.map { loadResource($0) }
        return result
    }
    
    public func loadResourceRaw(_ url: VDUrl) throws -> UInt64 {
        let uuid = genId()
        Task {
            do {
                let serverImg = try await loadResourceAsync(url)
                if (serverImg.id != uuid) { errorForId[uuid] = ResourceError.newId(serverImg.id) }
            } catch {
                errorForId[uuid] = error
            }
        }
        return uuid
    }
    
    public func loadResourceRaw(_ image: PixelData) throws -> UInt64 {
        
        let uuid = genId()
        Task {
            do {
                let serverImg = try await loadResourceAsync(image)
                if (serverImg.id != uuid) { errorForId[uuid] = ResourceError.newId(serverImg.id) }
            } catch {
                errorForId[uuid] = error
            }
        }
        return uuid
    }
    
    //MARK: - UNLOADING
    public func unloadResource(_ id:ImageResource) {
        //_lastUsed[id.id] = nil
        Task {
            server.resourceStore.unloadResource(id) //permanent
        }
    }
    
    public func unloadResources(_ idList:[ImageResource]) {
        Task {
            server.resourceStore.unloadResources(idList)
        }
    }
    
    public func unloadResourceDelayed(_ id:ImageResource, _ ticks:Int) {
        _toUnload.append(QueuedUnload(resource: id, ticks: ticks))
    }
    
    public func unloadResourcesDelayed(_ idList:[ImageResource], _ ticks:Int) {
        for eachItem in idList {
            _toUnload.append(QueuedUnload(resource: eachItem, ticks: ticks))
        }
    }
    
    //MARK: - Conversions
    public func updateImage(_ image:EditedImage) throws -> ReadOnlyImage {
        return try server.resourceStore.updateImage(image)
    }
    
    public func toImage(_ id: ImageFlyWeight) async throws -> Image {
        return try server.resourceStore.toImage(id)
    }
    
    public func toEditableImage(_ id: ImageFlyWeight) async throws -> ReadOnlyImage {
        return try server.resourceStore.toEditableImage(id)
    }
    
    //MARK: -
    public func keepAliveAfterDeath(_ milliseconds: Int) {
        
    }
    
    /*
    public func pinResource(_ id:UInt64) -> Bool {
        let (contained, _) = _pinnedIDs.insert(id)
        _lastUsed[id] = nil
        return !contained
    }
    
    public func unpinResource(_ id:UInt64) -> Bool {
        let contained = _pinnedIDs.remove(id)
        _lastUsed[id] = 0
        return contained != nil
    }*/

    //MARK: -
    public func clearCommands() {
        cmdList.removeAll(keepingCapacity: true)
    }

    public func sendCommands() {
        if (cmdList.count > 0) {
            server.drawingInterpolator.receiveCmds(cmdList)
        }
    }
    
    public func createImage(_ block:(_ context:IDraw) throws -> (), size:Size<DValue>) throws -> UInt64 {
        let builder = ImageBuilder(client: self)
        try block(builder)
        return builder.finalize()
    }
    /*
    func createAndDrawToTexture(_ block:(_ context:RendererClient, _ frame:Rect<DValue>) throws -> (), size:Size<DValue>) throws -> AtlasImage {
        let atlas = imageManager.atlas
        let subTexture = try atlas.saveBlankImage(size)
        let targetImage = AtlasImage(texture: subTexture, atlas: atlas)
        //we must use the correct texture
        let pageIndex = subTexture.texturePageIndex
        let texture = rollingTextureForPage[pageIndex] ?? atlas.listPages[pageIndex].texture
        
        //let previousBlendmode = blendMode
        let previousTarget = try renderer.swapTarget(texture)
        let targetFrame = targetImage.sourceRect.to(Int16.self)
        currentWindowFrame.append(targetFrame)
        let lastClip = currentClipRect
        try setClipRect(targetFrame)
        destinationPage.append(pageIndex)
        //blendMode = .none
        
        try block(self, targetFrame)
        
        usingNewPage = false
        destinationPage.removeLast()
        currentWindowFrame.removeLast()
        //blendMode = previousBlendmode
        
        try setClipRect(lastClip)
        
        if let tempImage = rollingTextureForPage[pageIndex] {
            let old = atlas.listPages[pageIndex].texture
            let newPage = TexturePage(texture: tempImage, allocator: atlas.listPages[pageIndex].allocator)
            atlas.listPages[pageIndex] = newPage
            atlas.returnTexture(old)
            rollingTextureForPage[pageIndex] = nil
        }
        
        let prevPageIndex = destinationPage.last!
        if (prevPageIndex == -1) {
            try renderer.setTarget(previousTarget)
        } else if let target = rollingTextureForPage[prevPageIndex] {
            try renderer.setTarget(target)
            usingNewPage = true
        } else {
            let target = atlas.listPages[prevPageIndex].texture
            try renderer.setTarget(target)
        }
        
        return targetImage
    }*/
}

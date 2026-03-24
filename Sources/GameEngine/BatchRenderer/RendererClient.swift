//
//  RendererClient.swift
//
//
//  Created by Isaac Paul on 5/22/23.
//

import SDL2Swift

//The seperation (Client/Server) just allows my brain to work for some reason
/*

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
    case image(cmd: DrawCmd)
    case atlas(x: Int, y: Int, index: Int)
    case square(_ dest: Rect<Int16>, _ color: SDLColor, _ alpha: Float = 1)
}

public struct QueuedUnload {
    let resource:ImageResource
    var ticks:Int
}

enum ResourceError : Error {
    case newId(_ id:UInt64)
}

public class RendererClient: IDraw, IResourceContainer {

    var cmdList:[DrawCmd] = []
    let server:any IRendererServer
    public var defaultTime:UInt64 = 0
    public var maxTicksForRollback = 10
    var cacheList = WeakArray<IResourceCache>()

    //var _lastUsed:[UInt64:Int] = [:] //Store last used id
    //var _pinnedIDs:Set<UInt64> = Set() //ids that we dont remove
    private var _toUnload:[QueuedUnload] = []
    var errorForId:[UInt64:Error] = [:]
    var _resourceForId:[UInt64:ImageResource] = [:]

    public var _windowSize:Size<Int16> = Size(0, 0)
    public var windowSize:Size<Int16> {
        get {
            return _windowSize
        }
    }

    public init(_ cmdList: [DrawCmd] = [], _ server: any IRendererServer) {
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
        if (id == 0) {
            return true
        }
        if (_resourceForId[id] != nil) {
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

    //MARK: -
    public func draw(_ id: UInt64,
                     _ resourceId: UInt64,
                     _ rect: Rect<Int>,
                     _ color: SDLColor = SDLColor.white,
                     _ z: Int = 1,
                     _ rotation: Float = 0,
                     _ rotationPoint: Point<Int> = .zero,
                     _ alpha: Float = 1,
                     _ clipping: Rect<Int> = Rect.zero,
                     _ relTime: UInt64 = 0) {
        let time = relTime + defaultTime
        let cmd = DrawCmd(animationId: id, parentAnimationId: 0, dest: rect, color: color, alpha: alpha, z: z, rotation: rotation, rotationPoint: rotationPoint, clippingRect: clipping, flip: [], time: time, type: .image(resourceId: resourceId))
        cmdList.append(cmd)
    }

    public func drawCmd(_ cmd: DrawCmd) {
        cmdList.append(cmd)
    }

    public func finishDrawing() {
        _toUnload.forEachUncheckedMut { (eachItem:inout QueuedUnload, index:Int) in
            eachItem.ticks -= 1
        }
        _toUnload.removeAll(where: { $0.ticks <= 0 } )
    }


    //MARK: - LOADING

    public func loadResourceAsync(_ url: VDUrl) async throws -> Image {
        return try await server.loadResource(url)
    }

    public func loadResourceWithPixelDataAsync(_ url: VDUrl) async throws -> ReadOnlyImage {
        return try await server.loadResourceAsEditable(url)
    }

    public func loadResourceAsync(_ image: PixelData) async throws -> ReadOnlyImage {
        return try await server.loadResource(image)
    }

    public func loadResourcesAsync(_ urlList: [VDUrl]) async -> [Result<Image, Error>] {
        return await server.loadResources(urlList)
    }

    public func loadResourceAsync(_ url: VDUrl, _ choosenId: UInt64) async throws -> Image {
        return try await server.loadResource(url, choosenId)
    }

    public func loadResourceWithPixelDataAsync(_ url: VDUrl, _ choosenId: UInt64) async throws -> ReadOnlyImage {
        return try await server.loadResourceAsEditable(url, choosenId)
    }

    public func loadResourceAsync(_ image: PixelData, _ choosenId: UInt64) async throws -> ReadOnlyImage {
        return try await server.loadResource(image, choosenId)
    }

    public func loadResourcesAsync(_ urlList: [VDUrl], _ choosenId: [UInt64]) async -> [Result<Image, Error>] {
        return await server.loadResources(urlList, choosenId)
    }

    public func loadResource(_ url:VDUrl) -> ImageFlyWeight {
        let uuid = genId()
        let flyWeight = ImageFlyWeight(id: uuid)
        Task {
            do {
                let serverImg = try await loadResourceAsync(url, uuid)
                //if (result.id != uuid) { errorForId[uuid] = ResourceError.newId(result.id) }
                if (serverImg.id != uuid) {
                    flyWeight._id = uuid //shouldn't happen
                }
            } catch {
                await MainActor.run() {
                    errorForId[uuid] = error
                }
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
                let serverImg = try await loadResourceAsync(data, uuid)
                //if (result.id != uuid) { errorForId[uuid] = ResourceError.newId(result.id) }
                if (serverImg.id != uuid) {
                    img.id = uuid //shouldn't happen
                }
            } catch {
                await MainActor.run() {
                    errorForId[uuid] = error
                }
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
                let serverImg = try await loadResourceAsync(url, uuid)
                if (serverImg.id != uuid) { errorForId[uuid] = ResourceError.newId(serverImg.id) }
            } catch {
                await MainActor.run() {
                    errorForId[uuid] = error
                }
            }
        }
        return uuid
    }

    public func loadResourceRaw(_ image: PixelData) throws -> UInt64 {

        let uuid = genId()
        Task {
            do {
                let serverImg = try await loadResourceAsync(image, uuid)
                if (serverImg.id != uuid) { errorForId[uuid] = ResourceError.newId(serverImg.id) }
            } catch {
                await MainActor.run() {
                    errorForId[uuid] = error
                }
            }
        }
        return uuid
    }

    //MARK: - UNLOADING
    public func unloadResource(_ id: ImageResource) {
        Task { await server.unloadResource(id) }
    }

    public func unloadResources(_ idList: [ImageResource]) {
        Task { await server.unloadResources(idList) }
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
    public func updateImage(_ image: EditedImage) async throws -> ReadOnlyImage {
        return try await server.updateImage(image)
    }

    public func toImage(_ id: ImageFlyWeight) async throws -> Image {
        return try await server.toImage(id)
    }

    public func toEditableImage(_ id: ImageFlyWeight) async throws -> ReadOnlyImage {
        return try await server.toEditableImage(id)
    }

    //MARK: -
    public func keepAliveAfterDeath(_ milliseconds: Int) {

    }

    //MARK: -
    public func clearCommands() {
        cmdList.removeAll(keepingCapacity: true)
    }

    public func sendCommands() {
        guard cmdList.count > 0 else { return }
        Task { await server.receiveCmds(self.cmdList) }
    }
}

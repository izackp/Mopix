//
//  RendererClient.swift
//  
//
//  Created by Isaac Paul on 5/22/23.
//

import SDL2Swift

//The seperation just allows my brain to work for some reason
//I probably can make this a protocol but we're doing this for now
public class RendererClient {
    
    var cmdList:[DrawCmdImage] = []
    let server:RendererServer
    var cacheList = WeakArray<IResourceCache>()
    public var defaultTime:UInt64 = 0

    public init(_ cmdList: [DrawCmdImage] = [], _ server:RendererServer) {
        self.cmdList = cmdList
        self.server = server
    }

    public func addResourceCache(_ cache: IResourceCache) {
        //TODO: Assert unique
        //TODO: Maybe not a protocol but a class.. so we can hold onto it and clean it up automatically if it the owner goes out of scope
        cacheList.append(cache)
        cache.loadResources(self)
        cacheList.clean()
    }
    
    public func removeResourceCache(_ cache: IResourceCache) {
        cacheList.remove(element: cache)
        cache.unloadResources(self)
        cacheList.clean()
    }

    func needsReload() {
        cacheList.clean()
        for eachItem in cacheList {
            eachItem?.invalidateCache(self)
            eachItem?.loadResources(self)
        }
    }
    
    //MARK: -
    public func draw(_ id:UInt64, _ resourceId:UInt64, _ rect:Frame<Int>, _ color:SDLColor = SDLColor.white, _ z:Int = 1, _ rotation:Float = 0, _ rotationPoint:Point<Int> = .zero, _ alpha:Float = 1, _ relTime:UInt64 = 0) {
        //let image = _idImageCache[id]
        //image?.draw(renderer, rect.sdlRect(), color)
        let time = relTime + defaultTime
        cmdList.append(DrawCmdImage(animationId: id, resourceId: resourceId, dest: rect, z: z, rotation:rotation, rotationPoint:rotationPoint, alpha:alpha, time:time))
    }

    //MARK: -
    public func loadResource(_ url:VDUrl) -> UInt64 {
        return server.loadResource(url)
    }
    
    public func unloadResource(_ id:UInt64) {
        return server.unloadResource(id)
    }
    
    public func loadResources(_ urlList:[VDUrl]) -> [UInt64] {
        return server.loadResources(urlList)
    }
    
    public func unloadResources(_ idList:[UInt64]) {
        return server.unloadResources(idList)
    }

    //MARK: -
    public func clearCommands() {
        cmdList.removeAll(keepingCapacity: true)
    }

    public func sendCommands() {
        if (cmdList.count > 0) {
            server.receiveCmds(cmdList)
        }
    }
}

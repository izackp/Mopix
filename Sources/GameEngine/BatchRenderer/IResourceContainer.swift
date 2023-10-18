//
//  File.swift
//  
//
//  Created by Isaac Paul on 9/21/23.
//

/*
 So resources need to stick around for several ticks to avoid reloading them.
 EditableImage will probably need a hash so we don't recreate it on rollback
 Rollback will cause particle emitters to run twice.. We will have to hash and compare the request
 
 Also needed: Sound
 
 scenario:
 * Recreate world from x steps ago
 * Delete current world
 * Image exists but not yet used
 
 scnario 2:
 * Image becomes unused/deleted
 * Several steps happen
 * Rollback undo's image delete
 
 Scenario 3:
 * Can we skip unload when asset already exists during a rollback? (yes if we fetch the original class)
 
 solutions:
 * When deserializing use the render client to create the resources
 * Manually destroy ?
 
 ----
 I think I remember my other idea:
 We have ids for most things
 The client tracks how much it is used
 if the id is not used for x amount of time it is 'dropped'
 
 Maybe I'm overthinking and mixing caching with 'liveliness' . In one scenario we know when things are no longer used, and the other we can only free caches because the handle still maybe used in the future. I guess it comes down to: do I want reference counting or 'manual memory management' here.
 
 Ok so manual vs automatic reference counting
 
 ok it would be cool to just be able to render with a url
 */

/*
 init(SimpleImageManager)
 didLoseImageContext()
 loadResourceRaw(VDUrl) throws -> UInt64
 loadResourceRaw(PixelData) throws -> UInt64
 loadResource(VDUrl) throws -> Image
 loadResourceAsEditable(PixelData) throws -> EditableImage
 loadResourceAsEditable(VDUrl) throws -> EditableImage
 loadResources([VDUrl]) -> [Result[Image, Error]]
 toImage(ImageFlyWeight) throws -> Image
 toEditableImage(ImageFlyWeight) throws -> EditableImage
 unloadResource(ImageResource)
 unloadResource([ImageResource])
 keepAliveAfterDeath(Int)
 unloadResource(UInt64)
 unloadResources([UInt64])
 updateImage(EditableImage) throws
 */
public protocol IResourceContainer {
    func loadResourceAsync(_ url:VDUrl)               async throws -> Image
    func loadResourceAsync(_ image:PixelData)         async throws -> ReadOnlyImage
    func loadResourcesAsync(_ urlList:[VDUrl])        async        -> [Result<Image, Error>]
    func toImage(_ id:ImageFlyWeight)                 async throws -> Image
    func toEditableImage(_ id:ImageFlyWeight)         async throws -> ReadOnlyImage
    
    
    func loadResourceRaw(_ url:VDUrl) throws -> UInt64
    func loadResourceRaw(_ image:PixelData) throws -> UInt64
    func loadResource(_ url:VDUrl)       throws -> ImageFlyWeight
    func loadResource(_ image:PixelData) throws -> ReadOnlyImage
    func loadResources(_ urlList:[VDUrl]) throws -> [ImageFlyWeight]
    func unloadResource(_ id:ImageResource)
    func unloadResources(_ idList:[ImageResource])
    
    func keepAliveAfterDeath(_ milliseconds:Int)
    
    func updateImage(_ image:EditedImage) throws -> ReadOnlyImage
    
    //~~I cant remember why we need this.~~ My other idea was to never call unload. So if we did something like unload a level we could call softDrop so the client doesn't have to wait to drop.
    //This is for unpinned resources as pinned resources are never dropped.
    //func softDropResource(_ idList:ImageResource) //Hint to not cache resource anymore.
    //I think I wanted an unmanaged api for images
    //func pinResource(_ id:ImageResource) -> Bool
    //func unpinResource(_ id:ImageResource) -> Bool
    
    //Remote images
    //func loadResource(_ url:Url) throws -> ImageFlyWeight
    //func loadResourceAsync(_ url:VDUrl) async throws -> Image
    //func setInMemoryCacheSize(_ bytes:UInt)
    //func setDiskCacheSize(_ bytes:UInt)
    //Copy sdwebimage?
}

//
//  SpriteAtlas.swift
//  TestGame
//
//  Created by Isaac Paul on 4/20/22.
//

import Foundation
import SDL2
import SDL2_ttf

/*
 So there is an issue. We're going to have rolling texture pages, because there are cases when we need to be able to write to the texture page
 using the same texture page!
 When this occurs we create a new page by copying the old then writing one part of the change. After this the old page is 'old' but it isn't yet discard.
 We keep it around because what if the next thing we're drawing also needs to do the same thing since we're still drawing to the same allocation
 we don't want to keep creating new textures. We can start x amount of images and still use the old. Once an image is complete this all changes.
 The next op that makes use use the same texture on itself again will need to make a new texture.
 
 What do we do with old textures? We push / Pop them into a stack simple, easy, no need to create / destroy textures.
 
 I'm not sure if this should be done in the texture page structure...
 */

public struct TexturePage {
    //Incomplete meaning that there are no additional images completed that differ from the previous texture.
    //
    //Once any image has completed drawing we shift it down into texture. So it can resume normal behavior.
    //public let inCompleteTexture:SDLTexture? //Needed for drawing the texture onto iteself
    public let texture:SDLTexture //Always used for drawing and can be drawn to _unless_ there is an incomplete texture whish should also be used
    public let allocator:AtlasAllocator
}

public struct SubTexture {
    public let allocationId:AllocId
    public let texturePageIndex:Int
    //Maybe image atlas?
    public let sourceRect:Frame<Int32>
}

public struct PixelData {
    public let ptr:UnsafeRawBufferPointer
    public let width:Int
    public let pitch:Int
    
    func size() -> Size<Int32> {
        let len = ptr.count
        let height = len / pitch
        let size = Size<Int32>(Int32(width), Int32(height))
        return size
    }
}

extension SDLSurface {
    
    public func withPixelData<Result>(_ body:(_ pixelData:PixelData) throws -> (Result)) throws -> Result {
        let pitch = self.pitch
        let numBytes = self.height * pitch
        let blank = try self.withUnsafeMutableBytes { (ptr:UnsafeMutableRawPointer) -> Result in
            let bufferPtr = UnsafeRawBufferPointer(start: ptr, count: numBytes)
            let pixelData = PixelData(ptr: bufferPtr, width: self.width, pitch: pitch)
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
            
            let frame = Frame(origin: alloc.rectangle.origin, size: size)
            return SubTexture(allocationId: alloc.id, texturePageIndex: page, sourceRect: frame)
        }!
        return texture
    }*/
}




//Notes: Storing a 1D texture makes sense (to my limited knowledge) especially when it comes to texture packing
// However.. I'm not sure how to render a piece of the texture.. uv maps are 2d right?
//https://nical.github.io/posts/etagere.html
public class ImageAtlas {
    
    let renderer:SDLRenderer
    //1024 because why not
    //renderer->info.max_texture_width
    var listPages = Arr<TexturePage>.init() //Note assuming relatively small array
    var textureSize = Size<Int32>(1024, 1024)
    
    //Each texture has a blank pixel so we don't need to worry about switching textures.
    var _blankImageCache:[SubTexture] = [] //index matches page
    var textureCache:[SDLTexture] = [] //Object pool to avoid creating/deleting
    
    init(_ renderer:SDLRenderer) {
        self.renderer = renderer
    }

    func blankSubtexture(_ pageIdx:Int) throws -> SubTexture {
        if _blankImageCache.count == 0 {
            let _ = try addPage()
        }
        var index = pageIdx
        if index > _blankImageCache.count {
            index = 0
        }
        return _blankImageCache[index]
    }
    
    private func nextPageThatFits(_ start:Int, _ size:Size<UInt32>) -> Int {
        let space = size.area()
        return nextPageThatFits(start, space)
    }
    
    private func nextPageThatFits(_ start:Int, _ space:UInt32) -> Int {
        for i in 0..<listPages.count {
            if listPages[i].allocator.free_space() >= space {
                return i
            }
        }
        return -1
    }
    
    func createTexture() throws -> SDLTexture {
        if let existing = textureCache.popLast() {
            return existing
        }
        //TODO: Why does this have to be streaming to call lockAndEdit, but it can be static for updateTexture?
        let newTexture = try SDLTexture(renderer: renderer, format: .argb8888, access: .target, width: Int(textureSize.width), height: Int(textureSize.height))
        try newTexture.setBlendMode([SDLBlendMode.alpha])
        return newTexture
    }
    
    private func addPage() throws -> Int {
        
        let newTexture = try createTexture()
        //TODO: Not really needed; only used to visualize uninitied memory
        /*
        try newTexture.lockAndEditSurface(rect: nil) { (surface:SDLSurface) in
            let color = SDLColor.pink
            try surface.fill(color: color)
        }*/
        
        let allocator = AtlasAllocator(size: textureSize)
        var texturePage = TexturePage(texture: newTexture, allocator: allocator)
        listPages.append(texturePage)
        
        //Add blank texture for solid rectangles
        let surface = try buildBlankSurface()
        let index = listPages.count - 1
        let blank:SubTexture = try surface.withPixelData { pixelData in
            guard let texture = try saveIntoPage(&texturePage, index, pixelData) else {
                throw GenericError("Couldnt save into new page.")
            }
            return texture
        }
        
        _blankImageCache.append(blank)
        
        return index
    }
    
    func buildBlankSurface() throws -> SDLSurface {
        let surface = try SDLSurface(rgb: (0, 0, 0, 0), size: (width: 3, height: 3), depth: 32)
        let color = SDLColor.white
        try surface.fill(color: color)
        return try surface.convertSurface(format: SDL_PIXELFORMAT_ARGB8888)
    }
    
    //TODO: I was told its faster/better to convert the surface to a texture and then render it on to the atlas
    func save(_ preformat:SDLSurface) throws -> SubTexture {
        let surface = try preformat.convertSurface(format: SDL_PIXELFORMAT_ARGB8888)
        let texture:SubTexture = try surface.withPixelData { pixelData in
            return try save(pixelData)
        }
        return texture
    }
    
    func save(_ data:Data, width:Int, pitch:Int) throws -> SubTexture {
        return try data.withUnsafeBytes { (ptr:UnsafeRawBufferPointer) in
            let pixelData = PixelData(ptr: ptr, width: width, pitch: pitch)
            return try save(pixelData)
        }
    }
    
    func save(_ pixelData:PixelData) throws -> SubTexture {
        let space = UInt32(pixelData.size().area())
        var pageIdx = nextPageThatFits(0, space)
        while (pageIdx != -1) {
            guard let texture = try saveIntoPage(&listPages[pageIdx], pageIdx, pixelData) else {
                pageIdx = nextPageThatFits(pageIdx + 1, space)
                continue
            }
            return texture
        }
        let createdIndex = try addPage()
        guard let texture = try saveIntoPage(&listPages[createdIndex], createdIndex, pixelData) else {
            throw SDLError(errorMessage: "Cant save texture", debugInformation: nil)
        }
        return texture
    }
    
    public func saveBlankImage(_ size:Size<DValue>) throws -> SubTexture {
        if (size.width > textureSize.width || size.height > textureSize.height) {
            throw GenericError("Blank Image cannot exceed atlas texture size.")
        }
        let surface = try SDLSurface(rgb: (0, 0, 0, 0), size: (width: Int(size.width), height: Int(size.height)), depth: 32)
        let color = SDLColor.clear
        try surface.fill(color: color)
        let subTexture = try self.save(surface)
        return subTexture
    }
    
    private func saveIntoPage(_ page: inout TexturePage, _ index:Int, _ pixelData:PixelData) throws -> SubTexture? {
        guard let alloc = try saveIntoPageLow(&page, pixelData) else {
            return nil
        }
        let frame = Frame(origin: alloc.rectangle.origin, size: pixelData.size())
        return SubTexture(allocationId: alloc.id, texturePageIndex: index, sourceRect: frame)
    }
    
    private func saveIntoPageLow(_ page: inout TexturePage, _ pixelData:PixelData) throws -> Allocation? {
        let size = pixelData.size()
        guard let alloc = page.allocator.allocate(size_: size) else { return nil }
        do {
            var frame = alloc.rectangle
            frame.size = size //The allocator will over allocate (or add padding)
            try page.texture.update(for: frame.sdlRect(), pixels: pixelData.ptr, pitch: pixelData.pitch)
        } catch {
            page.allocator.deallocate(alloc.id)
            throw error
        }
        
        return alloc
    }
    
    func returnTexture(_ texture:SDLTexture) {
        textureCache.append(texture)
    }
    
    func returnSubtexture(_ subTexture:SubTexture) {
        //TODO: There is no mechanism to remove a texture page once created..
        let page = listPages[subTexture.texturePageIndex]
        page.allocator.deallocate(subTexture.allocationId)
    }
    
    /*
    func loadIntoTexture(_ data:Data) -> SDLTexture {
        return try! SDLTexture(renderer: renderer, format: .argb8888, access: .static, width: 1, height: 1)
    }*/
}

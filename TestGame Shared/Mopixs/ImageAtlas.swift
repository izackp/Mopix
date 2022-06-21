//
//  SpriteAtlas.swift
//  TestGame
//
//  Created by Isaac Paul on 4/20/22.
//

import Foundation
import SDL2

public struct TexturePage {
    public let texture:SDLTexture
    public let allocator:AtlasAllocator
}

public struct SubTexture {
    public let allocationId:AllocId
    public let texturePageIndex:Int
    //Maybe image atlas?
    public let sourceRect:Frame<Int32>
}

public class Image {
    public init(texture: SubTexture, atlas: ImageAtlas) {
        self.texture = texture
        self.atlas = atlas
    }
    
    let texture:SubTexture
    let atlas:ImageAtlas
    
    deinit {
        atlas.returnTexture(texture)
    }
    
    func draw(_ renderer:SDLRenderer, _ dest:SDL_Rect) {
        let sdlTexture = atlas.listPages[texture.texturePageIndex]
        let source = texture.sourceRect.sdlRect()
        //let test = SDL_Rect(x: 0, y: 0, w: 1024, h: 1024)
        do {
            try renderer.copy(sdlTexture.texture, source: source, destination: dest)
            //try renderer.copy(sdlTexture.texture, source: test, destination: test)
        } catch {
            print("Couldn't draw image")
        }

    }
}

public class ImageManager {
    let atlas:ImageAtlas
    let drive:VirtualDrive
    public init(atlas: ImageAtlas, drive: VirtualDrive) {
        self.atlas = atlas
        self.drive = drive
    }
    var _imageCache:[String:Image] = [:]
    
    func sprite(named:String) throws -> Image? {
        guard let url = drive.urlForFileName(named) else { return nil }
        return try sprite(url)
    }
    
    func sprite(_ url:URL) throws -> Image? {
        let path = url.absoluteString
        if let image = _imageCache[path] {
            return image
        }
        do {
            guard var file = try drive.readFile(url) else { return nil }
        
            let preFormatSurface = try file.withUnsafeMutableBytes { (ptr:UnsafeMutableRawBufferPointer) in
                return try SDLSurface.init(ptr: ptr)
            }
            let surface = try preFormatSurface.convertSurface(format: SDL_PIXELFORMAT_ARGB8888)
            let width = surface.width
            let numPixels = surface.width * surface.height * 4
            let pitch = surface.pitch//surface.pitch == width * bytesPerPixel //TODO: yea resolve this
            //let bytesPerPixel = surface.pitch
            let image = try surface.withUnsafeMutableBytes { (ptr:UnsafeMutableRawPointer) -> Image in
                let bufferPtr = UnsafeRawBufferPointer(start: ptr, count: numPixels)
                let idk:SubTexture = try atlas.saveIntoAtlas(bufferPtr, bytesPerPixel: 0, width: width, pitch: pitch)
                return Image(texture: idk, atlas: atlas)
            }
            _imageCache[path] = image
            return image
        } catch {
            print("Couldn't load sprite: \(error.localizedDescription)")
        }
        return nil
    }
}


public class SpriteBatch {
    
    func drawImage(_ image:Image) {
        
    }
    
    func drawText(_ text:String, _ renderer:SDLRenderer) {
        
    }
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
    
    init(_ renderer:SDLRenderer) {
        self.renderer = renderer
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
    
    private func addPage() throws -> Int {
        let newTexture = try SDLTexture(renderer: renderer, format: .argb8888, access: .static, width: Int(textureSize.width), height: Int(textureSize.height))
        let allocator = AtlasAllocator(size: textureSize)
        listPages.append(TexturePage(texture: newTexture, allocator: allocator))
        return listPages.count - 1
    }
    
    func saveIntoAtlas(_ data:Data, bytesPerPixel:UInt8, width:Int, pitch:Int) throws -> SubTexture {
        //var result:SubTexture? = nil
        return try data.withUnsafeBytes { (ptr:UnsafeRawBufferPointer) in
            return try saveIntoAtlas(ptr, bytesPerPixel: bytesPerPixel, width: width, pitch: pitch)
        }
        //return result!
    }
    
    func saveIntoAtlas(_ ptr:UnsafeRawBufferPointer, bytesPerPixel:UInt8, width:Int, pitch:Int) throws -> SubTexture {
        let len = ptr.count
        let height = len / pitch
        let size = Size<Int32>(Int32(width), Int32(height))
        let space = UInt32(size.area())
        var pageIdx = nextPageThatFits(0, space)
        while (pageIdx != -1) {
            guard let alloc = try saveIntoPage(&listPages[pageIdx], ptr, pitch, size) else {
                pageIdx = nextPageThatFits(pageIdx + 1, space)
                continue
            }
            return SubTexture(allocationId: alloc.id, texturePageIndex: pageIdx, sourceRect: alloc.rectangle)
        }
        let createdIndex = try addPage()
        guard let alloc = try saveIntoPage(&listPages[createdIndex], ptr, pitch, size) else {
            throw SDLError(errorMessage: "Cant save texture", debugInformation: nil)
        }
        
        return SubTexture(allocationId: alloc.id, texturePageIndex: createdIndex, sourceRect: alloc.rectangle)
    }
    
    private func saveIntoPage(_ page: inout TexturePage, _ ptrData:UnsafeRawBufferPointer, _ pitch:Int, _ size:Size<Int32>) throws -> Allocation? {
        guard let alloc = page.allocator.allocate(size_: size) else { return nil }
        do {
            try page.texture.update(for: alloc.rectangle.sdlRect(), pixels: ptrData, pitch: pitch)
        } catch {
            page.allocator.deallocate(alloc.id)
            throw error
        }
        
        return alloc
    }
    
    func returnTexture(_ subTexture:SubTexture) {
        
    }
    /*
    func loadIntoTexture(_ data:Data) -> SDLTexture {
        return try! SDLTexture(renderer: renderer, format: .argb8888, access: .static, width: 1, height: 1)
    }*/
}

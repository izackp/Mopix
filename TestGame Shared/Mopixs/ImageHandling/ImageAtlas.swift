//
//  SpriteAtlas.swift
//  TestGame
//
//  Created by Isaac Paul on 4/20/22.
//

import Foundation
import SDL2
import SDL2_ttf

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

public class ImageManager {
    let atlas:ImageAtlas
    let drive:VirtualDrive //TODO: doesn't _need_ to be in here.. maybe we can make a subclass
    public init(atlas: ImageAtlas, drive: VirtualDrive) {
        self.atlas = atlas
        self.drive = drive
    }
    var _imageCache:[String:Image] = [:]
    var _fontList:[String:URL] = [:]
    var _systemFonts:[String] = []
    var _fontCache:[FontDesc:Font] = [:]
    
    public func loadSystemFonts() {
        let names:[String] = (fontFamilyNames() as? [String]) ?? []
        _systemFonts = names
    }
    
    public func loadFont(_ url:VDUrl) {
        do {
            //TODO: This is pretty extra.. I would perfer to use something lighter than SDLFont
            //I would also prefer to have more infomation (available styles, sizes, etc)
            guard let fileUrl = try? drive.resolveToDirectUrl(url) else { return }
            let font = try SDLFont(file: fileUrl.path, ptSize: 14)
            guard let name = font.faceFamilyName() else {
                print("Couldn't load font. No name.")
                return
            }
            _fontList[name] = fileUrl
        } catch {
            print("Couldn't load font: \(error.localizedDescription)")
        }
    }
    
    public func fetchFont(desc:FontDesc) throws -> Font? {
        var name = desc.family
        if name == "default" {
            name = "Roboto"
            //return try fromCGFont("Helvetica", desc: desc)
        }
        
        if let url = _fontList[name] {
            let font = try SDLFont(file: url.path, ptSize: Int(desc.size))
            return Font(atlas: atlas, font: font)
        }
        
        return try fromCGFont(name, desc: desc)
    }
    
    func fromCGFont(_ name:String, desc:FontDesc) throws -> Font? {
        let cgFont = CGFont(name as CFString)
        guard let data = fontDataForCGFont(cgFont) else { return nil }
        let font = try SDLFont(data: data, ptSize: Int(desc.size))
        return Font(atlas: atlas, font: font)
    }
    
    public func sprite(named:String) throws -> Image? {
        guard let url = drive.urlForFileName(named) else { return nil }
        return try sprite(url)
    }
    
    public func sprite(_ url:URL) throws -> Image? {
        let path = url.absoluteString
        if let image = _imageCache[path] {
            return image
        }
        do {
            guard var file = try drive.readFile(url) else { return nil }
        
            let preFormatSurface = try file.withUnsafeMutableBytes { (ptr:UnsafeMutableRawBufferPointer) in
                return try SDLSurface.init(bmpDataPtr: ptr)
            }
            let subTexture = try atlas.save(preFormatSurface)
            let image = Image(texture: subTexture, atlas: atlas)
            _imageCache[path] = image
            return image
        } catch {
            print("Couldn't load sprite: \(error.localizedDescription)")
        }
        return nil
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
    
    var _blankImageCache:[SubTexture] = [] //index matches page
    
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
    
    private func addPage() throws -> Int {
        
        //TODO: Why does this have to be streaming to call lockAndEdit, but it can be static for updateTexture?
        let newTexture = try SDLTexture(renderer: renderer, format: .argb8888, access: .streaming, width: Int(textureSize.width), height: Int(textureSize.height))
        try newTexture.setBlendMode([SDLBlendMode.alpha])
        
        //TODO: Not really needed; only used to visualize uninitied memory
        try newTexture.lockAndEditSurface(rect: nil) { (surface:SDLSurface) in
            let color = SDLColor.pink
            try surface.fill(color: color)
        }
        
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
    
    func returnTexture(_ subTexture:SubTexture) {
        //TODO: There is no mechanism to remove a texture page once created..
        let page = listPages[subTexture.texturePageIndex]
        page.allocator.deallocate(subTexture.allocationId)
    }
    
    /*
    func loadIntoTexture(_ data:Data) -> SDLTexture {
        return try! SDLTexture(renderer: renderer, format: .argb8888, access: .static, width: 1, height: 1)
    }*/
}

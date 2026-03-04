//
//  ImageManager.swift
//  TestGame
//
//  Created by Isaac Paul on 7/2/22.
//

import Foundation
import SDL2Swift
import SystemFonts

public struct ImageResult {
    let image:AtlasImage
    let data:PixelData
}

public class ImageManager {
    let atlas:ImageAtlas
    public init(atlas: ImageAtlas, dataSources:[IDataSource]) {
        self.atlas = atlas
        self._dataSource = CombinedDataSource(dataSources)
    }
    
    
    var _dataSource:CombinedDataSource
    var _imageCache:[String:AtlasImage] = [:]
    var _fontList:[String:URL] = [:]
    var _fontCache:[FontDesc:Font] = [:] //TODO: Fonts should unload when no longer used
    
    var _systemFonts:[String] = [] //TODO: Is it needed?
    
    public func loadSystemFonts() {
        #if os(macOS)
        let names:[String] = (fontFamilyNames() as? [String]) ?? []
        _systemFonts = names
        #endif
    }
    
    public func addFont(_ url:URL) {
        do {
            //TODO: This is pretty extra.. I would perfer to use something lighter than SDLFont
            //I would also prefer to have more infomation (available styles, sizes, etc)
            let file = try _dataSource.fetch(url)
            let font = try SDLFont(data: file, ptSize: 14)
            guard let name = font.faceFamilyName() else {
                print("Couldn't load font. No name.")
                return
            }
            _fontList[name] = url
        } catch {
            print("Couldn't load font: \(error.localizedDescription)")
        }
    }
    
    public func fetchFont(desc:FontDesc) throws -> Font? {
        if let cached = _fontCache[desc] {
            return cached
        }
        let name = desc.family
        
        if let url = _fontList[name] {
            let file = try _dataSource.fetch(url)
            let font = try SDLFont(data: file, ptSize: Int(desc.size))
            let result = Font(atlas: atlas, font: font)
            _fontCache[desc] = result
            return result
        }
        
        #if os(macOS)
        let result = try fromCGFont(name, desc: desc)
        _fontCache[desc] = result
        return result
        #else
        return nil
        #endif
    }
    
    #if os(macOS)
    //NOTE: https://gitlab.freedesktop.org/freetype/freetype/-/issues/1281
    // Apple is now using a propietary hvgl table for some of there fonts and it has not been implemented in freetype
    func fromCGFont(_ name:String, desc:FontDesc) throws -> Font? {
        let cgFont = CGFont(name as CFString)
        guard let data = fontDataForCGFont(cgFont) else { return nil }
        let font = try SDLFont(data: data, ptSize: Int(desc.size))
        return Font(atlas: atlas, font: font)
    }
    #endif
    
    public func image(_ url:URL) -> AtlasImage? {
        /*
        let path = directUrl.absoluteString
        if let image = _imageCache[path] {
            return image
        }*/
        do {
            var file = try _dataSource.fetch(url)
            let preFormatSurface = try file.withUnsafeMutableBytes { (ptr:UnsafeMutableRawBufferPointer) in
                return try Surface(bmpDataPtr: ptr)
            }
            let subTexture = try atlas.save(preFormatSurface)
            let image = AtlasImage(texture: subTexture, atlas: atlas)
            //_imageCache[path] = image
            return image
        } catch {
            print("Couldn't load sprite: \(error.localizedDescription)")
        }
        return nil
    }
    
    public func image(named:String) -> AtlasImage? {
        guard let url = _dataSource.searchItemByName(named) else { return nil }
        return image(url)
    }
    
    public func imageAndPixels(_ url:URL) -> ImageResult? {
        let path = url.absoluteString //TODO: probably doesn't include host
        let existingImage:AtlasImage? = nil//_imageCache[path] //TODO: Weird because we don't cache the pixels..
        do {
            var file = try _dataSource.fetch(url)
        
            let preFormatSurface = try file.withUnsafeMutableBytes { (ptr:UnsafeMutableRawBufferPointer) in
                return try Surface.init(bmpDataPtr: ptr)
            }
            let image:AtlasImage
            if let toUse = existingImage {
                image = toUse
            } else {
                let subTexture = try atlas.save(preFormatSurface)
                image = AtlasImage(texture: subTexture, atlas: atlas)
            }
            //_imageCache[path] = image
            let pixelData = PixelData(preFormatSurface)
            return ImageResult(image: image, data: pixelData) //Not sure if the best idea to use preformat
        } catch {
            print("Couldn't load sprite: \(error.localizedDescription)")
        }
        return nil
    }
    
    public func image(_ editableImage:PixelData) -> AtlasImage? {
        do {
            let subTexture = try atlas.save(editableImage._surface)
            let image = AtlasImage(texture: subTexture, atlas: atlas)
            //_imageCache[path] = image //Could cache based on obj id..
            return image
        } catch {
            print("Couldn't load image into atlas: \(error.localizedDescription)")
        }
        return nil
    }
    
    public func updateImage(_ image:AtlasImage, _ editableImage:PixelData) throws {
        let size = editableImage.size().to(Int32.self)
        let subTexture = image.subTextureIndex
        let subTextureSize = subTexture.sourceRect.size
        if (size != subTextureSize) { throw GenericError("Editable size does not match image size. You should make a new image.")}
        let pageIndex = subTexture.texturePageIndex
        let texture = atlas.listPages[pageIndex].texture
        let frame = subTexture.sourceRect
        
        try editableImage._surface.withPixelData { pixelData in
            try texture.update(for: frame.sdlRect(), pixels: pixelData.ptr, pitch: pixelData.pitch)
        }
    }
}

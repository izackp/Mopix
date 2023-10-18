//
//  SimpleImageManager.swift
//  TestGame
//
//  Created by Isaac Paul on 7/2/22.
//

import Foundation
import SDL2
import SDL2Swift
import SDL2_TTF
import SDL2_TTFSwift

public struct ImageResult {
    let image:AtlasImage
    let data:PixelData
}

public class SimpleImageManager : ImageManager {
    let drive:VirtualDrive
    public init(atlas: ImageAtlas, drive: VirtualDrive) {
        self.drive = drive
        super.init(atlas: atlas)
    }
    
    var _vdFontList:[String:VDUrl] = [:]
    
    public func loadVDFont(_ url:VDUrl) {
        do {
            //TODO: This is pretty extra.. I would perfer to use something lighter than SDLFont
            //I would also prefer to have more infomation (available styles, sizes, etc)
            //guard let fileUrl = try? drive.resolveToDirectUrl(url) else { return }
            guard let file = try drive.readFile(url) else { return }
            let font = try SDLFont(data: file, ptSize: 14)
            guard let name = font.faceFamilyName() else {
                print("Couldn't load font. No name.")
                return
            }
            _vdFontList[name] = url
        } catch {
            print("Couldn't load font: \(error.localizedDescription)")
        }
    }
    
    //TODO: Proper inheritence Should extend functionality
    override public func fetchFont(desc: FontDesc) throws -> Font? {
        if let cached = _fontCache[desc] {
            return cached
        }
        let name = desc.family
        
        if let url = _vdFontList[name] {
            guard let file = try drive.readFile(url) else { return nil }
            let font = try SDLFont(data: file, ptSize: Int(desc.size))
            let result = Font(atlas: atlas, font: font)
            _fontCache[desc] = result
            return result
        }
        
        return try super.fetchFont(desc: desc)
    }
    
    public func image(named:String) -> AtlasImage? {
        guard let url = drive.searchByName(named)?.url else { return nil }
        return image(url)
    }
    
    public func image(_ url:VDUrl) -> AtlasImage? {
        let path = url.absoluteString //TODO: probably doesn't include host
        if let image = _imageCache[path] {
            return image
        }
        do {
            guard var file = try drive.readFile(url) else { return nil }
        
            let preFormatSurface = try file.withUnsafeMutableBytes { (ptr:UnsafeMutableRawBufferPointer) in
                return try Surface.init(bmpDataPtr: ptr)
            }
            let subTexture = try atlas.save(preFormatSurface)
            let image = AtlasImage(texture: subTexture, atlas: atlas)
            _imageCache[path] = image
            return image
        } catch {
            print("Couldn't load sprite: \(error.localizedDescription)")
        }
        return nil
    }
    
    public func imageAndPixels(_ url:VDUrl) -> ImageResult? {
        let path = url.absoluteString //TODO: probably doesn't include host
        let existingImage = _imageCache[path]
        do {
            guard var file = try drive.readFile(url) else { return nil }
        
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
            _imageCache[path] = image
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

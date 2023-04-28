//
//  ImageManager.swift
//  TestGame
//
//  Created by Isaac Paul on 7/2/22.
//

import Foundation
import SDL2Swift
import SystemFonts

public class ImageManager {
    let atlas:ImageAtlas
    public init(atlas: ImageAtlas) {
        self.atlas = atlas
    }
    
    var _imageCache:[String:Image] = [:]
    var _fontList:[String:URL] = [:]
    var _fontCache:[FontDesc:Font] = [:] //TODO: Fonts should unload when no longer used
    
    var _systemFonts:[String] = [] //TODO: Is it needed?
    
    public func loadSystemFonts() {
        let names:[String] = (fontFamilyNames() as? [String]) ?? []
        _systemFonts = names
    }
    
    public func loadFont(_ url:URL) {
        do {
            //TODO: This is pretty extra.. I would perfer to use something lighter than SDLFont
            //I would also prefer to have more infomation (available styles, sizes, etc)
            let font = try SDLFont(file: url.path, ptSize: 14)
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
            let font = try SDLFont(file: url.path, ptSize: Int(desc.size))
            let result = Font(atlas: atlas, font: font)
            _fontCache[desc] = result
            return result
        }
        
        let result = try fromCGFont(name, desc: desc)
        _fontCache[desc] = result
        return result
    }
    
    func fromCGFont(_ name:String, desc:FontDesc) throws -> Font? {
        let cgFont = CGFont(name as CFString)
        guard let data = fontDataForCGFont(cgFont) else { return nil }
        let font = try SDLFont(data: data, ptSize: Int(desc.size))
        return Font(atlas: atlas, font: font)
    }
    
    public func image(directUrl:URL) -> Image? {
        let path = directUrl.absoluteString
        if let image = _imageCache[path] {
            return image
        }
        do {
            var file = try Data(contentsOf: directUrl)
            let preFormatSurface = try file.withUnsafeMutableBytes { (ptr:UnsafeMutableRawBufferPointer) in
                return try Surface(bmpDataPtr: ptr)
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

//
//  SimpleImageManager.swift
//  TestGame
//
//  Created by Isaac Paul on 7/2/22.
//

import Foundation

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
    
    //TODO: API Should extend functionality
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
    
    public func image(named:String) -> Image? {
        guard let url = drive.searchByName(named)?.url else { return nil }
        return image(url)
    }
    
    public func image(_ url:VDUrl) -> Image? {
        let path = url.absoluteString //TODO: probably doesn't include host
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

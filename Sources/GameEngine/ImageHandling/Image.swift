//
//  Image.swift
//  TestGame
//
//  Created by Isaac Paul on 7/2/22.
//

import Foundation
import SDL2
import SDL2Swift

extension SDLColor {
    func alpha() -> UInt8 {
        let onlyAlpha = (0xFF000000 & rawValue) >> (4*6)
        return UInt8(onlyAlpha)
    }
}

struct SDLTextureSlice {
    let texture:Texture
    let rect:SDL_Rect
}

//3 types of images
//Image { id, url, size }
//FlyWeight { id }

//raw pixel data
//Editable { id, pixeldata, size }

//meta data info

//This additional layer exists so we can 'drop' textures. To do that we need a reference to the atlas
//subTextureIndex
public class AtlasImage {
    public init(texture: SubTextureIndex, atlas: ImageAtlas) {
        self.subTextureIndex = texture
        self.atlas = atlas
    }
    
    let subTextureIndex:SubTextureIndex
    private let atlas:ImageAtlas
    
    var size:Size<Int32> {
        get { return subTextureIndex.sourceRect.size }
    }
    
    var sourceRect:Rect<Int32> {
        get { return subTextureIndex.sourceRect.to(Int32.self) }
    }
    
    deinit {
        atlas.returnSubtexture(subTextureIndex)
    }
    
    func getTextureSlice() -> SDLTextureSlice {
        let texturePage = atlas.listPages[subTextureIndex.texturePageIndex]
        let sdlTexture = texturePage.texture
        
        let rect = subTextureIndex.sourceRect.sdlRect()
        return SDLTextureSlice(texture: sdlTexture, rect: rect)
    }
}

extension Renderer {
    func draw(_ image:AtlasImage, _ x:Int32, _ y:Int32, _ color:SDLColor = SDLColor.white, alpha:Float = 1) {
        let source = image.getTextureSlice()
        draw(source, SDL_Rect(x: x, y: y, w: source.rect.w, h: source.rect.h), color, alpha)
    }
    
    func draw(_ image:AtlasImage, _ dest:SDL_Rect, _ color:SDLColor = SDLColor.white, alpha:Float = 1) {
        let source = image.getTextureSlice()
        draw(source, dest, color, alpha)
    }
    
    func draw(_ imageSrc:SDLTextureSlice, _ dest:SDL_Rect, _ color:SDLColor = SDLColor.white, _ alpha:Float = 1) {
        let texture = imageSrc.texture
        let src = imageSrc.rect
        do {
            try texture.setColorModulation(color)
            try texture.setAlphaModulation(UInt8(255*alpha))
            try copy(texture, source: src, destination: dest)
            //try renderer.copy(sdlTexture.texture, source: test, destination: test)
        } catch {
            print("Couldn't draw image")
        }
    }
    
    func draw(_ imageSrc:SDLTextureSlice, _ dest:SDL_Rect, _ color:SDLColor = SDLColor.white, _ alpha:Float = 1, _ angle:Double = 0, _ center:SDL_Point = SDL_Point(x: 0, y: 0), _ flip:BitMaskOptionSet<RendererFlip> = [.none]) {
        let texture = imageSrc.texture
        let src = imageSrc.rect
        do {
            try texture.setColorModulation(color)
            try texture.setAlphaModulation(UInt8(255*alpha))
            try copyEx(texture, src, dest, angle, center, flip)
        } catch {
            print("Couldn't draw image")
        }
    }
}

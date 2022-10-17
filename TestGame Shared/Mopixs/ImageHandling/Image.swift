//
//  Image.swift
//  TestGame
//
//  Created by Isaac Paul on 7/2/22.
//

import Foundation
import SDL2

extension SDLColor {
    func alpha() -> UInt8 {
        let onlyAlpha = (0xFF000000 & rawValue) >> (4*6)
        return UInt8(onlyAlpha)
    }
}

struct ImageSource {
    let texture:SDLTexture
    let rect:SDL_Rect
}

public class Image {
    public init(texture: SubTexture, atlas: ImageAtlas) {
        self.texture = texture
        self.atlas = atlas
    }
    
    let texture:SubTexture
    let atlas:ImageAtlas
    
    
    deinit {
        atlas.returnSubtexture(texture)
    }
    
    func getSource() -> ImageSource {
        let subTexture = texture
        let texturePage = atlas.listPages[subTexture.texturePageIndex]
        let sdlTexture = texturePage.texture
        
        let rect = subTexture.sourceRect.sdlRect()
        return ImageSource(texture: sdlTexture, rect: rect)
    }
    
    //TODO: Not sure which is the better api.. one allows image?.draw(renderer, 0, 0) the other: renderer.draw(image, 0, 0)
    func draw(_ renderer:SDLRenderer, _ x:Int32, _ y:Int32, _ color:SDLColor = SDLColor.white) {
        let source = getSource()
        renderer.draw(source, SDL_Rect(x: x, y: y, w: source.rect.w, h: source.rect.h), color)
    }
    
    func draw(_ renderer:SDLRenderer, _ dest:SDL_Rect, _ color:SDLColor = SDLColor.white) {
        let source = getSource()
        renderer.draw(source, dest, color)
    }
}

extension SDLRenderer {
    func draw(_ image:Image, _ x:Int32, _ y:Int32, _ color:SDLColor = SDLColor.white, alpha:Float = 1) {
        let source = image.getSource()
        draw(source, SDL_Rect(x: x, y: y, w: source.rect.w, h: source.rect.h), color, alpha)
    }
    
    func draw(_ image:Image, _ dest:SDL_Rect, _ color:SDLColor = SDLColor.white, alpha:Float = 1) {
        let source = image.getSource()
        draw(source, dest, color, alpha)
    }
    
    func draw(_ imageSrc:ImageSource, _ dest:SDL_Rect, _ color:SDLColor = SDLColor.white, _ alpha:Float = 1) {
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
}

//
//  UIRenderContext.swift
//  TestGame
//
//  Created by Isaac Paul on 6/22/22.
//

import Foundation
import SDL2

public class UIRenderContext {
    public init(renderer: SDLRenderer, imageManger:ImageManager) {
        self.renderer = renderer
        self.imageManager = imageManger
    }
    
    let renderer:SDLRenderer
    let imageManager:ImageManager
    let lastTexture:Int = 0
    
    func drawSquare(_ frame:Frame<Int16>, _ color:SDLColor) throws {
        //let sdlRect = frame.sdlRect()
        //try renderer.setClipRect(sdlRect)
        //try blankTexture.setColorModulation(color)
        //TODO: we can probably just return sdl texture and source
        let blankSubTexture = try imageManager.atlas.blankSubtexture(lastTexture)
        let sdlTexture = imageManager.atlas.listPages[blankSubTexture.texturePageIndex]
        let source = blankSubTexture.sourceRect.sdlRect()
        let texture = sdlTexture.texture
        try texture.setColorModulation(color)
        try renderer.copy(sdlTexture.texture, source: source, destination: frame.sdlRect())
    }
    
    func drawImage(_ frame:Frame<Int16>, _ color:SDLColor, image:Image) throws {
        //try blankTexture.setColorModulation(color)
        image.draw(renderer, frame.sdlRect(), color)
    }
    
    func drawText(_ frame:Frame<Int16>, _ color:SDLColor, _ text:String, _ font:Font) throws {
        font.draw(renderer, text, x: Int(frame.x), y: Int(frame.y), color: color)
    }
    
    func drawAtlas(_ x:Int, _ y:Int) throws {
        let texture = imageManager.atlas.listPages[0].texture
        try texture.setColorModulation(255, 255, 255)
        try renderer.copy(texture, source: SDL_Rect(x: 0, y: 0, w: 1024, h: 1024), destination: SDL_Rect(x: Int32(x), y: Int32(y), w: 1024, h: 1024))
    }
}

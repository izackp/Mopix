//
//  UIRenderContext.swift
//  TestGame
//
//  Created by Isaac Paul on 6/22/22.
//

import Foundation
import SDL2

public class UIRenderContext {
    public init(renderer: SDLRenderer, blankTexture: SDLTexture, imageManger:ImageManager) {
        self.renderer = renderer
        self.blankTexture = blankTexture
        self.imageManager = imageManger
    }
    
    let renderer:SDLRenderer
    let blankTexture:SDLTexture
    let imageManager:ImageManager
    
    func drawSquare(_ frame:Frame<Int16>, _ color:SDLColor) throws {
        try blankTexture.setColorModulation(color)
        try renderer.copy(blankTexture, destination: frame.sdlRect())
    }
    
    func drawImage(_ frame:Frame<Int16>, _ color:SDLColor) throws {
        try blankTexture.setColorModulation(color)
        try renderer.copy(blankTexture, destination: frame.sdlRect())
    }
    
    func drawText(_ frame:Frame<Int16>, _ color:SDLColor, _ text:String, _ font:FontDesc) throws {
        
    }
}
/*
 How do we track font glyphs?
 Ok so we already fetch and use textures. I think we should follow suit with fonts.
 */

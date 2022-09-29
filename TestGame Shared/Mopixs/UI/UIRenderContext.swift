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
    var lastOffset:Point<Int16> = .zero //TODO: This feels hacky
    var currentClipRect:Frame<DValue>? = nil
    
    private func resolveSmartColor(_ color:SmartColor) -> SDLColor {
        if let name = color.name {
            switch name {
                case "green":
                    return SDLColor(rawValue: SmartColor.green.rawValue!)
                case "red":
                    return SDLColor(rawValue: SmartColor.red.rawValue!)
                default:
                    return SDLColor(rawValue: SmartColor.black.rawValue!)
            }
        }
        return SDLColor(rawValue: color.rawValue!)
    }
    
    func pushOffset(_ point:Point<Int16>) {
        lastOffset = Point(lastOffset.x + point.x, lastOffset.y + point.y)
    }
    
    func popOffset(_ point:Point<Int16>) {
        lastOffset = Point(lastOffset.x - point.x, lastOffset.y - point.y)
    }
    
    func setClipRectRelative(_ frame:Frame<DValue>) throws {
        let newFrame = frame.offset(lastOffset)
        try renderer.setClipRect(newFrame.sdlRect())
    }
    
    func setClipRect(_ frame:Frame<DValue>?) throws {
        try renderer.setClipRect(frame?.sdlRect())
    }
    
    func drawSquare(_ frame:Frame<Int16>, _ color:SmartColor) throws {
        try drawSquare(frame, resolveSmartColor(color))
    }
    
    func drawImage(_ frame:Frame<Int16>, _ color:SmartColor, image:Image) throws {
        try drawImage(frame, resolveSmartColor(color), image: image)
    }
    
    func drawText(_ pos:Point<Int16>, _ color:SmartColor, _ text:Substring, _ font:Font, spacing:Int = 0) throws {
        let newPos = pos + lastOffset
        font.draw(renderer, text, x: Int(newPos.x), y: Int(newPos.y), color: resolveSmartColor(color), spacing: spacing)
    }
    
    func drawSquare(_ frame:Frame<Int16>, _ color:SDLColor) throws {
        let newFrame = frame.offset(lastOffset)
        //TODO: we can probably just return sdl texture and source
        let blankSubTexture = try imageManager.atlas.blankSubtexture(lastTexture)
        let sdlTexture = imageManager.atlas.listPages[blankSubTexture.texturePageIndex]
        let source = blankSubTexture.sourceRect.sdlRect()
        let texture = sdlTexture.texture
        try texture.setColorModulation(color)
        try renderer.copy(sdlTexture.texture, source: source, destination: newFrame.sdlRect())
    }
    
    func drawImage(_ frame:Frame<Int16>, _ color:SDLColor, image:Image) throws {
        let newFrame = frame.offset(lastOffset)
        image.draw(renderer, newFrame.sdlRect(), color)
    }
    
    func drawText(_ frame:Frame<Int16>, _ color:SDLColor, _ text:Substring, _ font:Font) throws {
        let newFrame = frame.offset(lastOffset)
        font.draw(renderer, text, x: Int(newFrame.x), y: Int(newFrame.y), color: color)
    }
    
    func drawAtlas(_ x:Int, _ y:Int, index:Int = 0) throws {
        let listPages = imageManager.atlas.listPages
        if (index >= listPages.count) { return }
        let texture = listPages[index].texture
        try texture.setColorModulation(255, 255, 255)
        try renderer.copy(texture, source: SDL_Rect(x: 0, y: 0, w: 1024, h: 1024), destination: SDL_Rect(x: Int32(x), y: Int32(y), w: 1024, h: 1024))
    }
}

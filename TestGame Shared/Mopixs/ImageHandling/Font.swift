//
//  Font.swift
//  TestGame
//
//  Created by Isaac Paul on 7/2/22.
//

import Foundation
import SDL2
import SDL2_ttf

//A few ways we can do this:
//Lazy: Add to atlas as we go. However, the glyph could end up in another texture page
//Upfront: Load it all at once
//Temp: Load it once lazily, in order to draw string to texture.
//Immediate: Don't add to atlas and draw directly..
//I think we can accomplish 'Temp' via only lazy. We just need to drop the font when we're done with it.
public class Font {
    //let _fileUrl:URL
    var _glyphs:[Character:SubTexture] = [:] //TODO: Array or dictionary?
    let _atlas:ImageAtlas
    let _font:SDLFont
    
    public init(atlas: ImageAtlas, font:SDLFont) {
        _atlas = atlas
        _font = font
    }
    
    func widthOfText(_ text:String, maxWidthPxs:Int) throws -> MeasureResult {
        let metrics = try _font.measure(text, maxWidthPxs: maxWidthPxs)
        return metrics
    }
    
    func glyph(_ c:Character) throws -> SubTexture {
        if let texture = _glyphs[c] {
            return texture
        }
        let surface = try _font.renderGlyphBlended(c, foregroundColor: SDL_Color(r: 255, g: 255, b: 255, a: 255))
        let texture = try _atlas.save(surface)
        //assert(height == texture.sourceRect.height)
        _glyphs[c] = texture
        return texture
    }
    
    func draw(_ renderer:SDLRenderer, _ c:Character, x: Int, y:Int, color:SDLColor) {
        
        do {
            /*
            let test = try glyphTest(c)
            let source = SDL_Rect(x: 0, y: 0, w: Int32(test.width), h: Int32(test.height))
            var dest = source
            dest.x = Int32(x)
            dest.y = Int32(y)
            try renderer.copy(test, source: source, destination: dest)
            return*/
            
            let subTexture = try glyph(c)
            let sdlTexture = _atlas.listPages[subTexture.texturePageIndex]
            let source = subTexture.sourceRect.sdlRect()
            var dest = source
            dest.x = Int32(x)
            dest.y = Int32(y)
            try sdlTexture.texture.setColorModulation(color)
            try renderer.copy(sdlTexture.texture, source: source, destination: dest)
        } catch {
            print("Error couldn't draw image: \(error.localizedDescription)")
        }
    }
    
    func draw(_ renderer:SDLRenderer, _ text:String, x: Int, y:Int, color:SDLColor) {
        
        var nextX = x
        for c in text {
            do {
                let metrics = try _font.glyphMetrics(c: c)
                draw(renderer, c, x: nextX, y: y, color: color)
                nextX += metrics.advance
                //nextX += metrics.frame.right
            } catch {
                print("Error couldn't draw character '\(c)': \(error.localizedDescription)")
            }
        }
    }
}

//
//  Font.swift
//  TestGame
//
//  Created by Isaac Paul on 7/2/22.
//

import Foundation
import SDL2
import SDL2Swift
import SDL2_TTFSwift
import ICU

typealias SDLFont = SDL2_TTFSwift.Font

public extension Array {
    init(count: Int, elementCreator: @autoclosure () -> Element) {
        self = (0 ..< count).map { _ in elementCreator() }
    }
    init(count: Int, element: Element) {
        self = (0 ..< count).map { _ in element }
    }
}


extension Substring {
    func forEachCharacterWithIndex(iterator: (String.Index, Character) -> Void) {
        var currIndex = self.startIndex
        for char in self {
            iterator(currIndex, char)
            currIndex = self.index(after: currIndex)
        }
    }
}

extension String {
    
    func forEachCharacterWithIndex(iterator: (String.Index, Character) -> Void) {
        var currIndex = self.startIndex
        for char in self {
            iterator(currIndex, char)
            currIndex = self.index(after: currIndex)
        }
    }
    
    //words start at white space
    func iterateWords() -> AnyIterator<Substring> {
        var it = self.makeIterator()
        var i = 0
        var count:Int = 0
        let wordIt = AnyIterator {
            var reachedNonEmptySpace = false
            while let c = it.next()  {
                count += 1
                if (reachedNonEmptySpace) {
                    if (c.isWhitespace) {
                        //COMPLETE
                        let start = i
                        i = start+count - 1
                        count = 1
                        return self[start...i]
                    }
                } else {
                    if (!c.isWhitespace) {
                        reachedNonEmptySpace = true
                    }
                }
            }
            if (count > 0 && reachedNonEmptySpace) {
                let start = i
                i = start+count
                count = 0
                return self[start...i]
            }
            return nil
        }
        return wordIt
    }
}

//A few ways we can do this:
//Lazy: Add to atlas as we go. However, the glyph could end up in another texture page
//Upfront: Load it all at once
//Temp: Load it once lazily, in order to draw string to texture.
//Immediate: Don't add to atlas and draw directly..
//I think we can accomplish 'Temp' via only lazy. We just need to drop the font when we're done with it.
public class Font {
    //let _fileUrl:URL
    var _glyphs:[Character:AtlasImage] = [:] //TODO: Array or dictionary?
    let _atlas:ImageAtlas
    let _font:SDLFont
    
    public init(atlas: ImageAtlas, font:SDL2_TTFSwift.Font) {
        _atlas = atlas
        _font = font
    }
    
    deinit {
        /*
        for subTexture in _glyphs.values {
            _atlas.returnSubtexture(subTexture)
        }*/
    }
    
    func widthOfText(_ text:String, maxWidthPxs:Int) throws -> MeasureResult {
        let metrics = try _font.measure(text, inWidth: maxWidthPxs)
        return metrics
    }
    
    func widthOfText(_ text:Substring, maxWidthPxs:Int) throws -> MeasureResult {
        var width:Int = 0
        var count:Int = 0
        for c in text {
            do {
                let metrics = try _font.glyphMetrics(c: c)
                if (maxWidthPxs != 0 && width + metrics.advance > maxWidthPxs) { break }
                width += metrics.advance
                count += 1
            } catch {
                print("Error couldn't measure character '\(c)': \(error.localizedDescription)")
            }
        }
        return MeasureResult(extent: width, count: count)
    }
    
    func glyph(_ c:Character) throws -> AtlasImage {
        if let texture = _glyphs[c] {
            return texture
        }
        let surface = try _font.renderGlyphBlended(c, foregroundColor: SDL_Color(r: 255, g: 255, b: 255, a: 255))
        let texture = try _atlas.save(surface)
        let image = AtlasImage(texture: texture, atlas: _atlas)
        //assert(height == texture.sourceRect.height)
        _glyphs[c] = image
        return image
    }
}

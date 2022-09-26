//
//  Font.swift
//  TestGame
//
//  Created by Isaac Paul on 7/2/22.
//

import Foundation
import SDL2
import SDL2_ttf

extension String {
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

struct TextWord {
    let str:Substring
    let width:Int
}

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
    
    func splitIntoLines(_ text:String, maxWidthPxs:Int, characterSpacing:Int) throws -> [TextLine] {
        var lines:[TextLine] = []
        var width:Int = 0
        var count:Int = 0
        var start:Int = 0
        let height = _font.height()
        for (i, c) in text.enumerated() {
            do {
                let metrics = try _font.glyphMetrics(c: c)
                if (width + metrics.advance + characterSpacing > maxWidthPxs) {
                    let line = TextLine(str: text[start...i], width: width, height: height)
                    lines.append(line)
                    start = i
                    width = 0
                    count = 0
                }
                width += metrics.advance + characterSpacing
                count += 1
            } catch {
                print("Error couldn't measure character '\(c)': \(error.localizedDescription)")
            }
        }
        if (count > 0) {
            let line = TextLine(str: text[start...start + count], width: width, height: height)
            lines.append(line)
        }
        return lines
    }
    
    //Welcome to one of the ugliest functions in this code base
    //Builds a list of lines used to layout text
    //These lines will not include any initial whitespace unless:
    //  - The previous line was ended with a line break
    //  - It is the beginning of the line
    //Overall mimicing behavior of uilabel from iOS
    //Also does not include any whitespace at the end of the line
    //Lines are broken up by word to fit inside maxWidthPxs
    //They broken up even further by character if they still do not fit
    func splitIntoLinesWordWrapped(_ text:String, maxWidthPxs:Int, characterSpacing:Int) throws -> [TextLine] {
        var lines:[TextLine] = []
        var width:Int = 0
        var startIndex:String.Index = text.startIndex
        var lastWord:Substring? = nil
        var len = 0
        let height:Int = _font.height()
        for eachWord in text.iterateWords() {
            var wordWidth:Int = 0
            var lastItemWasNewline = false
            var lastItemWasSkipped = false
            var spacesInCur = 0
            var spaceWidth = 0
            for c in eachWord {
                len += 1
                if (c == "\n") {
                    if let lastWord2 = lastWord {
                        let line = TextLine(str: text[startIndex..<lastWord2.endIndex], width: width, height: height)
                        lines.append(line)
                        let dist = text.distance(from: startIndex, to: lastWord2.endIndex)
                        len -= dist
                        width = 0
                        startIndex = lastWord2.endIndex
                        lastWord = nil
                    } else {
                        let endIndex = text.index(startIndex, offsetBy: len)
                        let line = TextLine(str: text[startIndex..<endIndex], width: width, height: height)
                        lines.append(line)
                        startIndex = eachWord.endIndex
                        len = 0
                        width = 0
                    }
                    lastItemWasNewline = true
                    continue
                }
                if (!lastItemWasNewline && lastWord == nil && c.isWhitespace) {
                    lastItemWasSkipped = true
                    continue
                } else if (!lastItemWasNewline && c.isWhitespace) {
                    spacesInCur += 1
                }
                lastItemWasNewline = false
                if lastItemWasSkipped {
                    lastItemWasSkipped = false
                    startIndex = text.index(startIndex, offsetBy: len - 1)
                    len = 1
                }
                do {
                    let metrics = try _font.glyphMetrics(c: c)
                    let nextWidth = wordWidth + metrics.advance + characterSpacing
                    
                    let wordDoesntFit = width + nextWidth > maxWidthPxs
                    if (wordDoesntFit) {
                        if let lastWord2 = lastWord {
                            
                            let line = TextLine(str: text[startIndex..<lastWord2.endIndex], width: width, height: height)
                            lines.append(line)
                            let dist = text.distance(from: startIndex, to: lastWord2.endIndex) + 1
                            len -= dist
                            let index = text.index(lastWord2.endIndex, offsetBy: spacesInCur)
                            startIndex = index
                            width = 0
                            wordWidth = nextWidth - spaceWidth
                            lastWord = nil
                        } else {
                            
                            let endIndex = text.index(startIndex, offsetBy: len-1)
                            let line = TextLine(str: text[startIndex..<endIndex], width: wordWidth, height: height)
                            lines.append(line)
                            startIndex = endIndex
                            len = 1
                            width = 0
                            wordWidth = metrics.advance + characterSpacing
                        }
                    } else {
                        wordWidth = nextWidth
                        if (c.isWhitespace) {
                            spaceWidth += metrics.advance + characterSpacing
                        }
                    }
                } catch {
                    print("Error couldn't measure character '\(c)': \(error.localizedDescription)")
                }
            }
            width += wordWidth
            lastWord = eachWord
        }
        if let lastWord = lastWord {
            let line = TextLine(str: text[startIndex..<lastWord.endIndex], width: width, height: height)
            lines.append(line)
        }
        return lines
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
    
    func draw(_ renderer:SDLRenderer, _ text:Substring, x: Int, y:Int, color:SDLColor, spacing:Int = 0) {
        
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

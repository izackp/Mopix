//
//  SDLFont.swift
//  TestGame
//
//  Created by Isaac Paul on 6/24/22.
//

import Foundation
import SDL2_ttf
import SDL2

extension Bool {
    func toSDLBool() -> SDL_bool {
        if (self) {
            return SDL_TRUE
        }
        return SDL_FALSE
    }
}

extension String {
    internal func toSurface(_ block:(_ cStr:UnsafePointer<CChar>) -> (UnsafeMutablePointer<SDL_Surface>?)) throws -> SDLSurface {
        try self.withCString { (cStr:UnsafePointer<CChar>) in
            let result = block(cStr)
            let surface = try result.sdlThrow(type: type(of: self))
            return SDLSurface(ptr: surface)
        }
    }
}

extension Character {
    internal func toUInt32() throws -> UInt32 {
        let scaler = self.unicodeScalars.first?.value
        guard let ch = scaler else { throw GenericError("Can't convert \(self) to UInt32")}
        return ch
    }
    internal func toSurface(_ block:(_ ch:UInt32) -> (UnsafeMutablePointer<SDL_Surface>?)) throws -> SDLSurface {
        let ch = try toUInt32()
        let result = block(ch)
        let surface = try result.sdlThrow(type: type(of: self))
        return SDLSurface(ptr: surface)
    }
}

//TODO: A big question here.. do we use built in Font from foundation?
public final class SDLFont {
    
    // MARK: - Properties
    
    internal let internalPointer: OpaquePointer
    
    // MARK: - Initialization
    public init(file:String, ptSize:Int, index:Int = 0, hdpi:UInt32 = 0, vdpi:UInt32 = 0) throws {
        
        var fontPtr:OpaquePointer? //TODO: does this work if TTF_OpenFont returns null
        file.withCString { (ptr:UnsafePointer<CChar>) in
            fontPtr = TTF_OpenFontIndexDPI(ptr, Int32(ptSize), CLong(index), hdpi, vdpi)
        }
       
        self.internalPointer = try fontPtr.sdlThrow(type: type(of: self))
    }
    
    public init(data:Data, ptSize:Int, index:Int = 0, hdpi:UInt32 = 0, vdpi:UInt32 = 0) throws {
        
        var fontPtr:OpaquePointer?
        data.withUnsafeBytes { (dataPtr:UnsafeRawBufferPointer) in
            let rwops = SDL_RWFromMem(UnsafeMutableRawPointer(mutating: dataPtr.baseAddress), Int32(dataPtr.count))
            fontPtr = TTF_OpenFontIndexDPIRW(rwops, 0, Int32(ptSize), CLong(index), hdpi, vdpi)
        }
       
        self.internalPointer = try fontPtr.sdlThrow(type: type(of: self))
    }
    
    deinit {
        TTF_CloseFont(internalPointer)
    }
    
    //MARK: - Attributes
    static func byteSwappedUnicode(_ swapped:Bool) {
        TTF_ByteSwappedUNICODE(swapped.toSDLBool())
    }
    
    
    public enum FontStyle: Int32, BitMaskOption {
        
        case normal = 0x00000000 //Always true
        case bold = 0x00000001
        case italic = 0x00000002
        case underline = 0x00000004
        case strikethrough = 0x00000008
    }
    
    func getStyle() -> BitMaskOptionSet<FontStyle> {
        let style = TTF_GetFontStyle(internalPointer)
        return BitMaskOptionSet<FontStyle>(rawValue: style)
    }
    
    func setStyle(_ style:BitMaskOptionSet<FontStyle>) {
        TTF_SetFontStyle(internalPointer, style.rawValue)
    }
    
    func getOutline() -> Int {
        let outline = TTF_GetFontOutline(internalPointer)
        return Int(outline)
    }
    
    func setOutline(_ outline:Int) {
        TTF_SetFontOutline(internalPointer, Int32(outline))
    }
    
    public enum Hinting: Int32 {
        case normal = 0
        case light = 1
        case mono = 2
        case none = 3
        case lightSubpixel = 4
    }
    
    func getHinting() -> Hinting {
        let result = TTF_GetFontHinting(internalPointer)
        return Hinting(rawValue: result)!// ?? FontHinting.normal
    }
    
    func setHinting(_ hinting:Hinting) {
        TTF_SetFontHinting(internalPointer, hinting.rawValue)
    }
    
    public enum WrappedAlign: Int32 {
        case left = 0
        case center = 1
        case right = 2
    }
    
    func getWrappedAlign() -> WrappedAlign {
        let result = TTF_GetFontWrappedAlign(internalPointer)
        return WrappedAlign(rawValue: result)!// ?? FontHinting.normal
    }
    
    func setWrappedAlign(_ alignment:WrappedAlign) {
        TTF_SetFontWrappedAlign(internalPointer, alignment.rawValue)
    }
    
    func height() -> Int {
        return Int(TTF_FontHeight(internalPointer))
    }
    
    func ascent() -> Int {
        return Int(TTF_FontAscent(internalPointer))
    }
    
    func descent() -> Int {
        return Int(TTF_FontDescent(internalPointer))
    }
    
    func lineSkip() -> Int {
        return Int(TTF_FontLineSkip(internalPointer))
    }
    
    func getKerningAllowed() -> Bool {
        return TTF_GetFontKerning(internalPointer) > 0
    }
    
    func setKerningAllowed(_ value:Bool) {
        let conv:Int32 = value ? 1 : 0
        TTF_SetFontKerning(internalPointer, conv)
    }
    
    func faces() -> Int {
        return Int(TTF_FontFaces(internalPointer))
    }
    
    func facesIsFixedWidth() -> Bool {
        return TTF_FontFaceIsFixedWidth(internalPointer) > 0
    }
    
    func faceFamilyName() -> String? {
        guard let cStr = TTF_FontFaceFamilyName(internalPointer) else { return nil }
        return String(cString: cStr)
    }
    
    func faceStyleName() -> String? {
        guard let cStr = TTF_FontFaceStyleName(internalPointer) else { return nil }
        return String(cString: cStr)
    }
    
    func glphyIsProvided(_ c:Character) throws -> Bool {
        let ch = try c.toUInt32()
        let result = TTF_GlyphIsProvided32(internalPointer, ch)
        return (result > 0)
    }
    
    struct GlyphMetrics {
        let frame:Frame<Int> //TODO: remove? Strongly ties this to the game engine..
        let advance:Int
    }
    
    func glyphMetrics(c:Character) throws -> GlyphMetrics {
        var minX:Int32 = 0
        var maxX:Int32 = 0
        var minY:Int32 = 0
        var maxY:Int32 = 0
        var advance:Int32 = 0
        let ch = try c.toUInt32()
        let result = TTF_GlyphMetrics32(internalPointer, ch, &minX, &maxX, &minY, &maxY, &advance)
        try result.sdlThrow(type: type(of: self))
        
        let frame = Frame<Int>.init(x: Int(minX), y: Int(minY), width: Int(maxX - minX), height: Int(minY-maxY))
        return GlyphMetrics(frame: frame, advance: Int(advance))
    }
    
    func setFontSize(ptSize:Int, hdpi:Int = 0, vdpi:Int = 0) throws {
        let result = TTF_SetFontSizeDPI(internalPointer, Int32(ptSize), UInt32(hdpi), UInt32(vdpi))
        try result.sdlThrow(type: type(of: self))
    }
    
    //Swift string is backed by UTF-8 so it doesn't make sense to support more than that.
    func size(_ str:String) throws -> (Int,Int) {
        var w:Int32 = 0
        var h:Int32 = 0
        try str.withCString { (cStr:UnsafePointer<CChar>) in
            let result = TTF_SizeUTF8(internalPointer, cStr, &w, &h)
            try result.sdlThrow(type: type(of: self))
        }
        return (Int(w), Int(h))
    }
    
    public struct MeasureResult {
        let extent:Int
        let count:Int
    }
    
    public func measure(_ str:String, maxWidth:Int) throws -> MeasureResult {
        var count:Int32 = 0
        var extent:Int32 = 0
        
        try str.withCString { (cStr:UnsafePointer<CChar>) in
            let result = TTF_MeasureUTF8(internalPointer, cStr, Int32(maxWidth), &extent, &count)
            try result.sdlThrow(type: type(of: self))
        }
        return MeasureResult(extent: Int(extent), count: Int(count))
    }
    
    public func renderSolid(_ str:String, foregroundColor:SDL_Color) throws -> SDLSurface {
        try str.toSurface {
            TTF_RenderUTF8_Solid(internalPointer, $0, foregroundColor)
        }
    }
    
    public func renderSolidWrapped(_ str:String, foregroundColor:SDL_Color, wrapLengthPxs:UInt32) throws -> SDLSurface {
        try str.toSurface {
            TTF_RenderUTF8_Solid_Wrapped(internalPointer, $0, foregroundColor, wrapLengthPxs)
        }
    }
    
    public func renderLCD(_ str:String, foregroundColor:SDL_Color, backgroundColor:SDL_Color) throws -> SDLSurface {
        try str.toSurface {
            TTF_RenderUTF8_LCD(internalPointer, $0, foregroundColor, backgroundColor)
        }
    }
    
    public func renderLCDWrapped(_ str:String, foregroundColor:SDL_Color, backgroundColor:SDL_Color, wrapLengthPxs:UInt32) throws -> SDLSurface {
        try str.toSurface {
            TTF_RenderUTF8_LCD_Wrapped(internalPointer, $0, foregroundColor, backgroundColor, wrapLengthPxs)
        }
    }
    
    public func renderShaded(_ str:String, foregroundColor:SDL_Color, backgroundColor:SDL_Color) throws -> SDLSurface {
        try str.toSurface {
            TTF_RenderUTF8_Shaded(internalPointer, $0, foregroundColor, backgroundColor)
        }
    }
    
    public func renderShadedWrapped(_ str:String, foregroundColor:SDL_Color, backgroundColor:SDL_Color, wrapLengthPxs:UInt32) throws -> SDLSurface {
        try str.toSurface {
            TTF_RenderUTF8_Shaded_Wrapped(internalPointer, $0, foregroundColor, backgroundColor, wrapLengthPxs)
        }
    }
    
    public func renderBlended(_ str:String, foregroundColor:SDL_Color) throws -> SDLSurface {
        try str.toSurface {
            TTF_RenderUTF8_Blended(internalPointer, $0, foregroundColor)
        }
    }
    
    public func renderBlendedWrapped(_ str:String, foregroundColor:SDL_Color, wrapLengthPxs:UInt32) throws -> SDLSurface {
        try str.toSurface {
            TTF_RenderUTF8_Blended_Wrapped(internalPointer, $0, foregroundColor, wrapLengthPxs)
        }
    }
    
    public func renderGlyphShaded(_ c:Character,  foregroundColor:SDL_Color, backgroundColor:SDL_Color) throws -> SDLSurface {
        try c.toSurface { ch in
            TTF_RenderGlyph32_Shaded(internalPointer, ch, foregroundColor, backgroundColor)
        }
    }
    
    public func renderGlyphBlended(_ c:Character,  foregroundColor:SDL_Color) throws -> SDLSurface {
        try c.toSurface { ch in
            TTF_RenderGlyph32_Blended(internalPointer, ch, foregroundColor)
        }
    }
    
    public func renderGlyphLCD(_ c:Character,  foregroundColor:SDL_Color, backgroundColor:SDL_Color) throws -> SDLSurface {
        try c.toSurface { ch in
            TTF_RenderGlyph32_LCD(internalPointer, ch, foregroundColor, backgroundColor)
        }
    }
    
    public func renderGlyphSolid(_ c:Character,  foregroundColor:SDL_Color) throws -> SDLSurface {
        try c.toSurface { ch in
            TTF_RenderGlyph32_Solid(internalPointer, ch, foregroundColor)
        }
    }
    
    public func getFontKerningSize(prev_c:Character, c:Character) throws -> Int {
        let prev_ch = try prev_c.toUInt32()
        let ch = try c.toUInt32()
        let result = TTF_GetFontKerningSizeGlyphs32(internalPointer, prev_ch, ch)
        try result.sdlThrow(type: type(of: self))
        return Int(result)
    }
    
    public func setFontSDF(_ onOrOff:Bool) throws {
        let result = TTF_SetFontSDF(internalPointer, onOrOff.toSDLBool())
        try result.sdlThrow(type: type(of: self))
    }
    
    public func getFontSDF() -> Bool {
        let result = TTF_GetFontSDF(internalPointer)
        return (result == SDL_TRUE)
    }
    
    public func setDirection(_ dir:TTF_Direction) throws {
        let result = TTF_SetFontDirection(internalPointer, dir)
        try result.sdlThrow(type: type(of: self))
    }
    
    public func setFontScriptName(_ str:String) throws {
        try str.withCString {
            let result = TTF_SetFontScriptName(internalPointer, $0)
            try result.sdlThrow(type: type(of: self))
        }
    }
}

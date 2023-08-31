//
//  UIRenderContext.swift
//  TestGame
//
//  Created by Isaac Paul on 6/22/22.
//

import Foundation
import SDL2
import SDL2Swift

public class UIRenderContext {
    public init(renderer: Renderer, imageManger:ImageManager) {
        self.renderer = renderer
        self.imageManager = imageManger
    }
    
    let renderer:Renderer
    let imageManager:ImageManager
    private var _lastTexture:Int = 0
    //var lastOffset:Point<Int16> = .zero //TODO: This feels hacky
    var currentClipRect:Rect<DValue>? = nil
    ///Needed to preserve clipping
    var currentWindowFrame:[Rect<DValue>] = [.zero]
    
    var usingNewPage:Bool = false
    var destinationPage:[Int] = [-1]
    var rollingTextureForPage:[Int:Texture] = [:]
    var blendMode:BlendMode = .alpha
    
    func fetchFont(_ fontDesc:FontDesc) throws -> Font {
        guard let font = try imageManager.fetchFont(desc: fontDesc) else {
            throw GenericError("No font for desc: \(fontDesc.family)")
        }
        return font
    }
    
    func createAndDrawToTexture(_ block:(_ context:UIRenderContext, _ frame:Rect<DValue>) throws -> (), size:Size<DValue>) throws -> AtlasImage {
        let atlas = imageManager.atlas
        let subTexture = try atlas.saveBlankImage(size)
        let targetImage = AtlasImage(texture: subTexture, atlas: atlas)
        //we must use the correct texture
        let pageIndex = subTexture.texturePageIndex
        let texture = rollingTextureForPage[pageIndex] ?? atlas.listPages[pageIndex].texture
        
        //let previousBlendmode = blendMode
        let previousTarget = try renderer.swapTarget(texture)
        let targetFrame = targetImage.sourceRect.to(Int16.self)
        currentWindowFrame.append(targetFrame)
        let lastClip = currentClipRect
        try setClipRect(targetFrame)
        destinationPage.append(pageIndex)
        //blendMode = .none
        
        try block(self, targetFrame)
        
        usingNewPage = false
        destinationPage.removeLast()
        currentWindowFrame.removeLast()
        //blendMode = previousBlendmode
        
        try setClipRect(lastClip)
        
        if let tempImage = rollingTextureForPage[pageIndex] {
            let old = atlas.listPages[pageIndex].texture
            let newPage = TexturePage(texture: tempImage, allocator: atlas.listPages[pageIndex].allocator)
            atlas.listPages[pageIndex] = newPage
            atlas.returnTexture(old)
            rollingTextureForPage[pageIndex] = nil
        }
        
        let prevPageIndex = destinationPage.last!
        if (prevPageIndex == -1) {
            try renderer.setTarget(previousTarget)
        } else if let target = rollingTextureForPage[prevPageIndex] {
            try renderer.setTarget(target)
            usingNewPage = true
        } else {
            let target = atlas.listPages[prevPageIndex].texture
            try renderer.setTarget(target)
        }
        
        return targetImage
    }
    
    /*
    func pushOffset(_ point:Point<Int16>) {
        lastOffset = Point(lastOffset.x + point.x, lastOffset.y + point.y)
    }
    
    func popOffset(_ point:Point<Int16>) {
        lastOffset = Point(lastOffset.x - point.x, lastOffset.y - point.y)
    }
    func setClipRectRelative(_ frame:Rect<DValue>) throws {
        var newFrame = frame.offset(lastOffset)
        newFrame.clip(currentWindowFrame) //Metal crashes when clipping area exceeds window size
        try renderer.setClipRect(newFrame.sdlRect())
    }*/
    
    func setClipRect(_ frame:Rect<DValue>?) throws {
        var newFrame = frame
        newFrame?.clip(currentWindowFrame.last!)
        try renderer.setClipRect(newFrame?.sdlRect())
        currentClipRect = newFrame
    }
    
    func drawText( _ text:Substring, _ font:Font, _ pos:Point<Int16>, _ color:SDLColor, _ alpha:Float = 1, spacing:Int = 0) throws {
        //let bounds = currentWindowFrame.last!
        var dest = Rect<Int16>(x: pos.x, y: pos.y, width: 0, height: 0)
        for c in text {
            do {
                let metrics = try font._font.glyphMetrics(c: c)
                let image = try font.glyph(c)
                let imageSize = image.size.to(Int16.self)
                dest.width = imageSize.width
                dest.height = imageSize.height
                renderer.draw(image, dest.sdlRect(), color)
                dest.x += Int16(metrics.advance) + Int16(spacing)
            } catch {
                print("Error couldn't draw character '\(c)': \(error.localizedDescription)")
            }
        }
    }
    
    func drawTextLine( _ text:ArraySlice<RenderableCharacter>, _ pos:Point<Int16>, _ alpha:Float = 1) throws {
        //let bounds = currentWindowFrame.last!
        var dest = Rect<Int16>(x: pos.x, y: pos.y, width: 0, height: 0)
        for c in text {
            dest.width = Int16(c.size.width)
            dest.height = Int16(c.size.height)
            
            if let bgColor = c.background {
                try drawSquare(dest, bgColor.sdlColor())
            }
            if let image = c.img {
                dest.height = Int16(image.size.height)
                //assert(c.size.asInt32() == image.subTextureIndex.sourceRect.size)
                renderer.draw(image, dest.sdlRect(), c.foreground.sdlColor())
            }
            dest.x += Int16(c.size.width)
        }
    }
    
    func drawSquare(_ dest:Rect<Int16>, _ color:SDLColor, _ alpha:Float = 1) throws {
        //let newFrame = frame.offset(lastOffset)
        //TODO: we can probably just return sdl texture and source
        //var newFrame = frame
        //newFrame.clip(currentWindowFrame)
        let atlas = imageManager.atlas
        let blankSubTexture = try atlas.blankTextureIndex(_lastTexture)
        let texturePage = atlas.listPages[blankSubTexture.texturePageIndex]
        let source = blankSubTexture.sourceRect.sdlRect()
        let texture = texturePage.texture
        try drawImage2(dest, color, 1, imgSrc: SDLTextureSlice(texture: texture, rect: source), texturePageIndex: blankSubTexture.texturePageIndex)
    }
    
    private func copyAndSetTargetPage(_ index:Int) throws {
        let atlas = imageManager.atlas
        let texturePage = atlas.listPages[index]
        let newTexture = try atlas.createTexture()
        try renderer.setTarget(newTexture)
        //TODO: Why below int32 and above int??
        let textureFrame = SDL_Rect(x: 0, y: 0, w: Int32(atlas.textureSize.width), h: Int32(atlas.textureSize.height))
        let texture = texturePage.texture
        try texture.setColorModulation(SDLColor.white)
        try texture.setAlphaModulation(255)
        let previousBlendMode = try texture.blendMode()
        try texture.setBlendMode([BlendMode.none])
        try renderer.copy(texture, source: textureFrame, destination: textureFrame)
        //destinationPage[destinationPage.count - 1] = -1
        usingNewPage = true
        rollingTextureForPage[index] = newTexture
        try newTexture.setBlendMode(previousBlendMode)
    }
    
    func drawImage(_ image:AtlasImage, _ dest:Rect<Int16>, _ color:SDLColor = SDLColor.white, _ alpha:Float = 1) throws {
        let src = image.getTextureSlice()
        try drawImage2(dest, color, alpha, imgSrc: src, texturePageIndex: image.subTextureIndex.texturePageIndex)
    }
    
    func drawImage2(_ dest:Rect<Int16>, _ color:SDLColor, _ alpha:Float, imgSrc:SDLTextureSlice, texturePageIndex:Int) throws {
        _lastTexture = texturePageIndex
        if (!usingNewPage && destinationPage.last == _lastTexture) {
            try copyAndSetTargetPage(_lastTexture)
        }
        if (try imgSrc.texture.blendMode().contains(blendMode) == false) {
            try imgSrc.texture.setBlendMode([blendMode])//TODO: wth why optionset
        }
        renderer.draw(imgSrc, dest.sdlRect(), color, alpha)
    }
        
    func drawAtlas(_ x:Int, _ y:Int, index:Int = 0) throws {
        let listPages = imageManager.atlas.listPages
        if (index >= listPages.count) { return }
        let texture = listPages[index].texture
        try texture.setColorModulation(255, 255, 255)
        try renderer.copy(texture, source: SDL_Rect(x: 0, y: 0, w: 1024, h: 1024), destination: SDL_Rect(x: Int32(x), y: Int32(y), w: 1024, h: 1024))
    }
}

//
//  View.swift
//  TestGame
//
//  Created by Isaac Paul on 4/13/22.
//

import Foundation
import SDL2

public struct ViewLayoutBuilder {
    public var view:View
}

open class View {
    public var frame:Frame<Int16> = Frame.zero
    public var listLayouts:Arr<LayoutElement> = Arr<LayoutElement>.init()
    public var children:Arr<View> = Arr<View>.init()
    
    public var clipBounds:Bool = false

    open func layout() {
        //TODO: I'm not sure if a 'layout is dirty' check will improve performance
        for eachItem in listLayouts {
            eachItem.updateFrame(self)
        }

        layoutChildren()
    }

    open func layoutChildren() {
        for eachView in children {
            eachView.layout()
        }
    }
    
    public func configureLayout() -> ViewLayoutBuilder {
        return ViewLayoutBuilder(view: self)
    }
    
    
    open var backgroundColor = SDLColor.white
    
    open func draw(_ renderer:SDLRenderer, texture:SDLTexture) throws {
        
        //let surface = try SDLSurface(rgb: (0, 0, 0, 0), size: frame.toSDLSize(), depth: 32)
        //try surface.fill(color: backgroundColor)
        //let surfaceTexture = try SDLTexture(renderer: renderer, surface: surface)
        //try surfaceTexture.setBlendMode([.alpha])
        try texture.setColorModulation(backgroundColor)
        try renderer.copy(texture, destination: frame.sdlRect())
        
        for eachChild in children {
            try eachChild.draw(renderer, texture: texture)
        }
    }
}

public struct FontDesc {
    public var family:String
    public var weight:Uint16
    public var size:Float
    
    public static let defaultFont = FontDesc(family: "default", weight: 100, size: 14)
}

public class TextView : View {
    
    public var text:String = ""
    public var textColor:SDLColor = SDLColor.black
    
    public var font:FontDesc = FontDesc.defaultFont

    public var lineHeight:Float = 0
    public var characterSpacing:Int = 0
    public var lineStackingStrategy:Int = 0
    
    public var textWrapping:Int = 0
    public var textTrimming:Int = 0
    //isTextTrimmed
    public var textAlignment:Int = 0
    public var maxLines:Int = 0

    
    public init(text:String) {
        
    }
    
    open override func draw(_ renderer:SDLRenderer, texture:SDLTexture) throws {
        
        //let surface = try SDLSurface(rgb: (0, 0, 0, 0), size: frame.toSDLSize(), depth: 32)
        //try surface.fill(color: backgroundColor)
        //let surfaceTexture = try SDLTexture(renderer: renderer, surface: surface)
        //try surfaceTexture.setBlendMode([.alpha])
        try texture.setColorModulation(backgroundColor)
        try renderer.copy(texture, destination: frame.sdlRect())
        
        if (text.count > 0) {
            
        }
        
        for eachChild in children {
            try eachChild.draw(renderer, texture: texture)
        }
    }
}

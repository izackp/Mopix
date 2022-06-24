//
//  TextView.swift
//  TestGame
//
//  Created by Isaac Paul on 6/22/22.
//

import Foundation
import SDL2

public struct FontDesc {
    public var family:String
    public var weight:UInt16
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
    
    open override func draw(_ context:UIRenderContext) throws {
        
        try context.drawSquare(frame, backgroundColor)
        
        if (text.count > 0) {
            try context.drawText(frame, textColor, text, font)
        }
        
        for eachChild in children {
            try eachChild.draw(context)
        }
    }
}

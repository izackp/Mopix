//
//  TextView.swift
//  TestGame
//
//  Created by Isaac Paul on 6/22/22.
//

import Foundation
import SDL2

public struct FontDesc : Hashable {
    public var family:String
    public var weight:UInt16
    public var size:Float
    
    public static let defaultFont = FontDesc(family: "Roboto", weight: 100, size: 21)
}


public class TextView : View {
    
    public var text:String = ""
    public var textColor:SDLColor = SDLColor.idk
    
    public var fontDesc:FontDesc = FontDesc.defaultFont

    public var lineHeight:Float = 0
    public var characterSpacing:Int = 0
    public var lineStackingStrategy:Int = 0
    
    public var textWrapping:Int = 0
    public var textTrimming:Int = 0
    //isTextTrimmed
    public var textAlignment:Int = 0
    public var maxLines:Int = 0

    private var _cachedFont:Font! = nil
    
    public init(text:String) {
        self.text = text
    }
    
    func fetchFont(_ context:UIRenderContext) throws -> Font  {
        if let font = _cachedFont {
            return font
        }
        guard let font = try context.imageManager.fetchFont(desc: fontDesc) else {
            throw GenericError("No font for desc: \(fontDesc.family)")
        }
        _cachedFont = font
        return font
    }
    
    open override func draw(_ context:UIRenderContext) throws {
        
        try context.drawSquare(frame, backgroundColor)
        
        if (text.count > 0) {
            do {
                let font = try fetchFont(context)
                try context.drawText(frame, textColor, text, font)
            } catch {
                print("Error drawing text: \(error.localizedDescription)")
            }
        }
        
        for eachChild in children {
            try eachChild.draw(context)
        }
    }
}

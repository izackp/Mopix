//
//  TextField.swift
//  TestGame
//
//  Created by Isaac Paul on 10/4/22.
//

import Foundation
import SDL2

@available(macOS 12, *)
public class TextField : TextView {
    
    public var placeHolder:String = ""
    public var placeHolderColor:LabeledColor = LabeledColor.black
    public var placeHolderFont:FontDesc = FontDesc.defaultFont

    private var _placeHolderFont:Font? = nil
    
    private var _hasFocus:Bool = false
    private var _selectionStart:Int? = nil
    private var _cursor:Int = 0
    
    required public init() {
        super.init()
    }
    
    private enum CodingKeys: String, CodingKey {
        case placeHolder
        case placeHolderColor
        case placeHolderFont
    }
    
    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.placeHolder = try container.decodeIfPresent(String.self, forKey: .placeHolder) ?? ""
        self.placeHolderColor = try container.decodeDynamicItemIfPresent(LabeledColor.self, forKey: .placeHolderColor) ?? LabeledColor.idk
        self.placeHolderFont = try container.decodeIfPresent(FontDesc.self, forKey: .placeHolderFont) ?? FontDesc.defaultFont
    }
    
    public override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        if (placeHolder.count > 0) {
            try container.encode(placeHolder, forKey: .placeHolder)
        }
        if (placeHolderColor !== LabeledColor.idk) {
            try container.encode(placeHolderColor, forKey: .placeHolderColor)
        }
        if (placeHolderFont != FontDesc.defaultFont) {
            try container.encode(placeHolderFont, forKey: .placeHolderFont)
        }
    }
    
    func fetchPlaceHolderFont(_ context:UIRenderContext) throws -> Font  {
        if let font = _placeHolderFont {
            return font
        }
        guard let font = try context.imageManager.fetchFont(desc: placeHolderFont) else {
            throw GenericError("No font for desc: \(fontDesc.family)")
        }
        _placeHolderFont = font
        return font
    }
    
    open override func onMousePress(_ event: MouseButtonEvent) {
        super.onMousePress(event)
        //
    }
    
    open override func drawContent(_ context:UIRenderContext, _ rect:Frame<DValue>) throws {
        try super.drawContent(context, rect)
        //return
        if (text.count != 0 || placeHolder.count == 0) { return }
        if (_hasFocus) { return }
        
        //let font = try fetchPlaceHolderFont(context)
        
        //TODO: Copied in parent
        let textContext = TextContext(font: fontDesc, foregroundColor: self.placeHolderColor, backgroundColor: nil, kern: 0, tracking: 0, image: nil)
        
        let lines:[TextLine2]
        switch textWrapping {
            case .character:
                //lines = try font.splitIntoLines(text, maxWidthPxs: Int(rect.width), characterSpacing: characterSpacing)
                fallthrough
            case .word:
                lines = try TextLine2.buildFrom(attributedText, renderContext: context, context: textContext, maxWidthPxs: Int(rect.width))//try font.splitIntoLinesWordWrapped2(text, maxWidthPxs: Int(rect.width), characterSpacing: characterSpacing)
                break
            case .none:
                lines = try TextLine2.buildFrom(attributedText, renderContext: context, context: textContext, maxWidthPxs: nil)
        }
            
        var totalHeight = 0
        for eachLine in lines {
            totalHeight += eachLine.maxHeight
        }
        var y:Int16 = (rect.height - Int16(totalHeight)) / 2 + rect.y
        var firstLine = true
        for eachLine in lines {
            let lineWidth:Int
            let subStr:ArraySlice<RenderableCharacter>
            if (firstLine) {
                lineWidth = eachLine.widthTrimmingEndSpace()
                subStr = eachLine.strTrimmingEndSpace()
            } else {
                lineWidth = eachLine.widthTrimmingSpace()
                subStr = eachLine.strTrimmingSpace()
            }
            firstLine = false
            if lineWidth == 0 {
                y += Int16(eachLine.maxHeight)
                continue
            }
            let x:Int16
            switch textAlignment {
                case .center:
                    x = (rect.width - Int16(lineWidth)) / 2 + rect.x
                    break
                case .left:
                    fallthrough
                case .start:
                    x = rect.x
                    break
                case .right:
                    fallthrough
                case .end:
                    x = rect.right - Int16(lineWidth)
            }
            try context.drawTextLine(subStr, Point(x, y))
            y += Int16(eachLine.maxHeight)
        }
    }
}

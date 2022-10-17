//
//  TextField.swift
//  TestGame
//
//  Created by Isaac Paul on 10/4/22.
//

import Foundation
import SDL2

public class TextField : TextView {
    
    public var placeHolder:String = ""
    public var placeHolderColor:SmartColor = SmartColor.black
    public var placeHolderFont:FontDesc = FontDesc.defaultFont

    private var _placeHolderFont:Font? = nil
    
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
        self.placeHolderColor = try container.decodeDynamicItemIfPresent(SmartColor.self, forKey: .placeHolderColor) ?? SmartColor.idk
        self.placeHolderFont = try container.decodeIfPresent(FontDesc.self, forKey: .placeHolderFont) ?? FontDesc.defaultFont
    }
    
    public override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        if (placeHolder.count > 0) {
            try container.encode(placeHolder, forKey: .placeHolder)
        }
        if (placeHolderColor !== SmartColor.idk) {
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
    
    open override func drawContent(_ context:UIRenderContext, _ rect:Frame<DValue>) throws {
        try super.drawContent(context, rect)
        //return
        if (text.count != 0 || placeHolder.count == 0) { return }
        
        let font = try fetchPlaceHolderFont(context)
        
        //TODO: Copied in parent
        let lines:[TextLine]
        switch textWrapping {
            case .word:
                lines = try font.splitIntoLinesWordWrapped2(placeHolder, maxWidthPxs: Int(rect.width), characterSpacing: characterSpacing)
                break
            case .character:
                lines = try font.splitIntoLines(placeHolder, maxWidthPxs: Int(rect.width), characterSpacing: characterSpacing)
            case .none:
                lines = [TextLine(str: placeHolder.substring(from: 0), width: try font.widthOfText(placeHolder, maxWidthPxs: Int(Int32.max)).extent, height: font._font.height())]
        }
            
        guard let height = lines.first(where: { $0.height > 0 })?.height else { print("error no height"); return }
        let totalHeight = Int16(height * lines.count)
        var y:Int16 = (rect.height - totalHeight) / 2 + rect.y
        var firstLine = true
        for eachLine in lines {
            let lineWidth:Int
            let subStr:Substring
            if (firstLine) {
                lineWidth = eachLine.widthTrimmingEndSpace()
                subStr = eachLine.strTrimmingEndSpace()
            } else {
                lineWidth = eachLine.widthTrimmingSpace()
                subStr = eachLine.strTrimmingSpace()
            }
            firstLine = false
            if lineWidth == 0 {
                y += Int16(height)
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
                    x = 0
                    break
                case .right:
                    fallthrough
                case .end:
                    x = rect.right - Int16(lineWidth)
            }
            print("Drawing ph \(Point(x, y))")
            try context.drawText(subStr, font, Point(x, y), placeHolderColor, spacing: characterSpacing)
            y += Int16(height)
        }
    }
}

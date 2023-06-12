//
//  TextView.swift
//  TestGame
//
//  Created by Isaac Paul on 6/22/22.
//

import Foundation
import SDL2


//TODO: limit amount of possible lines
@available(macOS 12, *)
public class TextView : View {
    
    private var _text:String = ""
    public var text:String {
        get {
            return _text
        }
        set {
            if (_text == newValue) { return }
            _text = newValue
            _attrText = nil
        }
    }
    private var _attrText:AttributedString? = nil
    public var attributedText:AttributedString {
        get {
            if let result = _attrText {
                return result
            }
            let other = AttributedString(text)
            _attrText = other
            return other
        }
        set {
            _attrText = newValue
            _text = ""
        }
    }
    public var textColor:LabeledColor = LabeledColor.idk
    
    public var fontDesc:FontDesc = FontDesc.defaultFont

    public var lineHeight:Float = 0.0
    public var characterSpacing:Int = 0
    
    public var textWrapping:TextWrapping = .word
    public var textTrimming:Int = 0
    //isTextTrimmed
    public var textAlignment:TextAlignment = .center
    public var maxLines:Int = 0

    private var _cachedFont:Font! = nil
    private var _selectable:Bool = false
    
    var stats = Stats()
    
    required public override init() {
        super.init()
    }
    
    public init(text:String) {
        _text = text
        super.init()
    }
    
    private enum CodingKeys: String, CodingKey {
        case text
        case textColor
        case fontDesc
        case lineHeight
        case characterSpacing
        case textWrapping
        case textTrimming
        case textAlignment
        case maxLines
    }
    
    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder, clipBoundsDefault: true)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.text = try container.decodeIfPresent(String.self, forKey: .text) ?? ""
        self.textColor = try container.decodeDynamicItemIfPresent(LabeledColor.self, forKey: .textColor) ?? LabeledColor.idk
        self.fontDesc = try container.decodeIfPresent(FontDesc.self, forKey: .fontDesc) ?? FontDesc.defaultFont
        self.lineHeight = try container.decodeIfPresent(Float.self, forKey: .lineHeight) ?? 0.0
        self.characterSpacing = try container.decodeIfPresent(Int.self, forKey: .characterSpacing) ?? 0 //TODO: Int changes based on platform
        self.textWrapping = try container.decodeIfPresent(TextWrapping.self, forKey: .textWrapping) ?? .word
        self.textTrimming = try container.decodeIfPresent(Int.self, forKey: .textTrimming) ?? 0
        self.textAlignment = try container.decodeDynamicItemIfPresent(TextAlignment.self, forKey: .textAlignment) ?? .center
    }
    
    public override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        if (text.count > 0) {
            try container.encode(text, forKey: .text)
        }
        if (textColor !== LabeledColor.idk) {
            try container.encode(textColor, forKey: .textColor)
        }
        if (fontDesc != FontDesc.defaultFont) {
            try container.encode(fontDesc, forKey: .fontDesc)
        }
        if (self.lineHeight != 0.0) {
            try container.encode(lineHeight, forKey: .lineHeight)
        }
        if (self.characterSpacing != 0) {
            try container.encode(characterSpacing, forKey: .characterSpacing)
        }
        if (self.textWrapping != .word) {
            try container.encode(textWrapping, forKey: .textWrapping)
        }
        if (self.textTrimming != 0) {
            try container.encode(textTrimming, forKey: .textTrimming)
        }
        if (self.textAlignment != .center) {
            try container.encode(textAlignment, forKey: .textAlignment)
        }
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
    
    open override func drawContent(_ context:UIRenderContext, _ rect:Rect<DValue>) throws {
        //stats.printStats()
        if (text.count == 0) { return }
        //let font = try fetchFont(context)
        let textContext = TextContext(font: fontDesc, foregroundColor: self.textColor, backgroundColor: LabeledColor.white, kern: 0, tracking: 0, image: nil)
        
        
        var lines:[TextLine2] = []
        //try Application._shared.stats.measure("build draw thing") {
            switch textWrapping {
                case .character:
                    //lines = try font.splitIntoLines(text, maxWidthPxs: Int(rect.width), characterSpacing: characterSpacing)
                    fallthrough
                case .word:
                    //print("Building: \(text)")
                    lines = try TextLine2.buildFrom(attributedText, renderContext: context, context: textContext, maxWidthPxs: Int(rect.width))//try font.splitIntoLinesWordWrapped2(text, maxWidthPxs: Int(rect.width), characterSpacing: characterSpacing)
                    break
                case .none:
                    lines = try TextLine2.buildFrom(attributedText, renderContext: context, context: textContext, maxWidthPxs: nil)
            }
        //}

        
        
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

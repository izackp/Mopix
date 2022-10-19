//
//  TextView.swift
//  TestGame
//
//  Created by Isaac Paul on 6/22/22.
//

import Foundation
import SDL2

public enum TextWrapping : Int, Codable {
    case none
    case character
    case word
}

public enum TextAlignment : Int, Codable, ExpressibleByString {
    public init(_ value: String) throws {
        switch (value) {
            case "center":
                self = .center
            case "start":
                self = .start
            case "end":
                self = .end
            case "left":
                self = .left
            case "right":
                self = .right
            default:
                self = .center
        }
    }
    
    case center
    case start
    case end
    case left
    case right
}

struct TextLine {
    let str:Substring
    let width:Int
    let height:Int
    let startSpaceCount:Int
    let startSpaceWidth:Int
    let endSpaceCount:Int
    let endSpaceWidth:Int
    
    init(str: Substring, width: Int, height: Int, startSpaceCount: Int = 0, startSpaceWidth: Int = 0, endSpaceCount: Int = 0, endSpaceWidth: Int = 0) {
        self.str = str
        self.width = width
        self.height = height
        self.startSpaceCount = startSpaceCount
        self.startSpaceWidth = startSpaceWidth
        self.endSpaceCount = endSpaceCount
        self.endSpaceWidth = endSpaceWidth
    }
    
    func strTrimmingEndSpace() -> Substring {
        let offset = str.index(str.endIndex, offsetBy: -endSpaceCount)
        let newStr = str[str.startIndex..<offset]
        return newStr
    }
    
    func widthTrimmingEndSpace() -> Int {
        return width - endSpaceWidth
    }
    
    func strTrimmingSpace() -> Substring {
        let startOffset = str.index(str.startIndex, offsetBy: startSpaceCount)
        let offset = str.index(str.endIndex, offsetBy: -endSpaceCount)
        let newStr = str[startOffset..<offset]
        return newStr
    }
    
    func widthTrimmingSpace() -> Int {
        return width - startSpaceWidth - endSpaceWidth
    }
}


public class TextView : View {
    
    public var text:String = ""
    public var textColor:SmartColor = SmartColor.idk
    
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
    
    required public override init() {
        super.init()
    }
    
    public init(text:String) {
        self.text = text
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
        self.textColor = try container.decodeDynamicItemIfPresent(SmartColor.self, forKey: .textColor) ?? SmartColor.idk
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
        if (textColor !== SmartColor.idk) {
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
    
    open override func drawContent(_ context:UIRenderContext, _ rect:Frame<DValue>) throws {
        if (text.count == 0) { return }
        let font = try fetchFont(context)
        
        let lines:[TextLine]
        switch textWrapping {
            case .word:
                lines = try font.splitIntoLinesWordWrapped2(text, maxWidthPxs: Int(rect.width), characterSpacing: characterSpacing)
                break
            case .character:
                lines = try font.splitIntoLines(text, maxWidthPxs: Int(rect.width), characterSpacing: characterSpacing)
            case .none:
                lines = [TextLine(str: text.substring(from: 0), width: try font.widthOfText(text, maxWidthPxs: Int(Int32.max)).extent, height: font._font.height(), startSpaceCount: 0, startSpaceWidth: 0, endSpaceCount: 0, endSpaceWidth: 0)]
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
                    x = rect.x
                    break
                case .right:
                    fallthrough
                case .end:
                    x = rect.right - Int16(lineWidth)
            }
            try context.drawText(subStr, font, Point(x, y), textColor, spacing: characterSpacing)
            y += Int16(height)
        }
    }
}

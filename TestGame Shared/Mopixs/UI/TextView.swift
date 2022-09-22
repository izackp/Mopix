//
//  TextView.swift
//  TestGame
//
//  Created by Isaac Paul on 6/22/22.
//

import Foundation
import SDL2


public class TextView : View {
    
    public var text:String = ""
    public var textColor:SmartColor = SmartColor.idk
    
    public var fontDesc:FontDesc = FontDesc.defaultFont

    public var lineHeight:Float = 0.0
    public var characterSpacing:Int = 0
    public var lineStackingStrategy:Int = 0
    
    public var textWrapping:Int = 0
    public var textTrimming:Int = 0
    //isTextTrimmed
    public var textAlignment:Int = 0
    public var maxLines:Int = 0

    private var _cachedFont:Font! = nil
    
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
        case lineStackingStrategy
        case textWrapping
        case textTrimming
        case textAlignment
        case maxLines
    }
    
    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.text = try container.decodeIfPresent(String.self, forKey: .text) ?? ""
        self.textColor = try container.decodeDynamicItemIfPresent(SmartColor.self, forKey: .textColor) ?? SmartColor.idk
        self.fontDesc = try container.decodeIfPresent(FontDesc.self, forKey: .fontDesc) ?? FontDesc.defaultFont
        self.lineHeight = try container.decodeIfPresent(Float.self, forKey: .lineHeight) ?? 0.0
        self.characterSpacing = try container.decodeIfPresent(Int.self, forKey: .characterSpacing) ?? 0 //TODO: Int changes based on platform
        self.textWrapping = try container.decodeIfPresent(Int.self, forKey: .textWrapping) ?? 0
        self.textTrimming = try container.decodeIfPresent(Int.self, forKey: .textTrimming) ?? 0
        self.textAlignment = try container.decodeIfPresent(Int.self, forKey: .textAlignment) ?? 0
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
        if (self.textWrapping != 0) {
            try container.encode(textWrapping, forKey: .textWrapping)
        }
        if (self.textTrimming != 0) {
            try container.encode(textTrimming, forKey: .textTrimming)
        }
        if (self.textAlignment != 0) {
            try container.encode(textAlignment, forKey: .textAlignment)
        }
    }
    
    //MARK: - Serialization
    // Generated on : 2022-07-26 13:43:08 +0000
    /*
    required init(_ dictionary: Dictionary<String, Any>, _ cache:InstanceCache? = nil) throws {
        try super.init(dictionary, cache)
        text = try dictionary.expect("text")
        //We also want the ability to set colors via labels
        //So a color _cant_ just be an int.. but
        let test:UInt32 = try dictionary.expect("text")
        textColor = SmartColor(integerLiteral: test)
        //textColor = SDLColor(rawValue: try dictionary.expect("textColor"), cache)
        //fontDesc = FontDesc(try dictionary.expectDictionary("fontDesc"), cache)
        lineHeight = try dictionary.expect("lineHeight")
        characterSpacing = try dictionary.expect("characterSpacing")
        lineStackingStrategy = try dictionary.expect("lineStackingStrategy")
        textWrapping = try dictionary.expect("textWrapping")
        textTrimming = try dictionary.expect("textTrimming")
        textAlignment = try dictionary.expect("textAlignment")
        maxLines = try dictionary.expect("maxLines")
    }
    
    override public func toDictionary() -> [String : Any] {
        return [
            "text":text,
            //"textColor":textColor.toDictionary(),
            "fontDesc":fontDesc.toDictionary(),
            "lineHeight":lineHeight,
            "characterSpacing":characterSpacing,
            "lineStackingStrategy":lineStackingStrategy,
            "textWrapping":textWrapping,
            "textTrimming":textTrimming,
            "textAlignment":textAlignment,
            "maxLines":maxLines
        ]
    }*/
    // Hash : abc
    
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

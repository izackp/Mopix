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
    
    init(family: String, weight: UInt16, size: Float) {
        self.family = family
        self.weight = weight
        self.size = size
    }
    
    init(_ dictionary: [String : Any]) throws {
        family = try dictionary.expect("family")
        weight = try dictionary.expect("weight")
        size = try dictionary.expect("size")
    }
    
    func toDictionary() -> [String : Any] {
        return [
            "family":family,
            "weight":weight,
            "size":size
        ]
    }
}


public class TextView : View, Initializable {
    
    public var text:String = ""
    public var textColor:SmartColor = SmartColor.idk
    
    public var fontDesc:FontDesc = FontDesc.defaultFont

    public var lineHeight = 0.0
    public var characterSpacing = 0
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
    
    public required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
    
    //MARK: - Serialization
    // Generated on : 2022-07-26 13:43:08 +0000
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
    }
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
                try context.drawText(frame, textColor.sdlColor(), text, font)
            } catch {
                print("Error drawing text: \(error.localizedDescription)")
            }
        }
        
        for eachChild in children {
            try eachChild.draw(context)
        }
    }
}

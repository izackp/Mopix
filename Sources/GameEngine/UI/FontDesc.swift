//
//  FontDesc.swift
//  TestGame
//
//  Created by Isaac Paul on 8/9/22.
//

import Foundation
/*
 - Font traits
 - - traitItalic: UIFontDescriptor.SymbolicTraits
        The font’s style is italic.
 - - traitBold: UIFontDescriptor.SymbolicTraits
        The font’s style is boldface.
 - - traitExpanded: UIFontDescriptor.SymbolicTraits
        The font’s characters have an expanded width.
 - - traitCondensed: UIFontDescriptor.SymbolicTraits
        The font’s characters have a condensed width.
 - - traitMonoSpace: UIFontDescriptor.SymbolicTraits
        The font’s characters all have the same width.
 - - traitVertical: UIFontDescriptor.SymbolicTraits
        The font uses vertical glyph variants and metrics.
 - - traitUIOptimized: UIFontDescriptor.SymbolicTraits
        The font synthesizes appropriate attributes for user interface rendering, such as in control titles, if necessary.
 - - traitTightLeading: UIFontDescriptor.SymbolicTraits
        The font uses a leading value that’s less than the default.
 - - traitLooseLeading: UIFontDescriptor.SymbolicTraits
        The font uses a leading value that’s greater than the default.
 - - classMask: UIFontDescriptor.SymbolicTraits
        The font family class mask that you use to access font descriptor values.
 - - classOldStyleSerifs: UIFontDescriptor.SymbolicTraits
        The font’s characters include serifs, and reflect the Latin printing style of the 15th to 17th centuries.
 - - classTransitionalSerifs: UIFontDescriptor.SymbolicTraits
        The font’s characters include serifs, and reflect the Latin printing style of the 18th to 19th centuries.
 - - classModernSerifs: UIFontDescriptor.SymbolicTraits
        The font’s characters include serifs, and reflect the Latin printing style of the 20th century.
 - - classClarendonSerifs: UIFontDescriptor.SymbolicTraits
        The font’s characters include variations of old style and transitional serifs.
 - - classSlabSerifs: UIFontDescriptor.SymbolicTraits
        The font’s characters use square transitions, without brackets, between strokes and serifs.
 - - classFreeformSerifs: UIFontDescriptor.SymbolicTraits
        The font’s characters include serifs, and don’t generally fit within other serif design classifications.
 - - classSansSerif: UIFontDescriptor.SymbolicTraits
        The font’s characters don’t have serifs.
 - - classOrnamentals: UIFontDescriptor.SymbolicTraits
        The font’s characters use highly decorated or stylized character shapes.
 - - classScripts: UIFontDescriptor.SymbolicTraits
        The font’s characters simulate handwriting.
 - - classSymbolic: UIFontDescriptor.SymbolicTraits
        The font’s characters consist mainly of symbols rather than letters and numbers.
 
 */

public struct FontDesc : Codable, Hashable {
    
    public let family:String
    public let weight:UInt16
    public let size:Float
    private let _hash:Int
    
    public var hashValue: Int {
        get { return _hash }
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(_hash)
    }
    
    public static let defaultFont = FontDesc(family: "PingFangSC-Regular", weight: 100, size: 18)
    
    init(family: String, weight: UInt16, size: Float) {
        self.family = family
        self.weight = weight
        self.size = size
        
        var hasher = Hasher()
        hasher.combine(family)
        hasher.combine(weight)
        hasher.combine(size)
        _hash = hasher.finalize()
    }
    
    enum CodingKeys: CodingKey {
        case family
        case weight
        case size
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.family = try container.decodeIfPresent(String.self, forKey: .family) ?? "Roboto"
        self.weight = try container.decodeIfPresent(UInt16.self, forKey: .weight) ?? 100
        self.size = try container.decodeIfPresent(Float.self, forKey: .size) ?? 21
        
        var hasher = Hasher()
        hasher.combine(family)
        hasher.combine(weight)
        hasher.combine(size)
        _hash = hasher.finalize()
    }
    
    
    /*
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
    }*/
}

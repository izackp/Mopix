//
//  MopixAttributes.swift
//  TestGame
//
//  Created by Isaac Paul on 10/27/22.
//

import Foundation



extension AttributeScopes {

    public var mopix: AttributeScopes.MopixAttributes.Type { get {
        return MopixAttributes.self
    } }

    public struct MopixAttributes : AttributeScope {

        public let font: AttributeScopes.MopixAttributes.FontAttribute

        //public let paragraphStyle: AttributeScopes.MopixAttributes.ParagraphStyleAttribute

        public let foregroundColor: AttributeScopes.MopixAttributes.ForegroundColorAttribute

        public let backgroundColor: AttributeScopes.MopixAttributes.BackgroundColorAttribute

        public let ligature: AttributeScopes.MopixAttributes.LigatureAttribute

        public let kern: AttributeScopes.MopixAttributes.KernAttribute

        public let tracking: AttributeScopes.MopixAttributes.TrackingAttribute

        public let strikethroughStyle: AttributeScopes.MopixAttributes.StrikethroughStyleAttribute

        public let underlineStyle: AttributeScopes.MopixAttributes.UnderlineStyleAttribute

        public let strokeColor: AttributeScopes.MopixAttributes.StrokeColorAttribute

        public let strokeWidth: AttributeScopes.MopixAttributes.StrokeWidthAttribute

        public let shadow: AttributeScopes.MopixAttributes.ShadowAttribute

        ////public let textEffect: AttributeScopes.MopixAttributes.TextEffectAttribute

        public let attachment: AttributeScopes.MopixAttributes.AttachmentAttribute

        public let baselineOffset: AttributeScopes.MopixAttributes.BaselineOffsetAttribute

        public let underlineColor: AttributeScopes.MopixAttributes.UnderlineColorAttribute

        public let strikethroughColor: AttributeScopes.MopixAttributes.StrikethroughColorAttribute

        public let obliqueness: AttributeScopes.MopixAttributes.ObliquenessAttribute

        public let expansion: AttributeScopes.MopixAttributes.ExpansionAttribute

        public let toolTip: AttributeScopes.MopixAttributes.ToolTipAttribute

        public let markedClauseSegment: AttributeScopes.MopixAttributes.MarkedClauseSegmentAttribute

        public let superscript: AttributeScopes.MopixAttributes.SuperscriptAttribute

        public let textAlternatives: AttributeScopes.MopixAttributes.TextAlternativesAttribute

        ////public let glyphInfo: AttributeScopes.MopixAttributes.GlyphInfoAttribute

        public let cursor: AttributeScopes.MopixAttributes.CursorAttribute

        public typealias DecodingConfiguration = AttributeScopeCodableConfiguration

        public typealias EncodingConfiguration = AttributeScopeCodableConfiguration
    }
}

public extension AttributeDynamicLookup {
    subscript<T: AttributedStringKey>(dynamicMember keyPath: KeyPath<AttributeScopes.MopixAttributes, T>) -> T {
        return self[T.self]
    }
}

public enum LineBreak : Hashable, Codable {
    case soft
    case hard
}

//Why seperate.. idk
extension AttributeScopes.MopixAttributes {
    @frozen public enum FontAttribute : CodableAttributedStringKey {
        public typealias Value = FontDesc
        public static let name: String = "FontAttribute"
        /*
         Matrix - to modify the font?
         Attributes
         pointSize
         postscriptName
         symbolicTraits
         //Apple traits noted in FontDesc
         */
        //public static func value(for object: NSObject) throws -> URL
    }
    
    @frozen public enum LineBreakAttribute : CodableAttributedStringKey {
        public typealias Value = LineBreak
        public static let name: String = "LineBreakAttribute"
    }
    
    /*
     var alignment: NSTextAlignment
     The text alignment of the paragraph.
     enum NSTextAlignment
     Constants that specify text alignment.
     var firstLineHeadIndent: CGFloat
     The indentation of the first line of the paragraph.
     var headIndent: CGFloat
     The indentation of the paragraph’s lines other than the first.
     var tailIndent: CGFloat
     The trailing indentation of the paragraph.
     var lineHeightMultiple: CGFloat
     The line height multiple.
     var maximumLineHeight: CGFloat
     The paragraph’s maximum line height.
     var minimumLineHeight: CGFloat
     The paragraph’s minimum line height.
     var lineSpacing: CGFloat
     The distance in points between the bottom of one line fragment and the top of the next.
     var paragraphSpacing: CGFloat
     Distance between the bottom of this paragraph and top of next.
     var paragraphSpacingBefore: CGFloat
     The distance between the paragraph’s top and the beginning of its text content.
     */
    @frozen public enum ParagraphStyleAttribute : CodableAttributedStringKey {
        public typealias Value = String
        public static let name: String = "ParagraphStyleAttribute"
    }
    
    @frozen public enum ForegroundColorAttribute : CodableAttributedStringKey {
        public typealias Value = UInt32
        public static let name: String = "ForegroundColorAttribute"
    }
    
    @frozen public enum ForegroundColorLabelAttribute : CodableAttributedStringKey {
        public typealias Value = String
        public static let name: String = "ForegroundColorLabelAttribute"
    }
    
    @frozen public enum BackgroundColorAttribute : CodableAttributedStringKey {
        public typealias Value = UInt32
        public static let name: String = "BackgroundColorAttribute"
    }
    
    @frozen public enum BackgroundColorLabelAttribute : CodableAttributedStringKey {
        public typealias Value = String
        public static let name: String = "BackgroundColorLabelAttribute"
    }
    
    @frozen public enum LigatureAttribute : CodableAttributedStringKey {
        public typealias Value = Int
        public static let name: String = "LigatureAttribute"
        //The value 0 indicates no ligatures. The value 1 indicates the use of the default ligatures. The value 2 indicates the use of all ligatures. The default value for this attribute is 1. (Value 2 is unsupported on iOS.)
        //iOS will automatically render certain combinations of characters as a ligature.. this attr gives more control
    }
    
    @frozen public enum KernAttribute : CodableAttributedStringKey {
        public typealias Value = Float //Number of points (not pixels)
        public static let name: String = "KernAttribute"
    }
    
    @frozen public enum TrackingAttribute : CodableAttributedStringKey {
        public typealias Value = Float //Number of points (not pixels)
        public static let name: String = "TrackingAttribute"
    }
    
    @frozen public enum StrikethroughStyleAttribute : CodableAttributedStringKey {
        public typealias Value = UnderlineStyle
        public static let name: String = "StrikethroughStyleAttribute"
    }
    
    @frozen public enum UnderlineStyleAttribute : CodableAttributedStringKey {
        public typealias Value = UnderlineStyle
        public static let name: String = "UnderlineStyleAttribute"
    }
    
    @frozen public enum StrokeColorAttribute : CodableAttributedStringKey {
        public typealias Value = UInt32
        public static let name: String = "StrokeColorAttribute"
    }
    
    @frozen public enum StrokeWidthAttribute : CodableAttributedStringKey {
        public typealias Value = Float
        public static let name: String = "StrokeWidthAttribute"
    }
    
    @frozen public enum ShadowAttribute : CodableAttributedStringKey {
        public typealias Value = Shadow
        public static let name: String = "ShadowAttribute"
    }
    
    /* Used for the Letterpress effect
    @frozen public enum TextEffectAttribute : CodableAttributedStringKey {
        public typealias Value = String
        public static let name: String = "TextEffectAttribute"
    }*/
    
    @frozen public enum AttachmentAttribute : CodableAttributedStringKey {
        public typealias Value = DataAttachment
        public static let name: String = "AttachmentAttribute"
    }
    
    @frozen public enum BaselineOffsetAttribute : CodableAttributedStringKey {
        public typealias Value = String
        public static let name: String = "BaselineOffsetAttribute"
    }
    
    @frozen public enum UnderlineColorAttribute : CodableAttributedStringKey {
        public typealias Value = UInt32
        public static let name: String = "UnderlineColorAttribute"
    }
    
    @frozen public enum StrikethroughColorAttribute : CodableAttributedStringKey {
        public typealias Value = UInt32
        public static let name: String = "StrikethroughColorAttribute"
    }
    
    @frozen public enum ObliquenessAttribute : CodableAttributedStringKey {
        public typealias Value = Float
        public static let name: String = "ObliquenessAttribute"
    }
    
    @frozen public enum ExpansionAttribute : CodableAttributedStringKey {
        public typealias Value = Float
        public static let name: String = "ExpansionAttribute"
    }
    
    @frozen public enum ToolTipAttribute : CodableAttributedStringKey {
        public typealias Value = String
        public static let name: String = "ToolTipAttribute"
    }
    
    @frozen public enum MarkedClauseSegmentAttribute : CodableAttributedStringKey {
        public typealias Value = Int
        public static let name: String = "MarkedClauseSegmentAttribute"
    }
    
    @frozen public enum SuperscriptAttribute : CodableAttributedStringKey {
        public typealias Value = Int
        public static let name: String = "SuperscriptAttribute"
    }
    
    @frozen public enum TextAlternativesAttribute : CodableAttributedStringKey {
        public typealias Value = String
        public static let name: String = "TextAlternativesAttribute"
    }
    
    /*???
    @frozen public enum GlyphInfoAttribute : CodableAttributedStringKey {
        public typealias Value = String
        public static let name: String = "GlyphInfoAttribute"
    }*/
    
    @frozen public enum CursorAttribute : CodableAttributedStringKey {
        public typealias Value = String
        public static let name: String = "CursorAttribute"
    }
}

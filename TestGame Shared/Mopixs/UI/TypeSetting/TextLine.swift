
import Foundation
//
//  TextLine.swift
//  TestGame
//
//  Created by Isaac Paul on 10/19/22.
//

import ICU
import SDL2
import SDL2_ttf

struct SpaceInfo {
    var count:Int
    var width:Int
    
    static let zero = SpaceInfo(count: 0, width: 0)
    
    mutating func increment(_ width:Int) {
        count += 1
        self.width += width
    }
}

struct StringWidth {
    init(start: SpaceInfo, end: SpaceInfo, width: Int) {
        self.start = start
        self.end = end
        self.width = width
    }
    
    let start:SpaceInfo
    let end:SpaceInfo
    let width:Int
    
    static let zero = StringWidth(start: SpaceInfo.zero, end: SpaceInfo.zero, width: 0)
    
    init(width:Int) {
        start = SpaceInfo.zero
        end = SpaceInfo.zero
        self.width = width
    }
    
    func appending(_ other:StringWidth) -> StringWidth {
        return StringWidth(start: start, end: other.end, width: width + other.width)
    }
}

//Character spacing == tracking
struct CharacterMetrics {
    var width:Int
    var advance:Int
    
    static let zero = CharacterMetrics(width: 0, advance: 0)
    
    func copyTo(_ other: inout CharacterMetrics) {
        other.width = width
        other.advance = advance
    }
}


struct TextLine {
    internal init(str: Substring, height: Int, widthInfo: StringWidth) {
        self.str = str
        self.height = height
        self.widthInfo = widthInfo
    }
    
    internal init(str: Substring, height: Int, width: Int) {
        self.str = str
        self.height = height
        self.widthInfo = StringWidth(width: width)
    }
    
    let str:Substring
    let height:Int
    //let startIndex:Int //Cache to avoid walking string to get equivalent index
    let widthInfo:StringWidth
    
    func append(endIndex:String.Index, endWidthInfo:StringWidth) -> TextLine {
        let info = StringWidth(start: widthInfo.start, end: endWidthInfo.end, width: widthInfo.width + endWidthInfo.width)//, metrics: widthInfo.metrics + endWidthInfo.metrics)
        return TextLine(str: str[str.startIndex..<endIndex], height: height, widthInfo: info)
    }
    
    func strTrimmingEndSpace() -> Substring {
        let offset = str.index(str.endIndex, offsetBy: -widthInfo.end.count)
        let newStr = str[str.startIndex..<offset]
        return newStr
    }
    
    func widthTrimmingEndSpace() -> Int {
        return widthInfo.width - widthInfo.end.width
    }
    
    func strTrimmingSpace() -> Substring {
        let startOffset = str.index(str.startIndex, offsetBy: widthInfo.start.count)
        let offset = str.index(str.endIndex, offsetBy: -widthInfo.end.count)
        let newStr = str[startOffset..<offset]
        return newStr
    }
    
    func widthTrimmingSpace() -> Int {
        return widthInfo.width - widthInfo.start.width - widthInfo.end.width
    }
    /*
    func indexOfPosition(_ xPos:Int) -> Int {
        var curPos = 0
        var index = 0
        for cInfo in widthInfo.metrics {
            curPos += cInfo.advance
            let outerSpace = (cInfo.advance - cInfo.width)
            let centerOfGlyph = curPos - outerSpace - (cInfo.width / 2)
            if (xPos < centerOfGlyph) {
                return index
            }
            index += 1
        }
        return index
    }
    
    func indexOfPositionInTrim(_ xPos:Int) -> Int {
        var curPos = 0
        var index = 0
        for cInfo in widthInfo.metrics[widthInfo.start.count..<widthInfo.metrics.count-widthInfo.end.count] {
            curPos += cInfo.advance
            let outerSpace = (cInfo.advance - cInfo.width)
            let centerOfGlyph = curPos - outerSpace - (cInfo.width / 2)
            if (xPos < centerOfGlyph) {
                return index
            }
            index += 1
        }
        return index
    }*/
}

public struct TextLine2 {
    internal init(str: [RenderableCharacter], height: Int, widthInfo: StringWidth) {
        self.characters = str
        self.maxHeight = height
        self.widthInfo = widthInfo
    }
    
    internal init(str: [RenderableCharacter], height: Int, width: Int) {
        self.characters = str
        self.maxHeight = height
        self.widthInfo = StringWidth(width: width)
    }
    
    internal init(segment: Segment) {
        self.characters = segment.characters
        self.maxHeight = segment.height
        self.widthInfo = segment.widthInfo
    }
    
    let characters:[RenderableCharacter]
    let maxHeight:Int
    let baseLinePos:Int = 0
    let widthInfo:StringWidth
    
    func appending(segment:Segment) -> TextLine2 {
        let newLineWidth = self.widthInfo.appending(segment.widthInfo)
        var height = maxHeight
        if (height < segment.height) {
            height = segment.height
        }
        let combined = characters + segment.characters
        return TextLine2(str: combined, height: height, widthInfo: newLineWidth)
    }
    
    func strTrimmingEndSpace() -> ArraySlice<RenderableCharacter> {
        let offset = characters.index(characters.endIndex, offsetBy: -widthInfo.end.count)
        let newStr = characters[characters.startIndex..<offset]
        return newStr
    }
    
    func widthTrimmingEndSpace() -> Int {
        return widthInfo.width - widthInfo.end.width
    }
    
    func strTrimmingSpace() -> ArraySlice<RenderableCharacter> {
        let startOffset = characters.index(characters.startIndex, offsetBy: widthInfo.start.count)
        let offset = characters.index(characters.endIndex, offsetBy: -widthInfo.end.count)
        let newStr = characters[startOffset..<offset]
        return newStr
    }
    
    func widthTrimmingSpace() -> Int {
        return widthInfo.width - widthInfo.start.width - widthInfo.end.width
    }
}

/*
 let link: AttributeScopes.FoundationAttributes.LinkAttribute

 public let morphology: AttributeScopes.FoundationAttributes.MorphologyAttribute
 GrammaticalGender, PartOfSpeech, GrammaticalNumber

 public let inflect: AttributeScopes.FoundationAttributes.InflectionRuleAttribute
 InflectionRule: Automatic, specific
 
 public let languageIdentifier: AttributeScopes.FoundationAttributes.LanguageIdentifierAttribute
 String
 
 public let personNameComponent: AttributeScopes.FoundationAttributes.PersonNameComponentAttribute
 givenName, familyname, etc
 
 public let numberFormat: AttributeScopes.FoundationAttributes.NumberFormatAttributes
 numberSymbol, numberPart
 
 public let dateField: AttributeScopes.FoundationAttributes.DateFieldAttribute
 era, year, etc
 
 public let inlinePresentationIntent: AttributeScopes.FoundationAttributes.InlinePresentationIntentAttribute
 below
 
 public let presentationIntent: AttributeScopes.FoundationAttributes.PresentationIntentAttribute
 List of: paragraph header(level: Int) orderedList unorderedList listItem(ordinal: Int) codeBlock(languageHint: String?) blockQuote thematicBreak table(columns: [PresentationIntent.TableColumn]) tableHeaderRow tableRow(rowIndex: Int) tableCell(columnIndex: Int)
 
 public let alternateDescription: AttributeScopes.FoundationAttributes.AlternateDescriptionAttribute
 string
 
 public let imageURL: AttributeScopes.FoundationAttributes.ImageURLAttribute
 Url
 
 public let replacementIndex: AttributeScopes.FoundationAttributes.ReplacementIndexAttribute
 Int... ??
 
 public let measurement: AttributeScopes.FoundationAttributes.MeasurementAttribute
 value, unit
 
 public let inflectionAlternative: AttributeScopes.FoundationAttributes.InflectionAlternativeAttribute
 Attributed string
 
 public let byteCount: AttributeScopes.FoundationAttributes.ByteCountAttribute
 case value
 case spelledOutValue
 case unit(AttributeScopes.FoundationAttributes.ByteCountAttribute.Unit)
 case actualByteCount
}
 */

/*
 * font
 *        public let foregroundColor: AttributeScopes.MopixAttributes.ForegroundColorAttribute
 
 public let backgroundColor: AttributeScopes.MopixAttributes.BackgroundColorAttribute

 public let ligature: AttributeScopes.MopixAttributes.LigatureAttribute

 public let kern: AttributeScopes.MopixAttributes.KernAttribute //Individual spacing

 public let tracking: AttributeScopes.MopixAttributes.TrackingAttribute //spacing over range of characters

 public let strikethroughStyle: AttributeScopes.MopixAttributes.StrikethroughStyleAttribute

 public let underlineStyle: AttributeScopes.MopixAttributes.UnderlineStyleAttribute

 public let strokeColor: AttributeScopes.MopixAttributes.StrokeColorAttribute

 public let strokeWidth: AttributeScopes.MopixAttributes.StrokeWidthAttribute
 public let shadow: AttributeScopes.MopixAttributes.ShadowAttribute
 */

public struct TextContext {
    let font:FontDesc
    let foregroundColor:LabeledColor
    let backgroundColor:LabeledColor?
    let kern:Float
    let tracking:Float
    let image:Image?
}

extension LabeledColor {
    static func from(_ value:UInt32?) -> LabeledColor? {
        guard let value = value else { return nil }
        return LabeledColor(integerLiteral: value)
    }
}

extension TextContext {
    func absorbAttributes(_ attributes:ScopedAttributeContainer<AttributeScopes.MopixAttributes>) -> TextContext {
        let font = attributes.font ?? self.font
        let foregroundColor = LabeledColor.from(attributes.foregroundColor) ?? self.foregroundColor
        let backgroundColor = LabeledColor.from(attributes.backgroundColor) ?? self.backgroundColor
        let kern = attributes.kern ?? 0
        let tracking = attributes.tracking ?? 0
        return TextContext(font: font, foregroundColor: foregroundColor, backgroundColor: backgroundColor, kern: kern, tracking: tracking, image: nil)
    }
}

public struct RenderableCharacter {
    let img:Image? //Empty for whitespace
    let size:Size<Int>
    let baseLine:Int
    let foreground:LabeledColor
    let background:LabeledColor?
    //let isWhitespace:Bool
    let lineBreak:LineBreak?
}

//https://developer.apple.com/documentation/foundation/nsattributedstring/key/1533563-foregroundcolor
/*
 Do we have segments?
 or do we have an array of each char?
 */
extension LineBreakCursor {
    func isHardBreak() -> Bool {
        if case .hard = self.ruleStatus {
            return true
        }
        return false
    }
}

/*
struct MultiSourceIterator: IteratorProtocol {
 
    typealias Element = (AttributedString.Runs.Run, Character)
    let source:AttributedString.Runs.Iterator
    var currentIt:IndexingIterator<Slice<AttributedString.CharacterView>>? = nil
    
    init() {
        //self.source = source

    }
    
    mutating func next() -> (AttributedString.Runs.Run, Character)? {
        
        let sourceToUse = currentItem ?? source.next()
    }
}*/

struct CharacterInfo {
    let character:Character
    let context:TextContext
    let lineBreak:LineBreak?
}

struct CharacterIterator : IteratorProtocol {
    let str:AttributedString
    let allCharacters:String
    var position:Int?
    var positionIndex:String.Index?
    let textContext:TextContext
    var lineCursor:LineBreakCursor
    
    var runs:AttributedString.Runs.Iterator
    
    init(str: AttributedString, context:TextContext) {
        self.str = str
        self.textContext = context
        allCharacters = String(str.characters[...]) //https://forums.swift.org/t/attributedstring-to-string/61667
        
        lineCursor = LineBreakCursor(text: allCharacters)
        position = 0
        positionIndex = lineCursor.first()
        
        // We can turn the below into an iterator to clean up some code
        if let nextLineBreak = lineCursor.next(), let positionIndexLive = positionIndex {
            position! += allCharacters.distance(from: positionIndexLive, to: nextLineBreak)
            positionIndex = nextLineBreak
        } else {
            position = nil
            positionIndex = nil
        }
        
        runs = str.runs.makeIterator()
    }
    
    mutating func next() -> RenderableCharacter? {
        return nil
    }
}

struct CurrentRunContext {
    var run:AttributedString.Runs.Run
    var characterIterator:IndexingIterator<Slice<AttributedString.CharacterView>>
    var font:Font
    var textContext:TextContext
}


struct Step2Context {
    var currentRun:CurrentRunContext
    var character:Character
    var lineBreak:LineBreak?
}
/*
struct RenderableIterator : IteratorProtocol {
    typealias Element = RenderableCharacter
    
    let str:AttributedString
    let allCharacters:String
    let renderContext:UIRenderContext
    let textContext:TextContext
    var lineCursor:LineBreakCursor
    var position:Int?
    var positionIndex:String.Index?
    var runs:AttributedString.Runs.Iterator
    var currentRunContext:CurrentRunContext? = nil
    

    
    var error:Error? = nil
    
    init(str: AttributedString, renderContext:UIRenderContext, context:TextContext) {
        self.str = str
        self.renderContext = renderContext
        self.textContext = context
        allCharacters = String(str.characters[...]) //https://forums.swift.org/t/attributedstring-to-string/61667
        
        lineCursor = LineBreakCursor(text: allCharacters)
        position = 0
        positionIndex = lineCursor.first()
        
        // We can turn the below into an iterator to clean up some code
        if let nextLineBreak = lineCursor.next(), let positionIndexLive = positionIndex {
            position! += allCharacters.distance(from: positionIndexLive, to: nextLineBreak)
            positionIndex = nextLineBreak
        } else {
            position = nil
            positionIndex = nil
        }
        
        var hardBreak = lineCursor.isHardBreak()
        var currentPos = 0
        runs = str.runs.makeIterator()
    }
    
    func rethrowAnyErrors() throws {
        if let error = error {
            throw error
        }
    }
    
    mutating func next() -> RenderableCharacter? {
        
        guard var context = currentRunContext ?? fetchNextRun() else {
            return nil
        }
        let character:Character
        if let nextChar = context.characterIterator.next() {
            character = nextChar
        } else {
            var fetchedCharacter:Character? = nil
            while let nextContext = fetchNextRun() {
                if let nextChar = context.characterIterator.next() {
                    fetchedCharacter = nextChar
                    context = nextContext
                    break
                }
            }
            if let fetchedCharacter = fetchedCharacter {
                character = fetchedCharacter
            } else {
                return nil
            }
        }
        
        let height = context.font._font.height()
        
        //walking str might be cheaper
        var characterMetrics:[RenderableCharacter] = []
        var canLineBreak = false //Gotta ignore skipped whitespace too
        if let livePosition = position, let positionIndexLive = positionIndex {
            let isLineBreak = currentPos == livePosition
            canLineBreak = isLineBreak
            if let nextLineBreak = lineCursor.next() {
                position = livePosition + allCharacters.distance(from: positionIndexLive, to: nextLineBreak)
                positionIndex = nextLineBreak
                hardBreak = lineCursor.isHardBreak()
            } else {
                position = nil
                positionIndex = nil
            }
        }
        let metrics = try font._font.glyphMetrics(c: c)
        let thisWidth = metrics.advance + Int(overwrittenContext.kern) + Int(overwrittenContext.tracking)
        width += thisWidth
        let cSize = Size<Int>(thisWidth, metrics.frame.height)
        if (c.isWhitespace) {
            let rc = RenderableCharacter(img: nil, size: cSize, baseLine: 0)
        } else {
            let image = try font.glyph(c)
            let rc = RenderableCharacter(img: image, size: cSize, baseLine: font._font.descent())
        }
    }
    
    mutating func fetchNextRun() -> CurrentRunContext? {
        guard let next = runs.next() else { return nil }
        let runRange = next.range
        let currentCharacterIterator = str.characters[runRange].makeIterator()
        let overwrittenContext = textContext.absorbAttributes(next.mopix)
        let currentFont:Font
        do {
            currentFont = try renderContext.fetchFont(overwrittenContext.font)
        } catch {
            self.error = error
            return nil
        }
        
        return CurrentRunContext(run: next, characterIterator: currentCharacterIterator, font: currentFont, textContext: overwrittenContext)
    }
}*/

struct CharacterPos {
    let c:Character
    let pos:String.Index
}

struct Segment {
    let characters:[RenderableCharacter]
    let widthInfo:StringWidth
    let height:Int
    let hardbreak:Bool
}

//TODO: Rename; this checks in a moving forward direction only
struct LineBreakChecker {
    let source:String
    var position:Int? = 0
    var positionIndex:String.Index?
    var lineCursor:LineBreakCursor
    
    init(_ str:String) {
        source = str
        lineCursor = LineBreakCursor(text: str) //Pricy: .486ms
        positionIndex = lineCursor.first()
        // We can turn the below into an iterator to clean up some code
        if let nextLineBreak = lineCursor.next(), let positionIndexLive = positionIndex {
            position! += str.distance(from: positionIndexLive, to: nextLineBreak)
            positionIndex = nextLineBreak
        } else {
            position = nil
            positionIndex = nil
        }
    }
    
    mutating func lineBreakForPos(_ currentPos:Int) -> LineBreak? {
        guard
            let position = position,
            let positionIndex = positionIndex else {
            return nil
        }
        while (position < currentPos) {
            guard let nextLineBreak = lineCursor.next() else {
                self.position = nil
                self.positionIndex = nil
                return nil
            }
            self.position = position + source.distance(from: positionIndex, to: nextLineBreak)
            self.positionIndex = nextLineBreak
        }
        let isLineBreak = position == currentPos
        if (isLineBreak == false) { return nil }
        let lineBreak:LineBreak = lineCursor.isHardBreak() ? .hard : .soft
        return lineBreak
    }
}

protocol IteratorInnerProtocol : IteratorProtocol {
    
    associatedtype InnerElement
    mutating func nextInner() -> Self.InnerElement?
}

protocol ThrowingIteratorProtocol : IteratorProtocol where Element == Result<InnerElement, Error> {
    
    associatedtype InnerElement
    mutating func nextInner() throws -> Self.InnerElement?
    var measureName:String { get }
}

extension ThrowingIteratorProtocol {
    mutating func next() -> Self.Element? {
        do {
            let stats = Application._shared.stats
            
            //var time = CFAbsoluteTimeGetCurrent()
            let result = try self.nextInner()
            //var elapsed = CFAbsoluteTimeGetCurrent() - time
            //stats.insertSample(measureName, elapsed)
            if let result = result {
                return .success(result)
            }
            return nil
        } catch {
            return .failure(error)
        }
    }
}

struct RunIterator : ThrowingIteratorProtocol {
    var measureName: String {
        get { return "step1" }
    }
    
    mutating func nextInner() throws -> CurrentRunContext? {
        guard let run = runIterator.next() else { return nil }
        let characters = str.characters[run.range]
        let overwrittenContext = textContext.absorbAttributes(run.mopix)
        
        let font:Font = try renderContext.fetchFont(overwrittenContext.font)
        return CurrentRunContext(run: run, characterIterator: characters.makeIterator(), font: font, textContext: overwrittenContext)
    }
    
    typealias Element = Result<CurrentRunContext, Error>
    
    let str:AttributedString
    var runIterator:IndexingIterator<AttributedString.Runs>
    let renderContext:UIRenderContext
    let textContext:TextContext
}

struct Step2ContextIterator : ThrowingIteratorProtocol {
    var measureName: String {
        get { return "step2" }
    }
    
    mutating func nextInner() throws -> Step2Context? {
        if currentRun != nil, let character = currentRun!.characterIterator.next()  {
            currentPos += 1
            let lineBreakInfo = lineBreakChecker.lineBreakForPos(currentPos)
            return Step2Context(currentRun: currentRun!, character: character, lineBreak: lineBreakInfo)
        }
        
        while let step1Result = step1.next() {
            let step1Item = try step1Result.get()
            currentRun = step1Item
            guard let character = currentRun!.characterIterator.next() else {
                continue
            }
            currentPos += 1
            let lineBreakInfo = lineBreakChecker.lineBreakForPos(currentPos)
            return Step2Context(currentRun: currentRun!, character: character, lineBreak: lineBreakInfo)
            
        }
        return nil
    }
    
    typealias Element = Result<Step2Context, Error>
    
    var currentRun:CurrentRunContext?
    var lineBreakChecker:LineBreakChecker
    var currentPos = 0
    var step1:RunIterator
}

struct RenderableCharacterIterator : ThrowingIteratorProtocol {
    var measureName: String {
        get { return "step3" }
    }
    
    mutating func nextInner() throws -> RenderableCharacter? {
        guard let step2Result = step2.next() else { return nil }
        let step2Item = try step2Result.get()
        let c = step2Item.character
        let context = step2Item.currentRun.textContext
        let font:Font = step2Item.currentRun.font
        let metrics:SDLFont.GlyphMetrics = try font._font.glyphMetrics(c: c)
        
        let thisWidth = metrics.advance + Int(context.kern) + Int(context.tracking)
        let internalFont = font._font
        let cSize = Size<Int>(thisWidth, internalFont.height()) //TODO: Characters are rendered into textures the size of the font height.. we could optimize this?
        if (c.isWhitespace) {
            return RenderableCharacter(img: nil, size: cSize, baseLine: 0, foreground: context.foregroundColor, background: context.backgroundColor, lineBreak: nil)
        }
        
        let image:Image = try font.glyph(c)
        //assert(cSize.height == image.texture.sourceRect.height, "\(cSize.height) == \(image.texture.sourceRect.height)")
        return RenderableCharacter(img: image, size: cSize, baseLine: font._font.descent(), foreground: context.foregroundColor, background: context.backgroundColor, lineBreak: nil)
    }
    
    typealias Element = Result<RenderableCharacter, Error>
    var step2:Step2ContextIterator
}

struct SegmentIterator : ThrowingIteratorProtocol {
    var measureName: String {
        get { return "step4" }
    }
    
    mutating func nextInner() throws -> Segment? {
        var height:Int = 0
        var width:Int = 0
        var atStart = true
        var hardbreak = false
        var start = SpaceInfo.zero
        var end = SpaceInfo.zero
        listStep4.removeAll(keepingCapacity: true)
        while let nextResult = step3.next() {
            let next = try nextResult.get()
            listStep4.append(next)
            width += next.size.width
            if (height < next.size.height) {
                height = next.size.height
            }
            let isWhiteSpace = next.img == nil
            if (isWhiteSpace) {
                if (atStart) {
                    start.increment(next.size.width)
                } else {
                    end.increment(next.size.width)
                }
            } else {
                atStart = false
                end = SpaceInfo.zero
            }
            if (next.lineBreak == .hard) {
                hardbreak = true
            }
            if (next.lineBreak != nil) {
                break
            }
        }
        if (listStep4.count == 0) {
            return nil
        }
        let strWidth = StringWidth(start: start, end: end, width: width)
        
        return Segment(characters: listStep4, widthInfo: strWidth, height: height, hardbreak: hardbreak)
    }
    
    typealias Element = Result<Segment, Error>
    var step3:RenderableCharacterIterator
    var listStep4:[RenderableCharacter]
}

struct LineIterator : ThrowingIteratorProtocol {
    var measureName: String {
        get { return "step5" }
    }
    
    mutating func nextInner() throws -> TextLine2? {
        guard let maxWidthPxs = maxWidthPxs else {
            list.removeAll(keepingCapacity: true)
            
            //TODO: Make builder
            var width:Int = 0
            var height:Int = 0
            var atStart = true
            var start = SpaceInfo.zero
            var end = SpaceInfo.zero
            while let nextResult = step3.next() {
                let next = try nextResult.get()
                list.append(next)
                width += next.size.width
                if (height < next.size.height) {
                    height = next.size.height
                }
                let isWhiteSpace = next.img == nil
                if (isWhiteSpace) {
                    if (atStart) {
                        start.increment(next.size.width)
                    } else {
                        end.increment(next.size.width)
                    }
                } else {
                    atStart = false
                    end = SpaceInfo.zero
                }
            }
            if (list.count == 0) { return nil }
            let strWidth = StringWidth(start: start, end: end, width: width)
            let copy = list
            return TextLine2(str: copy, height: height, widthInfo: strWidth)
        }
        
        let line:TextLine2
        
        if let lastLine = lastLine {
            line = lastLine
        } else {
            if let segment = try step4.next()?.get() {
                line = TextLine2(segment: segment)
            } else {
                return nil
            }
        }
        
        
        while let nextLineResult = step4.next() {
            let nextLine = try nextLineResult.get()
            let segmentDoesntFit = line.widthInfo.width + nextLine.widthInfo.width > maxWidthPxs
            if (segmentDoesntFit) {
                let newLine = TextLine2(segment: nextLine)
                lastLine = newLine
                return line
            } else {
                let combinedLine = line.appending(segment: nextLine)
                if (nextLine.hardbreak) {
                    lastLine = nil
                    return lastLine
                }
                lastLine = combinedLine
            }
        }
        let finalLine = line
        lastLine = nil
        return finalLine
    }
    
    typealias Element = Result<TextLine2, Error>
    var step3:RenderableCharacterIterator
    var step4:SegmentIterator
    var list:[RenderableCharacter]
    let maxWidthPxs:Int?
    var lastLine:TextLine2? = nil
}

//Saves a chunk of time
fileprivate let cacheSize = 64
fileprivate var slist:[RenderableCharacter] = Array(count: cacheSize, element: RenderableCharacter(img: nil, size: Size(0, 0), baseLine: 0, foreground: LabeledColor.black, background: nil, lineBreak: nil))
fileprivate var slistStep4:[RenderableCharacter] = Array(count: cacheSize, element: RenderableCharacter(img: nil, size: Size(0, 0), baseLine: 0, foreground: LabeledColor.black, background: nil, lineBreak: nil))
fileprivate let maxLines = 99
fileprivate let empty:[RenderableCharacter] = []
fileprivate var slines:[TextLine2] = Array(count: maxLines, element: TextLine2(str: empty, height: 0, width: 0))


extension TextLine2 {
    //Can make faster with:
    // * Build my own linebreak checker
    // * Build my own attributed string
    // - - The issue is we have to run through iterators in sync:
    //     Line Break
    //     Attributed String - No way to transfer indexes between attr str and str
    //

    /*
     Adding Result type and moving functions into a generic `measuredIt` added about a 0.150-1ms
     Stats:
     avg     worst   fastest last
     0.687ms 2.189ms 0.449ms 0.602ms - build draw thing
     0.118ms 0.359ms 0.045ms 0.080ms - step0 - 0 - initialize vars
     0.008ms 0.087ms 0.002ms 0.005ms - step0 - 1 - initialize steps
     0.006ms 0.138ms 0.000ms 0.001ms - step1
     0.003ms 0.219ms 0.001ms 0.003ms - step2
     0.008ms 0.441ms 0.002ms 0.005ms - step3
     0.113ms 1.200ms 0.003ms 0.008ms - step4
     0.158ms 1.900ms 0.005ms 0.009ms - step5
     0.245ms 1.923ms 0.008ms 0.011ms - stepLast - build lines
     */
    
    static func buildFrom(_ str:AttributedString, renderContext:UIRenderContext, context:TextContext, maxWidthPxs:Int? = nil) throws -> [TextLine2] {
        
        var i = 0
        var lineIterator = try buildLineIterator(str, renderContext: renderContext, context: context, maxWidthPxs: maxWidthPxs)
        var lines = slines
        lines.removeAll(keepingCapacity: true)
        
        try Application._shared.stats.measure("stepLast - build lines"){
            while let eachLineResult = lineIterator.next() {
                let eachLine = try eachLineResult.get()
                lines.append(eachLine)
                i += 1
                if (i > maxLines) {
                    break
                }
            }
        }
        
        let linesCopy = lines
        lines.removeAll(keepingCapacity: true)
        return linesCopy
    }
    
    static func buildLineIterator(_ str:AttributedString, renderContext:UIRenderContext, context:TextContext, maxWidthPxs:Int? = nil) throws -> LineIterator {
        
        let stats = Application._shared.stats
        var time = CFAbsoluteTimeGetCurrent()
        let allCharacters = String(str.characters[...]) //https://forums.swift.org/t/attributedstring-to-string/61667
        
        //var currentPos = 0
        var lineBreakChecker = LineBreakChecker(allCharacters) //TODO: Relatively heavy
        var runIterator:IndexingIterator<AttributedString.Runs> = str.runs.makeIterator()
        
        var list:[RenderableCharacter] = slist
        var listStep4:[RenderableCharacter] = slistStep4
        //var lines:[TextLine2] = slines
        
        listStep4.removeAll(keepingCapacity: true)
        list.removeAll(keepingCapacity: true)
        //lines.removeAll(keepingCapacity: true)

        var elapsed = CFAbsoluteTimeGetCurrent() - time
        stats.insertSample("step0 - 0 - initialize vars", elapsed)
        time = CFAbsoluteTimeGetCurrent()
        
        var step1 = RunIterator(str: str, runIterator: runIterator, renderContext: renderContext, textContext: context)
        var step2 = Step2ContextIterator(lineBreakChecker: lineBreakChecker, step1: step1)
        var step3 = RenderableCharacterIterator(step2: step2)
        let step4 = SegmentIterator(step3: step3, listStep4: listStep4)
        let step5 = LineIterator(step3: step3, step4: step4, list: list, maxWidthPxs: maxWidthPxs)
        
        elapsed = CFAbsoluteTimeGetCurrent() - time
        stats.insertSample("step0 - 1 - initialize steps", elapsed)
        
        return step5
    }
}

public func valueOrDefault<T>(value:T?, body:()->(T?)) -> T? {
    return value ?? body()
}
/*
 if let textStyle = run.inlinePresentationIntent {
     /*
      public static var emphasized: InlinePresentationIntent { get }
      public static var stronglyEmphasized: InlinePresentationIntent { get }
      public static var code: InlinePresentationIntent { get }
      public static var strikethrough: InlinePresentationIntent { get }
      public static var softBreak: InlinePresentationIntent { get }
      public static var lineBreak: InlinePresentationIntent { get }
      public static var inlineHTML: InlinePresentationIntent { get }
      public static var blockHTML: InlinePresentationIntent { get }
      */

     // 6
     if textStyle.contains(.stronglyEmphasized) {
       print("Text is Bold")
     }
     if textStyle.contains(.emphasized) {
       print("Text is Italic")
     }
   // 7
   } else {
     print("Text is Regular")
   }
 */

func splitIntoLines(_ font:SDLFont, _ text:String, maxWidthPxs:Int) throws -> [TextLine] {
    var lines:[TextLine] = []
    var width:Int = 0
    var count:Int = 0
    var start:Int = 0
    let height = font.height()
    for (i, c) in text.enumerated() {
        do {
            let metrics = try font.glyphMetrics(c: c)
            if (width + metrics.advance > maxWidthPxs) {
                let line = TextLine(str: text[start...i], height: height, width: width)
                lines.append(line)
                start = i
                width = 0
                count = 0
            }
            width += metrics.advance
            count += 1
        } catch {
            print("Error couldn't measure character '\(c)': \(error.localizedDescription)")
        }
    }
    if (count > 0) {
        let line = TextLine(str: text[start...start + count], height: height, width: width)
        lines.append(line)
    }
    return lines
}

//Welcome to one of the ugliest functions in this code base
//Builds a list of lines used to layout text
//These lines will not include any initial whitespace unless:
//  - The previous line was ended with a line break
//  - It is the beginning of the line
//Overall mimicing behavior of uilabel from iOS
//Also does not include any whitespace at the end of the line
//Lines are broken up by word to fit inside maxWidthPxs
//They broken up even further by character if they still do not fit
//Line breaking is much more complex then I though: https://www.unicode.org/reports/tr14/
//
func splitIntoLinesWordWrapped(_ font:SDLFont, _ text:String, maxWidthPxs:Int, characterSpacing:Int) throws -> [TextLine] {
    var lines:[TextLine] = []
    //let charPos:[Int] = Array(repeating: 0, count: text.count)
    var width:Int = 0
    //let test:Character = "\u{0001e834}"
    var startIndex:String.Index = text.startIndex
    var lastWord:Substring? = nil
    var len = 0
    let height:Int = font.height()
    for eachWord in text.iterateWords() {
        var wordWidth:Int = 0
        var lastItemWasNewline = false
        var lastItemWasSkipped = false
        var spacesInCur = 0
        var spaceWidth = 0
        for c in eachWord {
            len += 1
            if (c == "\n") {
                if let lastWord2 = lastWord {
                    let line = TextLine(str: text[startIndex..<lastWord2.endIndex], height: height, width: width)
                    lines.append(line)
                    let dist = text.distance(from: startIndex, to: lastWord2.endIndex)
                    len -= dist
                    width = 0
                    startIndex = lastWord2.endIndex
                    lastWord = nil
                } else {
                    let endIndex = text.index(startIndex, offsetBy: len)
                    let line = TextLine(str: text[startIndex..<endIndex], height: height, width: width)
                    lines.append(line)
                    startIndex = eachWord.endIndex
                    len = 0
                    width = 0
                }
                lastItemWasNewline = true
                continue
            }
            if (!lastItemWasNewline && lastWord == nil && c.isWhitespace) {
                lastItemWasSkipped = true
                continue
            } else if (!lastItemWasNewline && c.isWhitespace) {
                spacesInCur += 1
            }
            lastItemWasNewline = false
            if lastItemWasSkipped {
                lastItemWasSkipped = false
                startIndex = text.index(startIndex, offsetBy: len - 1)
                len = 1
            }
            do {
                let metrics = try font.glyphMetrics(c: c)
                let nextWidth = wordWidth + metrics.advance + characterSpacing
                
                let wordDoesntFit = width + nextWidth > maxWidthPxs
                if (wordDoesntFit) {
                    if let lastWord2 = lastWord {
                        
                        let line = TextLine(str: text[startIndex..<lastWord2.endIndex], height: height, width: width)
                        lines.append(line)
                        let dist = text.distance(from: startIndex, to: lastWord2.endIndex) + 1
                        len -= dist
                        let index = text.index(lastWord2.endIndex, offsetBy: spacesInCur)
                        startIndex = index
                        width = 0
                        wordWidth = nextWidth - spaceWidth
                        lastWord = nil
                    } else {
                        
                        let endIndex = text.index(startIndex, offsetBy: len-1)
                        let line = TextLine(str: text[startIndex..<endIndex], height: height, width: wordWidth)
                        lines.append(line)
                        startIndex = endIndex
                        len = 1
                        width = 0
                        wordWidth = metrics.advance + characterSpacing
                    }
                } else {
                    wordWidth = nextWidth
                    if (c.isWhitespace) {
                        spaceWidth += metrics.advance + characterSpacing
                    }
                }
            } catch {
                print("Error couldn't measure character '\(c)': \(error.localizedDescription)")
            }
        }
        width += wordWidth
        lastWord = eachWord
    }
    if let lastWord = lastWord {
        let line = TextLine(str: text[startIndex..<lastWord.endIndex], height: height, width: width)
        lines.append(line)
    }
    return lines
}


//TODO:
//The ICU implementation is _heavy_. It requires a utf16 string while swift uses
//utf8 backed strings. When returning string indexes this means we have to convert
//index to the other.. which requires walking the string. I also suspect the wrapper framework
//does cache this utf16 portion while iterating the string

func splitIntoLinesWordWrapped2(_ font:SDLFont, _ text:String, maxWidthPxs:Int, characterSpacing:Int, maxLines:Int = 256) throws -> [TextLine] {
    var result:[TextLine] = []
    let height:Int = font.height()
    let lineCursor = LineBreakCursor(text: text)
    var previousLineBreak = lineCursor.first()
    var lastLine:TextLine? = nil
    var startIndex = 0
    //TODO: Note we are not handling hard breaks
    while let nextLineBreak = lineCursor.next() {
        
        let subStr = text[previousLineBreak..<nextLineBreak]
        let widthInfo = try analyzeStringMetrics(font, subStr, characterSpacing: characterSpacing)
        
        let width = widthInfo.width
        if let line = lastLine {
            let segmentDoesntFit = line.widthInfo.width + width > maxWidthPxs
            if (segmentDoesntFit) {
                result.append(line)
                lastLine = nil
                if (result.count >= maxLines) { break }
                let start = line.str.startIndex
                let newLine = TextLine(str: text[line.str.endIndex..<nextLineBreak], height: height, widthInfo: widthInfo)
                lastLine = newLine
            } else {
                lastLine = line.append(endIndex: nextLineBreak, endWidthInfo: widthInfo)
            }
        } else {
            let newLine = TextLine(str: subStr, height: height, widthInfo: widthInfo)
            lastLine = newLine
        }
        previousLineBreak = nextLineBreak
        //~startIndex += widthInfo.metrics.count
    }
    if let lastLine = lastLine {
        result.append(lastLine)
    }
   
    return result
}


func analyzeStringMetrics(_ font:SDLFont, _ str:Substring, characterSpacing:Int) throws -> StringWidth {
    var width = 0
    var atStart = true
    var start = SpaceInfo.zero
    var end = SpaceInfo.zero
    
    var i = 0
    let count = str.count //walking string but cheaper than reallocating an array
    var characterMetrics:[CharacterMetrics] = Array(repeating: CharacterMetrics.zero, count: count)
    for c in str {
        let metrics = try font.glyphMetrics(c: c)
        let thisWidth = metrics.advance + characterSpacing //TODO: We can squeeze more in a line if we check to fit without including this.
        width += thisWidth
        characterMetrics[i] = CharacterMetrics(width: metrics.frame.width, advance: metrics.advance)
        if (c.isWhitespace) {
            if (atStart) {
                start.increment(thisWidth)
            } else {
                end.increment(thisWidth)
            }
        } else {
            atStart = false
            end = SpaceInfo.zero
        }
        i+=1
    }
    return StringWidth(start: start, end: end, width: width)//, metrics: characterMetrics)
}

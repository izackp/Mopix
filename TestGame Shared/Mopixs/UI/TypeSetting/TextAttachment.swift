//
//  TextAttachment.swift
//  TestGame
//
//  Created by Isaac Paul on 10/31/22.
//


/* The apple implementation is just doing too much. Any line of text can be associated with data so we split that part out.
 Then we have the issue of arbituary rendering an 'image' which will be addressed by the other classes here.
 Of note: this is interesting https://unicode.org/L2/L2016/16105r-unicode-image-hash.pdf .
 Even though it's not standard it may seem like a decent proposal to support in the future.
 (https://shadycharacters.co.uk/2019/11/emoji-part-9-going-beyond/)
 */

public protocol DataProvider {
    var contents: Data { get }
    var fileType: String { get }
}

public struct DataAttachment : DataProvider, Hashable, Codable {
    public static func == (lhs: DataAttachment, rhs: DataAttachment) -> Bool {
        return lhs.fileType == rhs.fileType && lhs.contents == rhs.contents
    }
    
    public init(data contentData: Data, ofType uti: String) {
        contents = contentData
        fileType = uti
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(fileType)
        hasher.combine(contents)
    }
    
    public var contents: Data
    public var fileType: String
}

open class FileWrapperAttachment : DataProvider  {

    public init(fileWrapper: FileWrapper) {
        self.fileWrapper = fileWrapper
    }
    
    open var fileWrapper: FileWrapper
    
    open var contents: Data {
        get {
            fatalError("Not yet implemented")
        }
    }
    open var fileType: String {
        get {
            fatalError("Not yet implemented")
        }
    }
}

//TODO: More protocol than class
open class RenderableAttachment {
    init(bounds: Frame<Float>, lineLayoutPadding: CGFloat) {
        self.bounds = bounds
        self.lineLayoutPadding = lineLayoutPadding
    }
    
    open var bounds: Frame<Float>
    open var lineLayoutPadding: CGFloat
    
    open func draw() {
        
    }
}

open class RenderableAttachmentImage : RenderableAttachment {
    init(image: Image, bounds: Frame<Float>, lineLayoutPadding: CGFloat) {
        self.image = image
        super.init(bounds: bounds, lineLayoutPadding: lineLayoutPadding)
    }
    
    open var image: Image
}


/*
 Thinking about what can and should go into an Attributed String. Basically this is a string with additional information. This additional information can be anything.
 Including data dependant on UI such as below. The question is.. should we?
 public protocol NSTextAttachmentCellProtocol : NSObjectProtocol {

     @MainActor func draw(withFrame cellFrame: NSRect, in controlView: NSView?)
     @MainActor func wantsToTrackMouse() -> Bool
     @MainActor func highlight(_ flag: Bool, withFrame cellFrame: NSRect, in controlView: NSView?)
     @MainActor func trackMouse(with theEvent: NSEvent, in cellFrame: NSRect, of controlView: NSView?, untilMouseUp flag: Bool) -> Bool
     nonisolated func cellSize() -> NSSize
     nonisolated func cellBaselineOffset() -> NSPoint
     nonisolated unowned(unsafe) var attachment: NSTextAttachment? { get set }
     
     // Sophisticated cells should implement these in addition to the simpler methods, above.  The class NSTextAttachmentCell implements them to simply call the simpler methods; more complex conformers should implement the simpler methods to call these.
     @MainActor func draw(withFrame cellFrame: NSRect, in controlView: NSView?, characterIndex charIndex: Int)
     @MainActor func draw(withFrame cellFrame: NSRect, in controlView: NSView?, characterIndex charIndex: Int, layoutManager: NSLayoutManager)
     @MainActor func wantsToTrackMouse(for theEvent: NSEvent, in cellFrame: NSRect, of controlView: NSView?, atCharacterIndex charIndex: Int) -> Bool
     @MainActor func trackMouse(with theEvent: NSEvent, in cellFrame: NSRect, of controlView: NSView?, atCharacterIndex charIndex: Int, untilMouseUp flag: Bool) -> Bool

     nonisolated func cellFrame(for textContainer: NSTextContainer, proposedLineFragment lineFrag: NSRect, glyphPosition position: NSPoint, characterIndex charIndex: Int) -> NSRect
 }
 */

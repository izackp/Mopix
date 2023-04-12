//
//  View.swift
//  TestGame
//
//  Created by Isaac Paul on 4/13/22.
//

import Foundation
import SDL2

/*
//I want to reimplement CALayer so I'm not sure about the name 'View'
Features to support:
 rasterization
 masking
 shadows
 corner radius
 beizer path clipping
 border
 alpha
 anchor point & rotation // since sdl2 doesnt support transformations
Feature to support after removeing sdl2:
 3d and affine transformations
 
*/
open class View: Codable {

    public var _id:String? = nil
    public var frame:Frame<Int16> = Frame.zero
    public var listLayouts:[LayoutElement] = []
    public var listLayoutChildren:[LayoutChild] = []
    public var children:Arr<View> = Arr<View>.init()
    public weak var superView:View? = nil
    public weak var window:Window? = nil
    public var onTap:(()->())? = nil
    open var backgroundColor = LabeledColor.white
    public var alpha:Float = 1
    public var cachedImage:Image? = nil
    public var borderColor:LabeledColor = LabeledColor.clear
    public var borderWidth:DValue = 0
    public var userInteractable:Bool = true //Not sure how this is going to work yet
    public var clipBounds:Bool = false
    public var shouldRasterize:Bool = false
    public var shouldRedraw:Bool = false
    
    init () {
        
    }
    
    private enum CodingKeys: String, CodingKey {
        case _id
        case frame
        case listLayouts
        case listLayoutChildren
        case children
        case clipBounds
        case backgroundColor
        case alpha
        case shouldRasterize
        case borderColor
        case borderWidth
    }
    
    //TODO: Obviously weird..
    public init(from decoder: Decoder, clipBoundsDefault:Bool) throws {
        try someInit(from: decoder, clipBoundsDefault: clipBoundsDefault)
    }
    
    public required init(from decoder: Decoder) throws {
        try someInit(from: decoder, clipBoundsDefault: false)
    }
    
    func someInit(from decoder: Decoder, clipBoundsDefault:Bool) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self._id = try container.decodeIfPresent(String.self, forKey: ._id)
        self.frame = try container.decodeIfPresent(Frame<Int16>.self, forKey: .frame) ?? .zero
        self.listLayouts = try container.decodeArray(LayoutElement.self, forKey: .listLayouts)
        self.children = try container.decodeContiguousArray(View.self, forKey: .children)
        self.clipBounds = try container.decodeIfPresent(Bool.self, forKey: .clipBounds) ?? clipBoundsDefault
        self.backgroundColor = try container.decodeDynamicItemIfPresent(LabeledColor.self, forKey: .backgroundColor) ?? LabeledColor.white
        self.alpha = try container.decodeIfPresent(Float.self, forKey: .alpha) ?? 1
        self.shouldRasterize = try container.decodeIfPresent(Bool.self, forKey: .shouldRasterize) ?? false
        self.borderColor = try container.decodeDynamicItemIfPresent(LabeledColor.self, forKey: .borderColor) ?? LabeledColor.clear
        self.borderWidth = try container.decodeIfPresent(DValue.self, forKey: .borderWidth) ?? 0
        for eachChild in self.children {
            eachChild.superView = self
        }
        self.listLayoutChildren = try container.decodeArray(LayoutChild.self, forKey: .listLayoutChildren)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if (_id != nil) {
            try container.encode(_id, forKey: ._id)
        }
        if (frame != .zero) {
            try container.encode(frame, forKey: .frame)
        }
        if (listLayouts.count != 0) {
            try container.encodeArray(listLayouts, forKey: .listLayouts)
        }
        
        if (children.count != 0) {
            try container.encodeArray(children, forKey: .children)
        }
        if (clipBounds) {
            try container.encode(clipBounds, forKey: .clipBounds)
        }
        if (backgroundColor !== LabeledColor.white) {
            try container.encode(backgroundColor, forKey: .backgroundColor)
        }
        if (alpha != 1) {
            try container.encode(alpha, forKey: .alpha)
        }
        if (shouldRasterize) {
            try container.encode(shouldRasterize, forKey: .shouldRasterize)
        }
        if (borderColor.isClear() == false) {
            try container.encode(borderColor, forKey: .borderColor)
        }
        if (borderWidth != 0) {
            try container.encode(borderWidth, forKey: .borderWidth)
        }
        if (listLayoutChildren.count != 0) { //TODO: Verify it is at end of object
            try container.encodeArray(listLayoutChildren, forKey: .listLayoutChildren)
        }
    }
    
    func containerSize() -> Size<DValue>? {
        return superView?.frame.size ?? window?.frame.size
    }
    /*
    func isUserInteractable() -> Bool {
        if (userInteractable == false) {
            return false
        }
        return superView?.isUserInteractable() ?? true
    }*/
    
    func viewForPoint(_ point:Point<DValue>) -> View? {
        if (self.frame.containsPoint(point) == false) { return nil }
        
        let offsetPoint = point.offset(frame.x, frame.y)
        for eachSubview in children.reversed() {
            if let containingSubview = eachSubview.viewForPoint(offsetPoint) {
                return containingSubview
            }
        }
        return self
    }
    
    open func insertView(_ view:View, at:Int) {
        children.insert(view, at: at)
        view.superView = self
    }
    
    open func addSubview(_ view:View) {
        children.append(view)
        view.superView = self
    }
    
    open func removeFromSuperview() {
        if let parent = superView {
            parent.children.removeAll(where: { $0 === self})
        }
        superView = nil
    }
    
    open func onMouseEnter() {
        
    }
    
    open func onMouseLeave() {
        
    }
    
    open func onMouseMotion(event: SDL_MouseMotionEvent) {
        
    }
    
    open func onMousePress(_ event:MouseButtonEvent) {
        
    }
    
    open func onMouseRelease(_ event:MouseButtonEvent) {
        onTap?()
        /*
        print("Tapped View \(_id ?? ""): \(frame)")
        if (backgroundColor == LabeledColor.white) {
            backgroundColor = LabeledColor.red
            return
        }
        if (backgroundColor == LabeledColor.red) {
            backgroundColor = LabeledColor.blue
            return
        }
        if (backgroundColor == LabeledColor.blue) {
            backgroundColor = LabeledColor.green
            return
        }
        if (backgroundColor == LabeledColor.green) {
            backgroundColor = LabeledColor.white
            return
        }*/
    }

    open func layout() {
        for eachItem in listLayouts {
            eachItem.updateFrame(self)
        }
        
        layoutChildren()
        
        for eachItem in listLayoutChildren {
            eachItem.updateChildren(self)
        }
    }

    open func layoutChildren() {
        for eachView in children {
            eachView.layout()
        }
    }
    
    open func drawContent(_ context:UIRenderContext, _ rect:Frame<DValue>) throws {
        
    }
    
    func drawOrRaster(_ context:UIRenderContext, _ rect:Frame<DValue>) throws {
        if (alpha == 0) { return }
        let requiresComposition = (alpha != 1 && (children.count > 0 || !backgroundColor.isClear()))
        let requireRaster = (shouldRasterize || requiresComposition)
        if (requireRaster && cachedImage == nil || shouldRedraw) {
            let originalFrame = frame
            let image = try context.createAndDrawToTexture({ context, frame in
                //TODO: I don't like below.. Also we could do some optimizations by avoiding rendering under specific conditions
                //Currently we always need to redraw because we don't know anything about the the children
                //If any of the children changed 
                let offsetFrame = frame.offset(Point(originalFrame.origin.x * -1, originalFrame.origin.y * -1)) //2am brain hurts haxfix
                try draw(context, offsetFrame)
            }, size: originalFrame.size)
            cachedImage = image
            shouldRedraw = false
        }
        if let image = cachedImage {
            let offsetFrame = frame.offset(rect.origin)
            try context.drawImage(image, offsetFrame, LabeledColor.white.sdlColor(), alpha)
        } else {
            try draw(context, rect)
        }
    }
    
    open func draw(_ context:UIRenderContext, _ rect:Frame<DValue>) throws {
        if (alpha == 0) { return }
        let offsetFrame = frame.offset(rect.origin)
        if let image = cachedImage, shouldRedraw == false {
            try context.drawImage(image, offsetFrame)
            return
        }
        
        try context.drawSquare(offsetFrame, backgroundColor.sdlColor())
        let clip = clipBounds
        var lastClipRect:Frame<DValue>? = nil
        if (clip) {
            lastClipRect = context.currentClipRect
            try context.setClipRect(offsetFrame)
        }
        try drawContent(context, offsetFrame)
        for eachChild in children {
            try eachChild.drawOrRaster(context, offsetFrame)
        }
        
        if (borderWidth > 0 && borderColor.isClear() == false) {
            var line:Frame<DValue> = offsetFrame
            line.height = borderWidth
            let borderColorSdl = borderColor.sdlColor()
            try context.drawSquare(line, borderColorSdl)
            line.y = offsetFrame.bottom - borderWidth
            try context.drawSquare(line, borderColorSdl)
            line.y = offsetFrame.y + borderWidth
            line.width = borderWidth
            line.height = offsetFrame.height - (borderWidth * 2)
            try context.drawSquare(line, borderColorSdl)
            line.x = offsetFrame.right - borderWidth
            try context.drawSquare(line, borderColorSdl)
        }
        
        if (clip) {
            try context.setClipRect(lastClipRect)
        }
    }
    
    func viewForId(_ id:String) -> View? {
        for eachView in children {
            if (eachView._id == id) {
                return eachView
            }
        }
        for eachView in children {
            if let result = eachView.viewForId(id) {
                return result
            }
        }
        return nil
    }
}




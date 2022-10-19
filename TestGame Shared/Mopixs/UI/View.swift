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
 
One problem I have is that content can be drawn outside the layer..
*/
open class View: Codable {

    public var _id:String? = nil
    public var frame:Frame<Int16> = Frame.zero
    public var listLayouts:[LayoutElement] = []
    public var children:Arr<View> = Arr<View>.init()
    public weak var superView:View? = nil
    public weak var window:Window? = nil
    public var onTap:(()->())? = nil
    public var userInteractable:Bool = true //Not sure how this is going to work yet
    
    public var clipBounds:Bool = false
    open var backgroundColor = SmartColor.white
    public var alpha:Float = 1
    public var shouldRasterize:Bool = false
    public var shouldRedraw:Bool = false
    public var cachedImage:Image? = nil
    
    init () {
        
    }
    
    private enum CodingKeys: String, CodingKey {
        case _id
        case frame
        case listLayouts
        case children
        case clipBounds
        case backgroundColor
        case alpha
        case shouldRasterize
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
        self.backgroundColor = try container.decodeDynamicItemIfPresent(SmartColor.self, forKey: .backgroundColor) ?? SmartColor.white
        self.alpha = try container.decodeIfPresent(Float.self, forKey: .alpha) ?? 1
        self.shouldRasterize = try container.decodeIfPresent(Bool.self, forKey: .shouldRasterize) ?? false
        for eachChild in self.children {
            eachChild.superView = self
        }
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
        if (backgroundColor !== SmartColor.white) {
            try container.encode(backgroundColor, forKey: .backgroundColor)
        }
        if (alpha != 1) {
            try container.encode(alpha, forKey: .alpha)
        }
        if (shouldRasterize) {
            try container.encode(shouldRasterize, forKey: .shouldRasterize)
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
    
    open func onMousePress() {
        
    }
    
    open func onMouseRelease() {
        onTap?()
        /*
        print("Tapped View \(_id ?? ""): \(frame)")
        if (backgroundColor == SmartColor.white) {
            backgroundColor = SmartColor.red
            return
        }
        if (backgroundColor == SmartColor.red) {
            backgroundColor = SmartColor.blue
            return
        }
        if (backgroundColor == SmartColor.blue) {
            backgroundColor = SmartColor.green
            return
        }
        if (backgroundColor == SmartColor.green) {
            backgroundColor = SmartColor.white
            return
        }*/
    }

    open func layout() {
        for eachItem in listLayouts {
            eachItem.updateFrame(self)
        }

        layoutChildren()
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
                //TODO: I don't like below.. Also we could do some optimizations by avoiding rendering underspecific conditions
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
            try context.drawImage(image, offsetFrame, SmartColor.white, alpha)
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
        
        try context.drawSquare(offsetFrame, backgroundColor)
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
        if (clip) {
            try context.setClipRect(lastClipRect)
        }
    }
}




//
//  View.swift
//  TestGame
//
//  Created by Isaac Paul on 4/13/22.
//

import Foundation
import SDL2

open class View: Codable {

    public var frame:Frame<Int16> = Frame.zero
    public var listLayouts:[LayoutElement] = []
    public var children:Arr<View> = Arr<View>.init()
    public var superView:View? = nil
    
    public var clipBounds:Bool = false
    open var backgroundColor = SDLColor.white
    
    init () {
        
    }
    
    private enum CodingKeys: String, CodingKey {
        case frame
        case listLayouts
        case children
        case clipBounds
        case backgroundColor
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.frame = try container.decode(Frame<Int16>.self, forKey: .frame)
        self.listLayouts = try container.decodeArray(LayoutElement.self, forKey: .listLayouts)
        self.children = try container.decodeContiguousArray(View.self, forKey: .children)
        self.clipBounds = try container.decode(Bool.self, forKey: .clipBounds)
        self.backgroundColor = try container.decode(SDLColor.self, forKey: .backgroundColor)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(frame, forKey: .frame)
        try container.encodeArray(listLayouts, forKey: .listLayouts)
        try container.encode(children, forKey: .children)
        try container.encode(clipBounds, forKey: .clipBounds)
        try container.encode(backgroundColor, forKey: .backgroundColor)
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

    open func layout() {
        //TODO: I'm not sure if a 'layout is dirty' check will improve performance
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
    
    open func draw(_ context:UIRenderContext) throws {
        try context.drawSquare(frame, backgroundColor)
        
        for eachChild in children {
            try eachChild.draw(context)
        }
    }
}




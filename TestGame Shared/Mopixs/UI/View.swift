//
//  View.swift
//  TestGame
//
//  Created by Isaac Paul on 4/13/22.
//

import Foundation
import SDL2

public struct ViewLayoutBuilder {
    public var view:View
}

open class View {
    public var frame:Frame<Int16> = Frame.zero
    public var listLayouts:Arr<LayoutElement> = Arr<LayoutElement>.init()
    public var children:Arr<View> = Arr<View>.init()
    
    public var clipBounds:Bool = false

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
    
    public func configureLayout() -> ViewLayoutBuilder {
        return ViewLayoutBuilder(view: self)
    }
    
    
    open var backgroundColor = SDLColor.white
    
    open func draw(_ context:UIRenderContext) throws {
        
        try context.drawSquare(frame, backgroundColor)
        
        for eachChild in children {
            try eachChild.draw(context)
        }
    }
}




//
//  Layouts.swift
//  TestGame
//
//  Created by Isaac Paul on 4/13/22.
//

import Foundation

public typealias DValue = Int16

public protocol LayoutElement : Codable {
    func updateFrame(_ view:View)
}

public struct LEInset : LayoutElement, Codable {
    public var edge:Edge
    public var value:DValue
    
    public func updateFrame(_ view:View) {
        view.frame.offsetValueForEdge(edge, value)
    }
}

public struct LEInsetFixed : LayoutElement, Codable {
    public var edge:Edge
    public var value:DValue
    
    public func updateFrame(_ view:View) {
        view.frame.setValueForEdgeFixed(edge, value)
    }
}

public struct LEWidth : LayoutElement, Codable {
    public var value:DValue

    public func updateFrame(_ view:View) {
        view.frame.width = value
    }
}

public struct LEHeight : LayoutElement, Codable {
    public var value:DValue

    public func updateFrame(_ view:View) {
        view.frame.height = value
    }
}

public struct LEPosX : LayoutElement, Codable {
    public var value:DValue

    public func updateFrame(_ view:View) {
        view.frame.x = value
    }
}

public struct LEPosY : LayoutElement, Codable {
    public var value:DValue

    public func updateFrame(_ view:View) {
        view.frame.y = value
    }
}

public struct LEAlign : LayoutElement, Codable {
    public var vertical:Bool
    public var percentStart:Float
    public var percentEnd:Float

    //If I want to set the left edge to 50. I need to get the width of the parent
    public func updateFrame(_ view:View) {
        guard let container = view.containerSize() else { return }
        let remainingSize = Float(container.width - view.frame.size.width)
        let pTotal = percentEnd + percentStart
        if (pTotal == 0) {
            view.frame.x = Int16(remainingSize * 0.5)
            return
        }
        let pStart = percentStart / pTotal
        view.frame.x = Int16(remainingSize * pStart)
    }
}


public struct LEAnchor : LayoutElement, Codable {
    public var edge:Edge
    public var percent:Float

    public func perpendicularValueForEdge<T: Numeric>(_ frameSize:Size<T>) -> T {
        switch (edge) {
            case Edge.Top:
                fallthrough
            case Edge.Bottom:
                return frameSize.height
            default:
                return frameSize.width
        }
    }

    //If I want to set the left edge to 50. I need to get the width of the parent
    public func updateFrame(_ view:View) {
        guard let container = view.containerSize() else { return }
        let parentMag = perpendicularValueForEdge(container)
        let newValue = roundf(Float(parentMag) * percent)
        view.frame.setValueForEdge(edge, Int16(newValue))
    }
}

public struct LEAnchorFixed : LayoutElement, Codable {
    public var edge:Edge
    public var percent:Float

    public func perpendicularValueForEdge<T: Numeric>(_ frameSize:Size<T>) -> T {
        switch (edge) {
            case Edge.Top:
                fallthrough
            case Edge.Bottom:
                return frameSize.height
            default:
                return frameSize.width
        }
    }

    //If I want to set the left edge to 50. I need to get the width of the parent
    public func updateFrame(_ view:View) {
        guard let container = view.containerSize() else { return }
        let parentMag = perpendicularValueForEdge(container)
        let newValue = roundf(Float(parentMag) * percent)
        view.frame.setValueForEdgeFixed(edge, Int16(newValue))
    }
}

//TODO: Broken. Need to rethink
public struct LEWrapWidth : LayoutElement, Codable {
    public func updateFrame(_ view:View) {
        view.layoutChildren()
        var frame = view.frame
        var minX = frame.width
        var maxX:DValue = 0
        for child in view.children {
            let childFrame = child.frame
            let left = childFrame.left
            let right = childFrame.right
            if (left < minX) {
                minX = left
            }
            if (right > maxX) {
                maxX = right
            }
        }
        
        for child in view.children {
            child.frame.x -= minX
        }
        maxX -= minX
        frame.width = maxX
    }
}

public struct LEWrapHeight : LayoutElement, Codable {
    public func updateFrame(_ view:View) {
        view.layoutChildren()
        var frame = view.frame
        var minY = frame.height
        var maxY:DValue = 0
        for child in view.children {
            let childFrame = child.frame
            let top = childFrame.top
            let bottom = childFrame.bottom
            if (top < minY) {
                minY = top
            }
            if (bottom > maxY) {
                maxY = bottom
            }
        }
        
        for child in view.children {
            child.frame.y -= minY
        }
        maxY -= minY
        frame.width = maxY
    }
}

//TODO: I don't like it.. Think of something else
public struct LEMirrorMargin: LayoutElement, Codable {
    public var source:Edge
    public var destination:Edge
    
    public func updateFrame(_ view:View) {
        guard let container = view.containerSize() else { return }
        let sourceValue = view.frame.marginForEdge(source, containerSize: container)
        view.frame.setMarginForEdge(destination, value: sourceValue, container: container)
    }
}

//Match the side that has the biggest margin..
public struct LEMirrorMarginHorizontalMax: LayoutElement, Codable {
    
    public func updateFrame(_ view:View) {
        guard let container = view.containerSize() else { return }
        let leftValue = view.frame.marginForEdge(.Left, containerSize: container)
        let rightValue = view.frame.marginForEdge(.Right, containerSize: container)
        if (leftValue > rightValue) {
            view.frame.setMarginForEdge(.Right, value: leftValue, container: container)
        } else {
            view.frame.setMarginForEdge(.Left, value: rightValue, container: container)
        }
    }
}

/*
The current program is designed for in -> out -> apply

    What we know:
    We're going to have a 'view' and we're going to need to be able to call 'layoutSubviews' after resizing

Layout Kit:
    - Has a struct only architecture.
    - Generates UI Views from the tree


We have a few design considerations:
Layout kit uses these types of layouts:

    LabelLayout : A layout for a UILabel.
    ButtonLayout: A layout for a UIButton.
    SizeLayout  : A layout for a specific size (e.g. UIImageView).
    InsetLayout : A layout that insets its child layout (i.e. padding).
    StackLayout : A layout that stacks its child layouts horizontally or vertically.

    All layouts have an alignment and flexibility (priority per axis)
    Animation is done by providing an alternative layout tree and passing in a rootview of already layed out elements which is a bit 'much' imo.
        let animation = after.arrangement(width: 350, height: 250).prepareAnimation(for: rootView, direction: .rightToLeft)
    A user is going to want to deal solely with the element being animated.


Quick note:
We can use the double anchor method and allow anchors to be relative to other views, but it begs the question of how do we do something like minimum height? Also what if the view its linked to disappears? hmmm perhaps it can be relative to the opposite side, so instead of being pinned to the right be pinned to the left of the relative view.

Another layout engine mentioned you only need 4 sets of data to describe a frame
//X_Anchor, X_Offset
//Y_Anchor, Y_Offset
our dual anchor essentially describes 2 frames  Parent frame based on % and inset frame based on offset
//X_Rel_View, X_Offset
left [modifiers]
left [min, max, minVal, maxVal, relativeToV, anchor, Offset]
When we go over 4 I think we increase behavior conflicts
maxVal screws us with anchor
instead of describing left we can describe 'start' to indicate right lang support

    Ways to describe a view
    Start [20%, 10dp], Bottom [100%, 0dp], Top [0%, 0dp], Right [100%, 0dp]
    modfied to be next to text:
    Start [txtOther.right, 0%, 10dp], Same as above + maxWidth [100dp, .center]
    the issue with the above is where will the view align to? right, left, middle?

    Start [0%, 0dp], Bottom [50%, -20dp], Top [50%, 20dp], Right [100%, 0dp]

    Match [txtOther, .Right]
    Inset [Top, Right, Down, Left]
    Anchor [.Left, 0%]
    Width [100dp]
    Height [100dp]
    Position [x, y]
    MaxWidth [100dp]
    AlignBaseLine [txtOther]
    WrapContent [.Height]

    Match [.Top, parent, .Top]
    Match [.Bottom, parent, .Bottom]
    Anchor [.Top, 25%]
    Anchor [.Bottom, 25%]
    MaxHeight [100dp]

    My only issue so far is during the relayout phase. If txtOther changes how do we only update dependant views
    //txtOther.dependant.foreach { queueUpdate ()}

    What if we remove the view for the window.. I guess we just delete all the layout info?
*/

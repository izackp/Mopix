//
//  LayoutChild.swift
//  TestGame
//
//  Created by Isaac Paul on 1/12/23.
//

import Foundation

public protocol LayoutChild: Codable {
    func updateChildren(_ view:View)
}

public struct LCInset : LayoutChild, Codable {
    public var target:View
    public var edge:Edge
    public var value:DValue
    
    public func updateChildren(_ view:View) {
        view.frame.offsetValueForEdge(edge, value)
    }
}

public struct LCInsetFixed : LayoutChild, Codable {
    public var target:View
    public var edge:Edge
    public var value:DValue
    
    public func updateChildren(_ view:View) {
        view.frame.setValueForEdgeFixed(edge, value)
    }
}

public struct LCWidth : LayoutChild, Codable {
    public var target:View
    public var value:DValue

    public func updateChildren(_ view:View) {
        view.frame.width = value
    }
}

public struct LCHeight : LayoutChild, Codable {
    public var target:View
    public var value:DValue

    public func updateChildren(_ view:View) {
        view.frame.height = value
    }
}

public struct LCPosX : LayoutChild, Codable {
    public var target:View
    public var value:DValue

    public func updateChildren(_ view:View) {
        view.frame.x = value
    }
}

public struct LCPosY : LayoutChild, Codable {
    public var target:View
    public var value:DValue

    public func updateChildren(_ view:View) {
        view.frame.y = value
    }
}


public struct LCAnchor : LayoutChild, Codable {
    public var target:View
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
    public func updateChildren(_ view:View) {
        guard let container = view.containerSize() else { return }
        let parentMag = perpendicularValueForEdge(container)
        let newValue = roundf(Float(parentMag) * percent)
        target.frame.setValueForEdge(edge, Int16(newValue))
    }
}

public struct LCAnchorFixed : LayoutChild, Codable {
    public var target:View
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
    public func updateChildren(_ view:View) {
        guard let container = view.containerSize() else { return }
        let parentMag = perpendicularValueForEdge(container)
        let newValue = roundf(Float(parentMag) * percent)
        target.frame.setValueForEdgeFixed(edge, Int16(newValue))
    }
}

//TODO: Broken. Need to rethink
public struct LCWrapWidth : LayoutChild, Codable {
    public var target:View
    public func updateChildren(_ view:View) {
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

public struct LCWrapHeight : LayoutChild, Codable {
    public var target:View
    public func updateChildren(_ view:View) {
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
public struct LCMirrorMargin: LayoutChild, Codable {
    public var target:View
    public var source:Edge
    public var destination:Edge
    
    public func updateChildren(_ view:View) {
        guard let container = view.containerSize() else { return }
        let sourceValue = view.frame.marginForEdge(source, containerSize: container)
        target.frame.setMarginForEdge(destination, value: sourceValue, container: container)
    }
}

//Match the side that has the biggest margin..
public struct LCMirrorMarginHorizontalMax: LayoutChild, Codable {
    public var target:View
    
    public func updateChildren(_ view:View) {
        guard let container = view.containerSize() else { return }
        let leftValue = view.frame.marginForEdge(.Left, containerSize: container)
        let rightValue = view.frame.marginForEdge(.Right, containerSize: container)
        if (leftValue > rightValue) {
            target.frame.setMarginForEdge(.Right, value: leftValue, container: container)
        } else {
            target.frame.setMarginForEdge(.Left, value: rightValue, container: container)
        }
    }
}


public struct LCMatch : LayoutChild, Codable {
    public var target:View
    public var edgeTarget:Edge
    public var source:View
    public var edgeSource:Edge

    public func updateChildren(_ view:View) {
        target.frame.setValueForEdge(edgeTarget, source.frame.valueForEdge(edgeSource))
    }
}

public struct LCMatchFixed : LayoutChild, Codable {
    public var target:View
    public var edgeTarget:Edge
    public var source:View
    public var edgeSource:Edge

    public func updateChildren(_ view:View) {
        target.frame.setValueForEdgeFixed(edgeTarget, source.frame.valueForEdge(edgeSource))
    }
}

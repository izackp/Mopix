//
//  Layouts.swift
//  TestGame
//
//  Created by Isaac Paul on 4/13/22.
//

import Foundation

protocol Initializable {
    init()
}

func createInstance2(typeThing:Initializable.Type) -> Initializable {
    return typeThing.init()
}

class TypeMap {
    static let shared = TypeMap()
    
    var typeList:[Initializable.Type] = []
    
    func register(_ type:Initializable.Type) {
        //register(TypeMap.self)
        
        let idk = createInstance2(typeThing: type)
        print(String(describing: idk))
        let mirror = Mirror(reflecting: idk)
        for case let (label?, value) in mirror.children {
            print (label, value)
        }
        if let _ = typeList.firstIndex(where: {$0 == type}) {
            return
        } else {
            typeList.append(type)
        }
    }
}


public struct AnyCodable {
    
}

public typealias DValue = Int16

public enum LECodableWrapper: Codable {
    case inset(LEInset)
    case insetFixed(LEInsetFixed)
    case width(LEWidth)
    case height(LEHeight)
    case posX(LEPosX)
    case posY(LEPosY)
    case match(LEMatch)
    case matchFixed(LEMatchFixed)
    case anchor(LEAnchor)
    case anchorFixed(LEAnchorFixed)
    case wrapWidth(LEWrapWidth)
    case wrapHeight(LEWrapHeight)
    case mirrorMargin(LEMirrorMargin)
    case mirrorMarginHorizontalMax(LEMirrorMarginHorizontalMax)
    
    init(_ from:LayoutElement) {
        switch from {
        case let from as LEInset:
            self = .inset(from)
        case let from as LEInsetFixed:
            self = .insetFixed(from)
        case let from as LEWidth:
            self = .width(from)
        case let from as LEHeight:
            self = .height(from)
        case let from as LEPosX:
            self = .posX(from)
        case let from as LEPosY:
            self = .posY(from)
        case let from as LEMatch:
            self = .match(from)
        case let from as LEMatchFixed:
            self = .matchFixed(from)
        case let from as LEWrapWidth:
            self = .wrapWidth(from)
        case let from as LEWrapHeight:
            self = .wrapHeight(from)
        case let from as LEMirrorMargin:
            self = .mirrorMargin(from)
        case let from as LEMirrorMarginHorizontalMax:
            self = .mirrorMarginHorizontalMax(from)
        default:
            fatalError("Unknown type")
        }
    }

    private enum CodingKeys: String, CodingKey {
        case type
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let typeInfo = try container.decode(String.self, forKey: .type)
        
        switch typeInfo {
            case "LEInset":
                self = .inset(try LEInset(from: decoder))
            case "LEInsetFixed":
                self = .insetFixed(try LEInsetFixed(from: decoder))
            case "LEWidth":
                self = .width(try LEWidth(from: decoder))
            case "LEHeight":
                self = .height(try LEHeight(from: decoder))
            case "LEPosX":
                self = .posX(try LEPosX(from: decoder))
            case "LEPosY":
                self = .posY(try LEPosY(from: decoder))
            case "LEMatch":
                self = .match(try LEMatch(from: decoder))
            case "LEMatchFixed":
                self = .matchFixed(try LEMatchFixed(from: decoder))
            case "LEAnchor":
                self = .anchor(try LEAnchor(from: decoder))
            case "LEAnchorFixed":
                self = .anchorFixed(try LEAnchorFixed(from: decoder))
            case "LEWrapWidth":
                self = .wrapWidth(try LEWrapWidth(from: decoder))
            case "LEWrapHeight":
                self = .wrapHeight(try LEWrapHeight(from: decoder))
            case "LEMirrorMargin":
                self = .mirrorMargin(try LEMirrorMargin(from: decoder))
            case "LEMirrorMarginHorizontalMax":
                self = .mirrorMarginHorizontalMax(try LEMirrorMarginHorizontalMax(from: decoder))
            default:
                fatalError("Unknown type")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
            case .inset(let item):
                try container.encode("LEInset", forKey: .type)
                try item.encode(to: encoder)
            case .insetFixed(let item):
                try container.encode("LEInsetFixed", forKey: .type)
                try item.encode(to: encoder)
            case .width(let item):
                try container.encode("LEWidth", forKey: .type)
                try item.encode(to: encoder)
            case .height(let item):
                try container.encode("LEHeight", forKey: .type)
                try item.encode(to: encoder)
            case .posX(let item):
                try container.encode("LEPosX", forKey: .type)
                try item.encode(to: encoder)
            case .posY(let item):
                try container.encode("LEPosY", forKey: .type)
                try item.encode(to: encoder)
            case .match(let item):
                try container.encode("LEMatch", forKey: .type)
                try item.encode(to: encoder)
            case .matchFixed(let item):
                try container.encode("LEMatchFixed", forKey: .type)
                try item.encode(to: encoder)
            case .anchor(let item):
                try container.encode("LEAnchor", forKey: .type)
                try item.encode(to: encoder)
            case .anchorFixed(let item):
                try container.encode("LEAnchorFixed", forKey: .type)
                try item.encode(to: encoder)
            case .wrapWidth(let item):
                try container.encode("LEWrapWidth", forKey: .type)
                try item.encode(to: encoder)
            case .wrapHeight(let item):
                try container.encode("LEWrapHeight", forKey: .type)
                try item.encode(to: encoder)
            case .mirrorMargin(let item):
                try container.encode("LEMirrorMargin", forKey: .type)
                try item.encode(to: encoder)
            case .mirrorMarginHorizontalMax(let item):
                try container.encode("LEMirrorMarginHorizontalMax", forKey: .type)
                try item.encode(to: encoder)
        }
    }
    
    public func toLE() -> LayoutElement {
        switch self {
            case .inset(let item):
                return item
            case .insetFixed(let item):
            return item
            case .width(let item):
            return item
            case .height(let item):
            return item
            case .posX(let item):
            return item
            case .posY(let item):
            return item
            case .match(let item):
            return item
            case .matchFixed(let item):
            return item
            case .anchor(let item):
            return item
            case .anchorFixed(let item):
            return item
            case .wrapWidth(let item):
            return item
            case .wrapHeight(let item):
            return item
            case .mirrorMargin(let item):
            return item
            case .mirrorMarginHorizontalMax(let item):
            return item
        }
    }
}

public protocol LayoutElement : Any, Codable {
    func updateFrame(_ view:View)
}

extension LayoutElement {
    static func idk(_ value:Int) -> LayoutElement {
        return LEInset(edge: Edge.Top, value: 0)
    }
}

public struct LEInset : LayoutElement, Codable {
    public var edge:Edge
    public var value:DValue
    
    public func updateFrame(_ view:View) {
        view.frame.setValueForEdge(edge, value)
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

public struct LEMatch : LayoutElement, Codable {
    public var edgeSource:Edge
    public var source:View
    public var edgeDestination:Edge

    public func updateFrame(_ view:View) {
        view.frame.setValueForEdge(edgeDestination, source.frame.valueForEdge(edgeSource))
    }
}

public struct LEMatchFixed : LayoutElement, Codable {
    public var edgeSource:Edge
    public var source:View
    public var edgeDestination:Edge

    public func updateFrame(_ view:View) {
        view.frame.setValueForEdgeFixed(edgeDestination, source.frame.valueForEdge(edgeSource))
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
        guard let parent = view.superView else { return }
        let parentMag = perpendicularValueForEdge(parent.frame.size)
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
        guard let parent = view.superView else { return }
        let parentMag = perpendicularValueForEdge(parent.frame.size)
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
        guard let parent = view.superView else { return }
        let container = parent.frame.size
        let sourceValue = view.frame.marginForEdge(source, containerSize: container)
        view.frame.setMarginForEdge(destination, value: sourceValue, container: container)
    }
}

public struct LEMirrorMarginHorizontalMax: LayoutElement, Codable {
    
    public func updateFrame(_ view:View) {
        guard let parent = view.superView else { return }
        let container = parent.frame.size
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

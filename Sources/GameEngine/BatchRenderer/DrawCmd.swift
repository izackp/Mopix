//
//  DrawCmd.swift
//
//
//  Created by Isaac Paul on 5/22/23.
//

import Foundation
import SDL2Swift
import SDL2

//Var vs let : https://forums.swift.org/t/to-var-or-let-struct-properties/52363/12
//Seems like defaulting to var makes sense unless we have specific varients

public struct DrawProperties {
    let animationId:UInt64
    let resourceId:UInt64
    let dest:Rect<Int>
    let color:SDLColor = SDLColor.white
    let z:Int
    let alpha:Float
    let rotation:Float
    let rotationPoint:Point<Int> //point where to rotate
    let clippingRect:Rect<Int>
    let flip:BitMaskOptionSet<Renderer.RendererFlip> = [.none]
    var time:UInt64
}

public struct DrawCmdImage {
    let animationId:UInt64
    let parentAnimationId:UInt64
    let resourceId:UInt64
    let dest:Rect<Int>
    let color:SDLColor = SDLColor.white
    let z:Int
    let alpha:Float
    let rotation:Float
    let rotationPoint:Point<Int> //point where to rotate
    let clippingRect:Rect<Int>
    let flip:BitMaskOptionSet<Renderer.RendererFlip> = [.none]
    var time:UInt64

    public init(animationId: UInt64, resourceId: UInt64, dest: Rect<Int>, z: Int, alpha: Float, rotation: Float, rotationPoint: Point<Int>, clippingRect: Rect<Int>, time: UInt64) {
        self.animationId = animationId
        self.parentAnimationId = 0
        self.resourceId = resourceId
        self.dest = dest
        self.z = z
        self.alpha = alpha
        self.rotation = rotation
        self.rotationPoint = rotationPoint
        self.clippingRect = clippingRect
        self.time = time
    }

    public init(animationId: UInt64, parentAnimationId: UInt64, resourceId: UInt64, dest: Rect<Int>, z: Int, alpha: Float, rotation: Float, rotationPoint: Point<Int>, clippingRect: Rect<Int>, time: UInt64) {
        self.animationId = animationId
        self.parentAnimationId = parentAnimationId
        self.resourceId = resourceId
        self.dest = dest
        self.z = z
        self.alpha = alpha
        self.rotation = rotation
        self.rotationPoint = rotationPoint
        self.clippingRect = clippingRect
        self.time = time
    }

    static func getId(_ item:DrawCmdImage) -> Int {
        Int(Int64(bitPattern: item.animationId))
    }
}

public extension DrawCmdImage {

    func compare(_ other:DrawCmdImage) -> ComparisonResult {
        let result = z.compare(other.z)
        if (result == .orderedSame) {
            return resourceId.compare(other.resourceId) //Somethings like shapes dont need an resource id
        }
        return result
    }

    func lerp(_ oldCmd:DrawCmdImage, _ currentTime:UInt64) -> DrawCmdImage {
        let diff = time - oldCmd.time
        if (diff == 0) { return self }
        let offset = currentTime - oldCmd.time
        if (offset == 0) { return oldCmd }

        let offsetF = Float(offset)
        let diffF = Float(diff)
        let percent:Float
        if (offsetF >= diffF) {
            percent = 1
        } else {
            percent = Float(offset) / Float(diff)
        }

        let result = DrawCmdImage(
            animationId: animationId,
            parentAnimationId: parentAnimationId,
            resourceId: resourceId,
            dest: dest.lerp(oldCmd.dest, percent),
            z: z.lerp(oldCmd.z, percent),
            alpha: alpha.lerp(oldCmd.alpha, percent),
            rotation: rotation.lerpAngle(oldCmd.rotation, percent),
            rotationPoint: rotationPoint.lerp(oldCmd.rotationPoint, percent),
            clippingRect: clippingRect.lerp(oldCmd.clippingRect, percent),
            time: oldCmd.time + offset) //NOTE: time lerp not really needed...
        return result
    }
}

/// Solid color rectangle — no texture required.
public struct DrawCmdFill {
    public let animationId: UInt64
    public let parentAnimationId: UInt64
    public let dest: Rect<Int>
    public let color: SDLColor
    public let alpha: Float
    public let z: Int
    public let clippingRect: Rect<Int>

    public init(animationId: UInt64, parentAnimationId: UInt64, dest: Rect<Int>, color: SDLColor, alpha: Float, z: Int, clippingRect: Rect<Int>) {
        self.animationId = animationId
        self.parentAnimationId = parentAnimationId
        self.dest = dest
        self.color = color
        self.alpha = alpha
        self.z = z
        self.clippingRect = clippingRect
    }
}

/// One command per View — background fill and borders.
public struct DrawCmdView {
    public let animationId: UInt64
    public let parentAnimationId: UInt64
    public let dest: Rect<Int>
    public let backgroundColor: SDLColor
    public let backgroundAlpha: Float
    public let borderColor: SDLColor
    public let borderWidth: Int
    public let z: Int
    public let clippingRect: Rect<Int>

    public init(animationId: UInt64, parentAnimationId: UInt64, dest: Rect<Int>, backgroundColor: SDLColor, backgroundAlpha: Float, borderColor: SDLColor, borderWidth: Int, z: Int, clippingRect: Rect<Int>) {
        self.animationId = animationId
        self.parentAnimationId = parentAnimationId
        self.dest = dest
        self.backgroundColor = backgroundColor
        self.backgroundAlpha = backgroundAlpha
        self.borderColor = borderColor
        self.borderWidth = borderWidth
        self.z = z
        self.clippingRect = clippingRect
    }
}

/// Render-to-texture — recursive sub-command list.
public struct DrawCmdRTT {
    public let animationId: UInt64
    public let parentAnimationId: UInt64
    public let targetResourceId: UInt64
    public let targetRect: Rect<Int>
    public let z: Int
    public let clippingRect: Rect<Int>
    public var subCommands: [DrawCmd]

    public init(animationId: UInt64, parentAnimationId: UInt64, targetResourceId: UInt64, targetRect: Rect<Int>, z: Int, clippingRect: Rect<Int>, subCommands: [DrawCmd]) {
        self.animationId = animationId
        self.parentAnimationId = parentAnimationId
        self.targetResourceId = targetResourceId
        self.targetRect = targetRect
        self.z = z
        self.clippingRect = clippingRect
        self.subCommands = subCommands
    }
}

/// Typed draw command sent through the rendering pipeline.
/// The `indirect` keyword is required because DrawCmdRTT embeds [DrawCmd].
public indirect enum DrawCmd {
    case image(DrawCmdImage)
    case fill(DrawCmdFill)
    case view(DrawCmdView)
    case rtt(DrawCmdRTT)

    /// The z-order of the command, used for sorting.
    var z: Int {
        switch self {
        case .image(let c): return c.z
        case .fill(let c):  return c.z
        case .view(let c):  return c.z
        case .rtt(let c):   return c.z
        }
    }

    /// The animationId of the command.
    var animationId: UInt64 {
        switch self {
        case .image(let c): return c.animationId
        case .fill(let c):  return c.animationId
        case .view(let c):  return c.animationId
        case .rtt(let c):   return c.animationId
        }
    }

    /// The parentAnimationId of the command.
    var parentAnimationId: UInt64 {
        switch self {
        case .image(let c): return c.parentAnimationId
        case .fill(let c):  return c.parentAnimationId
        case .view(let c):  return c.parentAnimationId
        case .rtt(let c):   return c.parentAnimationId
        }
    }
}

//
//  DrawCmd.swift
//
//
//  Created by Isaac Paul on 5/22/23.
//

import Foundation
import SDL2Swift
import SDL2

public enum DrawCmdType {
    case image(resourceId: UInt64)
    case fill                                                    // color/alpha from DrawCmd base
    case view(borderColor: SDLColor, borderWidth: Int)          // base color = backgroundColor
    case text(fontHandle: UInt64, content: String, size: Float, align: TextAlignment)
    case line(to: Point<Int>, thickness: Int)                   // color/alpha from DrawCmd base
    case circle(radius: Int, filled: Bool)                      // centered on DrawCmd.dest origin
    case rect(filled: Bool)                                     // uses DrawCmd.dest
    case rtt                                                     // stub; to be removed
}

public struct DrawCmd {
    public let target: UInt64                                   // 0 = viewport; non-zero = editable image ResHandle
    public let animationId: UInt64
    public let parentAnimationId: UInt64
    public let dest: Rect<Int>
    public let color: SDLColor
    public let alpha: Float
    public let z: Int
    public let rotation: Float
    public let rotationPoint: Point<Int>
    public let clippingRect: Rect<Int>
    public let flip: BitMaskOptionSet<Renderer.RendererFlip>
    public var time: UInt64
    public let type: DrawCmdType

    public init(
        target: UInt64 = 0,
        animationId: UInt64,
        parentAnimationId: UInt64,
        dest: Rect<Int>,
        color: SDLColor,
        alpha: Float,
        z: Int,
        rotation: Float,
        rotationPoint: Point<Int>,
        clippingRect: Rect<Int>,
        flip: BitMaskOptionSet<Renderer.RendererFlip>,
        time: UInt64,
        type: DrawCmdType
    ) {
        self.target = target
        self.animationId = animationId
        self.parentAnimationId = parentAnimationId
        self.dest = dest
        self.color = color
        self.alpha = alpha
        self.z = z
        self.rotation = rotation
        self.rotationPoint = rotationPoint
        self.clippingRect = clippingRect
        self.flip = flip
        self.time = time
        self.type = type
    }
}

public extension DrawCmd {

    func lerp(_ oldCmd: DrawCmd, _ currentTime: UInt64) -> DrawCmd {
        let diff = time - oldCmd.time
        if (diff == 0) { return self }
        guard currentTime >= oldCmd.time else { return self }
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

        return DrawCmd(
            target: target,
            animationId: animationId,
            parentAnimationId: parentAnimationId,
            dest: dest.lerp(oldCmd.dest, percent),
            color: color,
            alpha: alpha.lerp(oldCmd.alpha, percent),
            z: z.lerp(oldCmd.z, percent),
            rotation: rotation.lerpAngle(oldCmd.rotation, percent),
            rotationPoint: rotationPoint.lerp(oldCmd.rotationPoint, percent),
            clippingRect: clippingRect.lerp(oldCmd.clippingRect, percent),
            flip: flip,
            time: oldCmd.time + offset,
            type: type
        )
    }

    static func getId(_ cmd: DrawCmd) -> Int {
        Int(Int64(bitPattern: cmd.animationId))
    }

    func compare(_ other: DrawCmd) -> ComparisonResult {
        if animationId < other.animationId { return .orderedAscending }
        if animationId > other.animationId { return .orderedDescending }
        return .orderedSame
    }
}

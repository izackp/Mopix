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
    case rtt                                                     // stub; redesigned separately
}

public struct DrawCmd {
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
}

public extension DrawCmd {

    func lerp(_ oldCmd: DrawCmd, _ currentTime: UInt64) -> DrawCmd {
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

        return DrawCmd(
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
}

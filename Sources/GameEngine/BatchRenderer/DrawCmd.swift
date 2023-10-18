//
//  DrawCmd.swift
//  
//
//  Created by Isaac Paul on 5/22/23.
//

import Foundation
import SDL2Swift
import SDL2

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

//Var vs let : https://forums.swift.org/t/to-var-or-let-struct-properties/52363/12
//Seems like defaulting to var makes sense unless we have specific varients
public struct DrawCmdImage {
    public init(animationId: UInt64, resourceId: UInt64, dest: Rect<Int>, z: Int, alpha: Float, rotation: Float, rotationPoint: Point<Int>, clippingRect: Rect<Int>, time: UInt64) {
        self.animationId = animationId
        self.resourceId = resourceId
        self.dest = dest
        self.z = z
        self.alpha = alpha
        self.rotation = rotation
        self.rotationPoint = rotationPoint
        self.clippingRect = clippingRect
        self.time = time
    }
    
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

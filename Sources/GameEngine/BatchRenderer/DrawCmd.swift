//
//  DrawCmd.swift
//  
//
//  Created by Isaac Paul on 5/22/23.
//

public struct DrawCmdImage {
    let animationId:UInt64
    let resourceId:UInt64
    let dest:Frame<Int>
    let color:SDLColor = SDLColor.white
    let z:Int
    let rotation:Float
    let rotationPoint:Point<Int> //point where to rotate
    let alpha:Float
    let time:UInt64
}

public extension DrawCmdImage {
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
            rotation: rotation.lerp(oldCmd.rotation, percent), 
            rotationPoint: rotationPoint.lerp(oldCmd.rotationPoint, percent), 
            alpha: alpha.lerp(oldCmd.alpha, percent), 
            time: oldCmd.time + offset) //NOTE: time lerp not really needed...
        return result
    }
}

//
//  Animator.swift
//  TestGame
//
//  Created by Isaac Paul on 5/3/22.
//

import Foundation


public struct KeyFrame<T> {
    public let value:T
    public let time:Float
}

public class SpriteAnimationClip {
    public init(length: Float, name: String, keyFrames: [KeyFrame<Image>]) throws {
        if (keyFrames.isEmpty) {
            throw GenericError("Animation Clip must have frames") //TODO: ??
        }
        self.length = length
        self.name = name
        self.keyFrames = keyFrames
    }
    
    public var length:Float
    public var name:String
    public var keyFrames:[KeyFrame<Image>]

    //TODO: Binary search?
    func frameForTime(_ time:Float) -> KeyFrame<Image> {
        var vTime = time
        if (vTime > length) {
            vTime -= length
        }

        var currentFrame:KeyFrame<Image> = keyFrames.first!
        for frame in keyFrames {
            if (frame.time > time) {
                return currentFrame
            }

            currentFrame = frame
        }

        return currentFrame
    }

    public func applyFrame(_ time:Float) {
        
        //KeyFrame<Sprite> frame = FrameForTime(time);
        //if (renderer.sprite == frame.Value)
        //    return;
        //Debug.Log("Changing keyframe to: " + frame.Value.name);
        //renderer.sprite = frame.Value;
    }
}

public class Animator {
    public init(speed: Float, shouldLoop: Bool, hidden: Bool, currentPlayTime: Float, currentClip: SpriteAnimationClip? = nil) {
        self.speed = speed
        self.shouldLoop = shouldLoop
        self.hidden = hidden
        self.currentPlayTime = currentPlayTime
        self.currentClip = currentClip
    }

    public var speed:Float
    //public var SpriteRenderer SprRenderer;
    public var shouldLoop:Bool
    public var hidden:Bool

    public var currentPlayTime:Float
    public var currentClip:SpriteAnimationClip?


    public func update(deltaTime:Float) {
        currentPlayTime += (deltaTime * speed)

        guard let currentClip = currentClip else {
            return
        }

        while (currentPlayTime > currentClip.length) {
            currentPlayTime -= currentClip.length
        }

        if (hidden) {
            //SprRenderer.sprite = null;
            return
        }

        currentClip.applyFrame(currentPlayTime)
    }
    
    public func playAnimation(newClip:SpriteAnimationClip, shouldReset:Bool) {
        if (currentClip !== newClip) {
            currentPlayTime = 0.0
            currentClip = newClip
        }

        if (shouldReset) {
            currentPlayTime = 0.0
        }
    }
}

//
//  InterfaceStructClass.swift
//  TestGame
//
//  Created by Isaac Paul on 3/30/23.
//

import Foundation
public class InterfaceStructClass : IParticleBacking {

    struct FastTweenC : SomeTween {

        public var targetPtr:Particle! = nil// { get set }
        public var particlePool:ObjectPool<Particle>! = nil
        public var _tracker = Tracker(0)

        public var ID: ContiguousHandle
        public var isAlive: Bool
        public var completed: Bool
        private var _canceled: Bool = false

        public init() {
            _tracker = Tracker(0)
            //self.particlePool = particlePool
            ID = ContiguousHandle(index: 0)
            isAlive = false
            completed = false
        }
        
        public mutating func initHook() {
            assert(!isAlive, "unexpected")
            _tracker = Tracker(0)
        }

        public mutating func clean() {
            _canceled = false
            completed = false
        }

        public mutating func setDuration(_ time:TimeInterval) {
            _tracker = .init(time)
        }

        public mutating func cancelAnimation() {
            _canceled = true
        }

        public mutating func processFrame(_ delta:Double) -> Bool {
            
            if (completed) {
                //throw new Exception("Yo")
                return true
            }
            if (_canceled) {
                onComplete(targetPtr, false)
                return true
            }

            let elapsedRatio = _tracker.progress(delta)
            action(targetPtr, elapsedRatio)

            let completed2 = elapsedRatio == 1.0
            completed = completed2
            if (completed2) {
                onComplete(targetPtr, completed2)
            }
            return completed
        }

        public var pos:Vector<Float> = Vector(0, 0)
        public var endGravity:Float = 0
        public var endVector:Vector<Float> = Vector(0, 0)
        public var colorDiff:ARGB32Diff = ARGB32Diff(start: 0, dest: 0)

        public func action(_ target:Particle, _ elapsedRatio:Double) {
            let ratio = Float(elapsedRatio)
            let x = endVector.x * ratio
            let y = endVector.y * ratio
            let otherY = endGravity * ratio * ratio
            target.pos = Vector<Float>(x, y + otherY) + pos
            target.color = colorDiff.colorForElapsedRatio(elapsedRatio)
            //if (elapsedRatio == 1.0) { target.completed = true }
        }

        public func onComplete(_ target:Particle, _ didFinish:Bool) {
            particlePool.returnItem(target)
        }
    }

    public class Particle : IInitializable {
        public var pos:Vector<Float> = Vector.zero
        public var color:ARGB32 = ARGB32.white //TODO: Was Int
        public var completed = false
        
        public var isAlive: Bool
        //public var completed: Bool
        //private var _canceled: Bool = false

        required public init() {
            isAlive = false
            completed = false
        }
        
        public func initHook() {
            assert(!isAlive, "unexpected")
            pos = Vector.zero
            color = ARGB32.white
        }
        
        public func clean() {
            pos = Vector.zero
            color = ARGB32.white
        }
    }

    let _tweener = Tweener<FastTweenC>()
    var _particlePool = ObjectPool<Particle>(initialCapacity: Helper.NUM_VIEWS)

    public func createParticle(startColor:ARGB32, colorDiff:ARGB32Diff, gravity:Float, ms:Int, vector:Vector<Float>, pos:Vector<Float>) {
        let newParticle = _particlePool.retrieve()
        newParticle.color = startColor
        newParticle.pos = pos
        
        let msF = Float(ms)
        let msD = Double(ms)
        let endGravity = gravity * msF * msF
        let endVector = Vector<Float>(vector.x * msF, vector.y * msF)

        let _ = _tweener.popTween { tween in
            tween.targetPtr = newParticle
            tween.particlePool = _particlePool
            tween.setDuration(msD)
            tween.pos = pos
            tween.endGravity = endGravity
            tween.colorDiff = colorDiff
            tween.endVector = endVector
        }
    }

    public func createParticleBulk(_ data:ContiguousArray<ParticleData>) {
    }

    public func numParticles() -> Int {
        return _tweener.runningTweens()
    }

    public func drawParticles(_ renderer:SDLRenderer, _ surface:SDLSurface, _ windowSize:Size<Int>) throws {
        //Not sure how to draw. If I add it to any kind of list then I'll have to remove it which will be expensive
        //I add a callback so it draws to the surface during the action but that will skew benchmarks
    }

    public func runTweens(_ delta:Double) {
        _tweener.processFrame(delta)
    }

    public func debugInfo() -> String {
        return _tweener.debugInfo()
    }
}

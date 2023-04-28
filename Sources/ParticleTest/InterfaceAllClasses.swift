//
//  InterfaceAllClasses.swift
//  TestGame
//
//  Created by Isaac Paul on 4/12/23.
//

import AniTween
import ChunkedPool
import GameEngine
import Foundation
import SDL2Swift

public class InterfaceAllClasses : IParticleBacking {

    class FastTween : SomeTween {

        public var ID: ContiguousHandle
        
        public var isAlive: Bool
        public var completed: Bool
        private var _canceled: Bool = false
        
        public var particle: ParticleClass! = nil
        public var tracker: Tracker

        required public init() {
            tracker = Tracker(0)
            ID = ContiguousHandle(index: 0)
            isAlive = false
            completed = false
        }
        
        public func initHook() {
            assert(!isAlive, "unexpected")
            tracker = Tracker(0)
        }

        public func clean() {
            _canceled = false
            completed = false
        }

        public func setDuration(_ time:Double ) {
            tracker = .init(time)
        }

        public func cancelAnimation() {
            _canceled = true
        }

        public func processFrame(_ delta:Double) -> Bool {
            
            assert(!completed)
            if (completed) {
                //throw GenericError("Yo")
            }

            if (_canceled) {
                return true
            }
            
            let elapsedRatio = tracker.progress(delta)
            
            action(particle, elapsedRatio)
            let completed2 = elapsedRatio == 1.0
            completed = completed2
            assert (completed2 == particle.completed)
            return completed
        }

        public var pos:Vector<Float> = Vector(0, 0)
        public var endGravity:Float = 0
        public var endVector:Vector<Float> = Vector(0, 0)
        public var colorStart:ARGB32 = ARGB32.black
        public var colorDiff:ARGB32Diff = ARGB32Diff(start: 0, dest: 0)

        public func action(_ target:ParticleClass, _ elapsedRatio:Double) {
            let ratio = Float(elapsedRatio)
            let x = endVector.x * ratio
            let y = endVector.y * ratio
            let otherY = endGravity * ratio * ratio
            var end = y + otherY
            var endx = x
            if (end > 300) {
                let thing = ((end - 300) * 0.2)
                end = 300 - thing
                endx -= thing
                target.pos = Vector<Float>(endx, end) + pos
                target.color = ARGB32.darkRed
            } else {
                target.pos = Vector<Float>(endx, end) + pos
                target.color = colorDiff.colorForElapsedRatio(colorStart, elapsedRatio)
            }
            if (elapsedRatio == 1.0) {
                target.completed = true
            }
        }
    }
    
    static let particlePool = ChunkedPool<ParticleClass>()

    private let _tweener = Tweener<FastTween>()
    private var _lockParticle = pthread_rwlock_t()
    private var _lockTweener = pthread_rwlock_t()
    
    init() {
        pthread_rwlock_init(&_lockParticle, nil)
        pthread_rwlock_init(&_lockTweener, nil)
    }

    public func createParticle(_ particleData:ParticleCreationData) {
        
        //pthread_rwlock_wrlock(&_lockParticle)
        guard let newParticleRef = InterfaceAllClasses.particlePool.rentRefClass( { newParticle in
            newParticle.color = particleData.startColor
            newParticle.pos = particleData.pos
        }) else {
            //pthread_rwlock_unlock(&_lockParticle)
            return
        }
        //pthread_rwlock_unlock(&_lockParticle)
        
        let msF = Float(particleData.ms)
        let msD = Double(particleData.ms)
        let endGravity = particleData.gravity * msF * msF
        let endVector = Vector<Float>(particleData.vector.x * msF, particleData.vector.y * msF)
        let pos = particleData.pos
        let colorDiff = particleData.colorDiff
        
        //pthread_rwlock_wrlock(&_lockTweener)
        _ = _tweener.popTween { tween in
            tween.particle = newParticleRef.item
            tween.setDuration(msD)
            tween.pos = pos
            tween.endGravity = endGravity
            tween.colorDiff = colorDiff
            tween.endVector = endVector
        }
        //pthread_rwlock_unlock(&_lockTweener)
    }

    public func createParticleBulk(_ data:ContiguousArray<ParticleCreationData>) {
        for eachItem in data {
            createParticle(eachItem)
        }
    }

    public func numParticles() -> Int {
        return _tweener.runningTweens()
    }

    public func drawParticles(_ surface:EditableImage, _ windowSize:Size<Int>) throws {
        
        for eachChunk in InterfaceAllClasses.particlePool.data {
            guard let eachChunk = eachChunk else { continue }
            eachChunk.data.forEachUnchecked { eachParticle, i in
                if (eachParticle.isAlive) {
                    let pos = eachParticle.pos
                    let color = eachParticle.color
                    try? surface.drawPoint(Int32(pos.x), Int32(pos.y), color.rawValue)
                }
            }
        }
    }

    public func runTweens(_ delta:Double) {
        _tweener.processFrame(delta)
        
        let pool = InterfaceAllClasses.particlePool
        let chunks = pool.data.count
        var deleted = 0
        var alive = 0
        for w in 0 ..< chunks {
            guard let eachChunk = pool.data[w] else { continue }
            let chunkData = eachChunk.data
            let len = chunkData.count
            for t in 0..<len {
                let eachItem = chunkData[t]
                if (!eachItem.isAlive) { continue }
                
                if (eachItem.cleanOnComplete()) {
                    deleted += 1
                    pool.returnCleanedItem(eachChunk, UInt16(w), UInt16(t))
                } else {
                    alive += 1
                }
            }
        }
    }

    public func debugInfo() -> String {
        return _tweener.debugInfo()
    }
}

//
//  InterfaceStruct.swift
//  TestGame
//
//  Created by Isaac Paul on 3/30/23.
//

import AniTween
import ChunkedPool
import GameEngine
import Foundation
import SDL2Swift

public class InterfaceStruct : IParticleBacking {

    //Transformations are hardcoded instead of passed in an anonymous code block; hence 'fast'
    //We also forgo the onComplete callback
    struct FastTween : SomeTween {

        public var ID: ContiguousHandle
        
        public var isAlive: Bool
        public var completed: Bool
        private var _canceled: Bool = false
        
        public var particleId: ContiguousHandle
        public var tracker: Tracker
        public var particleAction = ParticleAction()

        public init() {
            tracker = Tracker(0)
            ID = ContiguousHandle(index: 0)
            particleId = ContiguousHandle(index: 0)
            isAlive = false
            completed = false
        }
        
        public mutating func initHook() {
            assert(!isAlive, "unexpected")
            tracker = Tracker(0)
        }

        public mutating func clean() {
            _canceled = false
            completed = false
        }

        public mutating func setDuration(_ time:Double) {
            tracker = .init(time)
        }

        public mutating func cancelAnimation() {
            _canceled = true
        }

        public mutating func processFrame(_ delta:Double) -> Bool {
            assert(!completed)

            if (_canceled) {
                onComplete(false)
                return true
            }
            
            let elapsedRatio = tracker.progress(delta)
            
            let chunkIndex = Int(particleId.chunkIndex())
            let itemIndex = Int(particleId.itemIndex())
            if let chunk = InterfaceStruct.particlePool.data[chunkIndex] {
                
                //TODO: Replace with with()
                chunk.data.withUnsafeBufferPointer { (ptr:UnsafeBufferPointer<Particle>) in
                    guard let buffer = ptr.baseAddress else { return }
                    let ptr:UnsafeMutablePointer<Particle> = UnsafeMutablePointer(mutating: buffer.advanced(by: itemIndex))
                    particleAction.action(&ptr.pointee, elapsedRatio)
                }
            }
            let completed2 = elapsedRatio == 1.0
            completed = completed2
            
            return completed
        }

        public func onComplete(_ didFinish:Bool) {
            InterfaceStruct.particlePool.returnItem(particleId)
        }
    }
    
    static let particlePool = ChunkedPool<Particle>()

    private let _tweener = Tweener<FastTween>()
    private var _lockParticle = pthread_rwlock_t()
    private var _lockTweener = pthread_rwlock_t()
    
    init() {
        pthread_rwlock_init(&_lockParticle, nil)
        pthread_rwlock_init(&_lockTweener, nil)
    }
    
    public func createParticle(_ particleData:ParticleCreationData) {
        
        //pthread_rwlock_wrlock(&_lockParticle)
        guard let newParticleId = InterfaceStruct.particlePool.rent( { newParticle in
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
        let colorStart = particleData.startColor
        
        //pthread_rwlock_wrlock(&_lockTweener)
        _ = _tweener.popTween { tween in
            tween.particleId = newParticleId
            tween.setDuration(msD)
            tween.particleAction.pos = pos
            tween.particleAction.endGravity = endGravity
            tween.particleAction.colorStart = colorStart
            tween.particleAction.colorDiff = colorDiff
            tween.particleAction.endVector = endVector
        }
        //pthread_rwlock_unlock(&_lockTweener)
    }

    public func createParticleBulk(_ data:ContiguousArray<ParticleCreationData>) {
        //var len = data.count
        for eachItem in data {
            createParticle(eachItem)
        }
    }

    public func numParticles() -> Int {
        return _tweener.runningTweens()
    }

    public func drawParticles(_ surface:EditableImage, _ windowSize:Size<Int>) throws {
        
        for eachChunk in InterfaceStruct.particlePool.data {
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
        
        let pool = InterfaceStruct.particlePool
        let chunks = pool.data.count
        var deleted = 0
        var alive = 0
        for w in 0 ..< chunks {
            guard let eachChunk = pool.data[w] else { continue }
            
            eachChunk.data.forEachUnchecked { (eachItem:inout Particle, t) in
                if (!eachItem.isAlive) { return }
                
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

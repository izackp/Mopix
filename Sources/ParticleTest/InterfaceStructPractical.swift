//
//  InterfaceStructPractical.swift
//  TestGame
//
//  Created by Isaac Paul on 4/7/23.
//

import AniTween
import ChunkedPool
import GameEngine
import Foundation
import SDL2Swift

public class InterfaceStructPractical : IParticleBacking {

    static let sharedPool = ChunkedPool<Particle>()

    let _tweener = Tweener<Tween>()
    
    private var _lockParticle = pthread_rwlock_t()
    private var _lockTweener = pthread_rwlock_t()
    
    init() {
        pthread_rwlock_init(&_lockParticle, nil)
        pthread_rwlock_init(&_lockTweener, nil)
    }

    public func createParticle(_ data:ParticleCreationData) {
        
        //pthread_rwlock_wrlock(&_lockParticle)
        //A more practical example probably wouldn't use a ChunkedPool. However, this is for testing performance, and any other solution will slow to a crawl
        guard let newParticleRef = InterfaceStructPractical.sharedPool.rentRef( { newParticle in
            newParticle.color = data.startColor
            newParticle.pos = data.pos
        }) else {
            //pthread_rwlock_unlock(&_lockParticle)
            return
        }
        //pthread_rwlock_unlock(&_lockParticle)
        
        let msF = Float(data.ms)
        let endGravity = data.gravity * msF * msF
        let posDiff = Vector<Float>(data.vector.x * msF, data.vector.y * msF)
        let ms = Double(data.ms)
        let startPos = data.pos
        let colorStart = data.startColor
        let colorDiff = data.colorDiff

        //pthread_rwlock_wrlock(&_lockTweener)
        let tween = _tweener.animate(ms, CurveD.exponential.easeOut, { elapsedRatio in
            newParticleRef.with { particle in
                let ratio = Float(elapsedRatio)
                var posOffset = posDiff * ratio
                posOffset.y += endGravity * ratio * ratio
                particle.pos = startPos + posOffset
                particle.color = colorDiff.colorForElapsedRatio(colorStart, elapsedRatio)
            }
        }, { canceled in
            newParticleRef.with { particle in
                particle.completed = true
            }
        })
        
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
        
        for eachChunk in InterfaceStructPractical.sharedPool.data {
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
        
        let pool = InterfaceStructPractical.sharedPool
        let chunks = pool.data.count
        var deleted = 0
        var alive = 0
        for w in 0 ..< chunks {
            guard let eachChunk = pool.data[w] else { continue }
            eachChunk.data.forEachUnchecked { eachParticle, t in
                if (!eachParticle.isAlive) { return }
                
                if (eachParticle.cleanOnComplete()) {
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

/*
 Notes:
 
 //~0.75ms
 eachChunk.data.iterateUnchecked { ptr, t in
     if (!ptr.pointee.isAlive) { return }
     
     if (ptr.pointee.cleanOnComplete()) {
         deleted += 1
         pool.returnCleanedItem(eachChunk, UInt16(w), UInt16(t))
     } else {
         alive += 1
     }
 }
 
 // ~0.75ms
 eachChunk.data.withUnsafeMutableBufferPointer { (ptr:inout UnsafeMutableBufferPointer<Particle>) in
     guard let buffer = ptr.baseAddress else { return }
     let len = ptr.count
     for t in 0 ..< len {
         let eachParticle:UnsafeMutablePointer<Particle> = buffer.advanced(by: t)
         if (!eachParticle.pointee.isAlive) { continue }
         
         if (eachParticle.pointee.cleanOnComplete()) {
             deleted += 1
             pool.returnCleanedItem(eachChunk, UInt16(w), UInt16(t))
         } else {
             alive += 1
         }
     }
 }
 
 //~0.75ms
 eachChunk.data.forEachUnchecked { eachParticle, t in
     if (!eachParticle.isAlive) { return }
     
     if (eachParticle.cleanOnComplete()) {
         deleted += 1
         pool.returnCleanedItem(eachChunk, UInt16(w), UInt16(t))
     } else {
         alive += 1
     }
 }
 
 //~1.9ms
 let len = UInt16(eachChunk.count())
 for t in 0..<len {
     let didDeleted = eachChunk.withPtr(t) { eachParticle in
         return eachParticle.pointee.cleanOnComplete()
     }
     if didDeleted {
         deleted += 1
         //swift doesn't like me accessing memory that I'm modifying
         pool.returnCleanedItem(eachChunk, UInt16(w), t)
     }
 }
 
 //~1.9ms
 let len = UInt16(eachChunk.count())
 for t in 0..<len {
     let didDeleted = eachChunk.with(t) { eachParticle in
         return eachParticle.cleanOnComplete()
     }
     if didDeleted {
         deleted += 1
         //swift doesn't like me accessing memory that I'm modifying
         pool.returnCleanedItem(eachChunk, UInt16(w), t)
     }
 }
 
 //~2.0ms
 eachChunk.data.forEachItem { eachParticle, i in
     if (!eachParticle.isAlive) { return }
     
     if (eachParticle.cleanOnComplete()) {
         deleted += 1
         pool.returnCleanedItem(eachChunk, UInt16(w), UInt16(i))
     } else {
         alive += 1
     }
 }
 */

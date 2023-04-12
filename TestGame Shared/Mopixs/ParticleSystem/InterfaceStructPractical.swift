//
//  InterfaceStructPractical.swift
//  TestGame
//
//  Created by Isaac Paul on 4/7/23.
//

import Foundation
public class InterfaceStructPractical : IParticleBacking {

    static let sharedPool = ChunkedPool<Particle>()

    let _tweener = Tweener<TweenStruct<Particle>>()
    
    private var _lockParticle = pthread_rwlock_t()
    private var _lockTweener = pthread_rwlock_t()
    
    init() {
        pthread_rwlock_init(&_lockParticle, nil)
        pthread_rwlock_init(&_lockTweener, nil)
    }
    //let _particleList = sharedPool
    //ObjectPool<Particle> _particlePool = new ObjectPool<Particle>(Helper.NUM_VIEWS)

    public func createParticle(startColor:ARGB32, colorDiff:ARGB32Diff, gravity:Float, ms:Int, vector:Vector<Float>, pos:Vector<Float>) {
        
        //pthread_rwlock_wrlock(&_lockParticle)
        guard let newParticleId = InterfaceStructPractical.sharedPool.rentRef( { newParticle in
            newParticle.color = startColor
            newParticle.pos = pos
        }) else {
            //pthread_rwlock_unlock(&_lockParticle)
            return
        }
        //pthread_rwlock_unlock(&_lockParticle)
        
        let msF = Float(ms)
        let endGravity = gravity * msF * msF
        let endVector = Vector<Float>(vector.x * msF, vector.y * msF)
        let msD = Double(ms)
        
        //pthread_rwlock_wrlock(&_lockTweener)
        _ = _tweener.popTween { tween in
            tween.targetPtr = newParticleId
            tween.setDuration(msD)
            tween.action = { (target:inout Particle, elapsedRatio:Double) in
                let ratio = Float(elapsedRatio)
                let x = endVector.x * ratio
                let y = endVector.y * ratio
                //let variance = (abs(Float(colorDiff.diffB))/255)
                //let idk = (endGravity) * variance
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
                    target.color = colorDiff.colorForElapsedRatio(elapsedRatio)
                }
                if (elapsedRatio == 1.0) {
                    target.completed = true
                }
            }
        }
        
        //pthread_rwlock_unlock(&_lockTweener)
        //}
    }

    public func createParticleBulk(_ data:ContiguousArray<ParticleData>) {
        //var len = data.count
        for eachItem in data {
            guard let newParticleId = InterfaceStructPractical.sharedPool.rentRef( { newParticle in
                newParticle.color = eachItem.startColor
                newParticle.pos = eachItem.pos
            }) else { return }
            
            let msF = Float(eachItem.ms)
            let msD = Double(eachItem.ms)
            let endGravity = eachItem.gravity * msF * msF
            let endVector = Vector<Float>(eachItem.vector.x * msF, eachItem.vector.y * msF)
            let pos = eachItem.pos
            let colorDiff = eachItem.colorDiff

            _ = _tweener.popTween { tween in
                tween.targetPtr = newParticleId
                tween.setDuration(msD)
                tween.action = { (target:inout Particle, elapsedRatio:Double) in
                    let ratio = Float(elapsedRatio)
                    let x = endVector.x * ratio
                    let y = endVector.y * ratio
                    //let variance = (abs(Float(colorDiff.diffB))/255)
                    //let idk = (endGravity) * variance
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
                        target.color = colorDiff.colorForElapsedRatio(elapsedRatio)
                    }
                    if (elapsedRatio == 1.0) {
                        target.completed = true
                    }
                }
            }
        }
    }

    public func numParticles() -> Int {
        return _tweener.runningTweens()
    }

    public func drawParticles(_ renderer:SDLRenderer, _ surface:SDLSurface, _ windowSize:Size<Int>) throws {
        
        for eachChunk in InterfaceStructPractical.sharedPool.data {
            guard let eachChunk = eachChunk else { continue }
            eachChunk.data.withUnsafeBufferPointer { (ptr:UnsafeBufferPointer<Particle>) in
                guard let buffer = ptr.baseAddress else { return }
                let len = ptr.count
                for t in 0 ..< len {
                    let partPtr:UnsafePointer<Particle> = buffer.advanced(by: t)
                    let eachParticle = partPtr.pointee
                    if (eachParticle.isAlive) {
                        let pos = eachParticle.pos
                        if (pos.x < 0 || pos.y < 0) {
                            continue
                        }
                        let x = Int(pos.x)
                        let y = Int(pos.y)
                        if (x > windowSize.width || y > windowSize.height) { continue }
                        let color = eachParticle.color
                        //try? renderer.setDrawColor(red: color.r, green: color.g, blue: color.b)
                        //try? renderer.drawPoint(x: Int32(x), y: Int32(y))
                        
                        try? surface.drawPoint(Int32(x), Int32(y), color.rawValue)
                    }
                }
            }
        }
    }

    public func runTweens(_ delta:Double) {
        _tweener.processFrame(delta)
        
        let time = CFAbsoluteTimeGetCurrent()
        _tweener.processCompleted()
        let pool = InterfaceStructPractical.sharedPool
        let chunks = pool.data.count
        var deleted = 0
        var alive = 0
        for w in 0 ..< chunks {
            guard let eachChunk = pool.data[w] else { continue }
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
        }
        let deletionTime = CFAbsoluteTimeGetCurrent() - time
        //let other = InterfaceStruct.sharedPool.countLive()
        //print("deletionTime Particles: \(toStrSmart(deletionTime)) deleted:\(deleted) alive:\(alive)")
        
    }

    public func debugInfo() -> String {
        return _tweener.debugInfo()
    }
    
    
    static func handle(_ eachParticle:inout Particle) -> Bool {
        if (eachParticle.isAlive && eachParticle.completed) {
            eachParticle.clean()
            eachParticle.isAlive = false
            return true
        }
        return false
    }
}

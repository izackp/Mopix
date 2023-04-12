//
//  InterfaceClass.swift
//  TestGame
//
//  Created by Isaac Paul on 3/30/23.
//

import Foundation

//NOTE: Not that slow if we avoid using _list
public class InterfaceClass : IParticleBacking {

    public class Particle : IInitializable {
        var pos:Vector<Float> = Vector(0, 0)
        var color:ARGB32 = 0
        var done:Bool = false
        
        required public init() { }
    }

    let _tweener = TweenerContiguousClass<Particle>()
    
    let _particlePool = ObjectPool<Particle>(initialCapacity: Helper.NUM_VIEWS)
    var _list:[Particle] = []
    
    public func createParticle(startColor:ARGB32, colorDiff:ARGB32Diff, gravity:Float, ms:Int, vector:Vector<Float>, pos:Vector<Float>) {
        let newParticle = _particlePool.retrieve()
        newParticle.done = false
        //_list.append(newParticle)
        newParticle.color = startColor
        newParticle.pos = pos
        let msF = Float(ms)
        let msD = Double(ms)
        let endGravity = gravity * msF * msF
        let endVector = Vector<Float>(vector.x * msF, vector.y * msF)
        guard let tween = _tweener.popTween(target: newParticle) else { return }
        let _ = tween.duration(msD)
        tween.action = { (particle:Particle, elapsedRatio:Double) in
            let ratio = Float(elapsedRatio)
            let x = endVector.x * ratio
            let y = endVector.y * ratio
            let otherY = endGravity * ratio * ratio
            particle.pos = Vector<Float>(x, y + otherY) + pos
            particle.color = colorDiff.colorForElapsedRatio(elapsedRatio)
        }
        let pool = _particlePool
        tween.onComplete = { (particle:Particle, didFinish:Bool) in
            pool.returnItem(particle)
            particle.done = true
        }
    }


    public func createParticleBulk(_ data: ContiguousArray<ParticleData>) {
        
    }

    public func numParticles() -> Int {
        return _tweener.totalTweens()
    }

    public func drawParticles(_ renderer:SDLRenderer, _ surface:SDLSurface, _ windowSize:Size<Int>) throws {
        for eachParticle in _list {
            let pos = eachParticle.pos
            if (pos.x < 0 || pos.y < 0) {
                continue
            }
            let x = Int(pos.x)
            let y = Int(pos.y)
            if (x > windowSize.width || y > windowSize.height) { continue }
            let color = eachParticle.color
            //try renderer.setDrawColor(red: color.r, green: color.g, blue: color.b)
            try? surface.drawPoint(Int32(x), Int32(y), color.rawValue)
        }
    }

    public func runTweens(_ delta:Double) {
        _tweener.processFrame(delta)
        /*
        let count = _list.count
        for i in stride(from: count-1, to: 0, by: -1) {
            if (_list[i].done) {
                _list.remove(at: i)
            }
        }*/
    }

    public func debugInfo() -> String {
        return ""
    }
}

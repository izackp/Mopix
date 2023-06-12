//
//  Emitter.swift
//  TestGame
//
//  Created by Isaac Paul on 3/20/23.
//

import Foundation
import GameEngine
import SDL2Swift

public struct ParticleCreationData {
    let startColor:ARGB32
    let colorDiff:ARGB32Diff
    let gravity:Float
    let ms:Int
    let vector:Vector<Float>
    let pos:Vector<Float>
}

public protocol IParticleBacking {
    func createParticle(_ data:ParticleCreationData)
    func createParticleBulk(_ data:ContiguousArray<ParticleCreationData>)
    func numParticles() -> Int
    func runTweens(_ delta:Double)
    func drawParticles(_ surface:EditableImage, _ windowSize:Size<Int>) throws
    func debugInfo() -> String
}

public class Emitter : IDrawable {

    var _life:ClosedRange<Int> = 0...0
    var _startColor:ClosedRange<ARGB32> = 0...0
    var _endColor:ClosedRange<ARGB32> = 255...255
    var _startArea:ClosedRange<Vector<Float>> = Vector.zero...Vector.zero
    var _initialVelocity:ClosedRange<Float> = 0...1
    var _initialDirection:ClosedRange<Float> = 0...0//Degrees
    var _gravity:Float = 0//Fall per ms
    var _backing:IParticleBacking
    
    var _limit:Int = 0
    var _particleBank = Bank(save: 1, cost: 1)
    
    init(_ backing: IParticleBacking) {
        _backing = backing
    }

    public func setNumParticles(_ numParticles:Int, _ perTicks:Int) {
        _particleBank.update(numParticles, perTicks)
    }

    public func setStartArea(_ x:Float, _ y:Float, _ xOffset:Float, _ yOffset:Float) {
        let topLeft = Vector<Float>(x - xOffset, y - yOffset)
        let bottomRight = Vector<Float>(x + xOffset, y + yOffset)
        _startArea = topLeft ... bottomRight
    }

    var created:Int = 0
    public func tick() {
        _particleBank.deposit()
        let available = withdrawParticlesToCreate()
        //var expectedTarget = Backing.NumParticles() + available
        created = available
        createParticlesSync(available)
        //createParticleBulk(available)
        
        //createParticlesThreaded(available)

        //var totalParticles = Backing.NumParticles()
        //Debug.Assert(totalParticles == expectedTarget)
    }

    private func withdrawParticlesToCreate() -> Int {
        var available = Int(_particleBank.withdrawsAvailable())
        let total = available + _backing.numParticles()
        if (_limit != 0 && total > _limit) {
            available -= (total - _limit)
        }
        if (available <= 0) { return 0 }
        let _ = _particleBank.withdraw(available)
        return available
    }

    var doOnce = false
    private func createParticlesSync(_ available:Int) {
        for _ in 0..<available {
            createParticle()
        }
    }

    //NOTE: Wayy too much thead contention; maybe viable if we could 'rent' in bulk
    private func createParticlesThreaded(_ available:Int) {
        let info = ProcessInfo.processInfo
        let threads = info.activeProcessorCount
        DispatchQueue.concurrentPerform(iterations: threads) { (index) in
            createParticleTask(threads, index, available)
            //print(index)
        }
    }

    public func debugInfo() -> String {
        return "Created particles \(created) - \(_backing.debugInfo())"
    }

    public func createParticleTask(_ parts:Int, _ index:Int, _ total:Int) {
        let splitParts = total / parts
        let begin = splitParts * index
        var end = splitParts * (index + 1)
        if (index == parts - 1) {
            end = total
        }

        for _ in begin..<end {
            createParticle()
        }
    }

    public func createParticleBulk(_ count:Int) {
        let newData = ContiguousArray(unsafeUninitializedCapacity: count, initializingWith: { buffer, initializedCount in
            for i in 0..<count {
                let startColor = _startColor.random()
                let endColor = _endColor.random()
                let colorDiff = startColor.diff(endColor)
                buffer[i] = ParticleCreationData(
                    startColor: startColor,
                    colorDiff: colorDiff,
                    gravity: _gravity,
                    ms: _life.random(),
                    vector: Emitter.randomFromPolarRange(_initialDirection, _initialVelocity),
                    pos: _startArea.random()
                )
            }
            initializedCount = count
        })
        //_data = newData
        _backing.createParticleBulk(newData)
        /*
        if let data = _data {
            _backing.createParticleBulk(data)
        } else {
            
        }*/
    }

    public func createParticle() {
        let startColor = _startColor.random()
        let endColor = _endColor.random()
        let colorDiff = startColor.diff(endColor)
        let data = ParticleCreationData(
            startColor: startColor,
            colorDiff: colorDiff,
            gravity: _gravity,
            ms: _life.random(),
            vector: Emitter.randomFromPolarRange(_initialDirection, _initialVelocity),
            pos: _startArea.random()
        )
        _backing.createParticle(data)
    }

    public static func randomFromPolarRange(_ direction:ClosedRange<Float>, _ velocity:ClosedRange<Float>) -> Vector<Float> {
        let dir = direction.random()
        let vel = velocity.random()
        let vector = polarToCartesian_Degrees(dir, vel)
        return vector
    }

    public func drawParticles(_ surface:EditableImage, _ windowSize:Size<Int16>) throws {
        let otherSize = Size<Int>(Int(windowSize.width), Int(windowSize.height))
        try _backing.drawParticles(surface, otherSize)
    }
    
    private var _existingImage:EditableImage? = nil
    private var _id:UInt64? = nil
    
    func getEditableImage(_ size:Size<Int>, _ renderer: GameEngine.RendererClient) throws -> (EditableImage, UInt64) {
        if let existing = _existingImage {
            return (existing, _id!)
        }
        let image = try EditableImage(size)
        try image.fill(color: SDLColor.clear)
        let id = try renderer.loadResource(image)
        _existingImage = image
        _id = id
        return (image, id)
    }
    
    public func draw(_ delta: UInt64, _ renderer: GameEngine.RendererClient) {
        if (renderer.windowSize == Size.zero) {
            return
        }
        step(16)
        do {
            let windowSize = renderer.windowSize.to(Int.self)
            let (image, id) = try getEditableImage(windowSize, renderer)
            try image.fill(color: SDLColor.clear)
            try self.drawParticles(image, renderer.windowSize)
            try renderer.updateImage(id, image)
            //TODO: We don't need to draw particles if nothing changed
            renderer.draw(0, id, Rect(origin: Point.zero, size: windowSize))
        } catch let error {
            print("Unable to draw emitter: \(error.localizedDescription)")
        }
    }

    public func runTweens(_ delta:Double) {
        _backing.runTweens(delta)
    }
    
}

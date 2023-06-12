//
//  TestEmitter.swift
//  TestGame
//
//  Created by Isaac Paul on 4/3/23.
//


import AniTween
import ChunkedPool
import GameEngine
import Foundation
import SDL2Swift
import SDL2

internal func toStrSmart(seconds:Double) -> String {
    if (seconds > 0.1) {
        return String(format: "%.3fs ", seconds)
    }
    return String(format: "%.3fms", seconds * 1000)
}

internal func toStrSmart(_ value:UInt64) -> String {
    let value = Double(value) / Double(SDL_GetPerformanceFrequency())
    return toStrSmart(seconds: value)
}

func buildEmitter(_ noWait:Bool) -> Emitter {
    //Console.CursorVisible = false
    //Console.WriteLine("Type 1 for Stuct or Type 2 for class backing.")
    let backing = InterfaceStruct()//ParticleSystem.InterfaceStruct()
    /*
    while (backing == null) {
        var key = Console.ReadKey().Key
        if (key == ConsoleKey.NumPad0) {
            backing = new ParticleSystem.InterfaceStruct()
        } else if (key == ConsoleKey.NumPad1) {
            backing = new ParticleSystem.InterfaceClass()
        }
    }*/

    let emitter = Emitter(backing)
    if (noWait) {
        emitter._life = 16 ... (160 / 4)
    } else {
        emitter._life = 500 ... 1000
    }

    emitter._startColor = ARGB32.green ... ARGB32.white
    emitter._endColor = ARGB32.darkBlue ... ARGB32.darkBlue
    emitter._initialDirection = (270 + 35.0) ... (270 + 35 + 30.0)
    emitter._initialVelocity = 0.1 ... 0.5
    emitter._gravity = 0.0008
    emitter.setStartArea(0.05, 0.80, 0, 0)
    
    if (noWait) {
        emitter.setNumParticles(200000 / 4, 1)
    } else {
        emitter.setNumParticles(20000, 1)
    }

    return emitter
}

extension Emitter : IUpdate {
    public func step(_ delta:UInt64) {
        self.setStartArea(200, 200, 20, 20)
        
        //var ms = counter.MillisecondsSinceLastCheck()
        //Helper.MeasureBegin()
        var time = SDL_GetPerformanceCounter()
        self.tick()
        let creationTime = SDL_GetPerformanceCounter() - time
        
        time = SDL_GetPerformanceCounter()
        let tweensToRun = self._backing.numParticles()
        self.runTweens(16)
        let runAndDeleteTime = SDL_GetPerformanceCounter() - time
        let executionTime = creationTime + runAndDeleteTime
        let perTween = executionTime / UInt64(tweensToRun)

        //Helper.MeasureBegin()
        let executionTimeFmt = toStrSmart(executionTime)
        let per = toStrSmart(perTween * 50000)
        let creation = toStrSmart(creationTime)
        let runAndDelete = toStrSmart(runAndDeleteTime)
        let debugInfo = self.debugInfo() //
        let msg = "Emitter: Updated \(tweensToRun) tweens: \(executionTimeFmt) -- per 50k: \(per) -- create: \(creation) -- run&delete: \(runAndDelete) -- \(debugInfo)          "

        print(msg)
        
        
        //lastDraw = Helper.MeasureEnd()
    }
}

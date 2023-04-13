//
//  TestEmitter.swift
//  TestGame
//
//  Created by Isaac Paul on 4/3/23.
//

import Foundation

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

extension Emitter {
    public func logic(_ draw:Bool, _ renderer:SDLRenderer, _ surface:SDLSurface, _ windowSize:Size<Int16>) throws {
        self.setStartArea(0.05 * Float(windowSize.width), 0.20 * Float(windowSize.height), 20, 20)
        try surface.fill(color: SDLColor.clear)
        
        //var ms = counter.MillisecondsSinceLastCheck()
        //Helper.MeasureBegin()
        var time = CFAbsoluteTimeGetCurrent()
        self.tick()
        let creationTime = CFAbsoluteTimeGetCurrent() - time
        
        time = CFAbsoluteTimeGetCurrent()
        let tweensToRun = self._backing.numParticles()
        self.runTweens(16)
        let runAndDeleteTime = CFAbsoluteTimeGetCurrent() - time
        let executionTime = creationTime + runAndDeleteTime

        //Helper.MeasureBegin()
        //var y = Math.Max(Console.WindowHeight - 1, 0)
        let executionTimeFmt = toStrSmart(executionTime)
        let per = toStrSmart(Double(executionTime) / Double(tweensToRun) * 50000)
        let creation = toStrSmart(creationTime)
        let runAndDelete = toStrSmart(runAndDeleteTime)
        let debugInfo = self.debugInfo() //
        let msg = "Emitter: Updated \(tweensToRun) tweens: \(executionTimeFmt) -- per 50k: \(per) -- create: \(creation) -- run&delete: \(runAndDelete) -- \(debugInfo)          "
        
        if (draw) {
            try self.drawParticles(renderer, surface, windowSize)
            //ScreenBuffer.Instance.Draw(msg, 0, y)
            //ScreenBuffer.Instance.DrawScreen()
        } else {
            /*
            Console.SetCursorPosition(0, y-2)
            Console.Write(msg)
            Console.SetCursorPosition(0, y-1)
            Console.Write($"Rent Average: {Benchmarks.rent.FormattedAverage(1000000)}ns\t\t\t")
            Console.SetCursorPosition(0, y)
            Console.Write($"Returned Average: {Benchmarks.returned.FormattedAverage(1000000)}ns\t\t")*/
            
            //Console.SetCursorPosition(0, y)
            //print(msg)
        }
        print(msg)
        //lastDraw = Helper.MeasureEnd()
    }
}

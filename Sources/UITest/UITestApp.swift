//
//  UITestApp.swift
//  UITest
//
//  Created by Isaac Paul on 4/13/22.
//

import Foundation
import GameEngine
import SDL2Swift
import SDL2
/*
class EngineWrapped : IUpdate, IDrawable {

    let scene:SIScene
    var totalTime:UInt64 = 0
    var pacing:UInt64 = 0

    init(scene: SIScene) {
        self.scene = scene
    }

    var changes = false
    func step(_ delta: UInt64) {
        totalTime += delta
        scene.step(delta)
        //so ideally we should be told how far in the future this list is
        //but we'll assume it's delta
        pacing = delta
        changes = true
    }
    
    func draw(_ delta: UInt64, _ renderer: GameEngine.RendererClient) {
        if (changes) {
            renderer.defaultTime = totalTime
            scene.draw(delta, renderer) //16ms
            changes = false
        }
    }
}
*/

extension Bundle {
    public static var UITest: Bundle = .module
}

class UITestApp : Application {
    
    let commandRepeater = CommandRepeater()
    //let scene = SIScene()
    static var shared:UITestApp! = nil
    
    override init() throws {
        try super.init()
        UITestApp.shared = self
        
        let newWindow = try FullWindow(parent: self, title: "My Test App", options:[Renderer.Option.presentVsync])
        addWindow(newWindow)
        let resources = URL(fileURLWithPath: Bundle.UITest.resourcePath!).appendingPathComponent("ExternalFiles")
        print("Mounting: \(resources)")
        try vd.mountPath(path: resources)
        if #available(macOS 12, *) {
            let vc = try UIBuilderVC.build()
            newWindow.setRootViewController(vc)
        } else {
            // Fallback on earlier versions
        }
        /*
        let resources = URL(fileURLWithPath: Bundle.SpaceInvaders.resourcePath!).appendingPathComponent("ExternalFiles")
        print("Mounting: \(resources)")
        try vd.mountPath(path: resources)*/

        //let engine = EngineWrapped(scene: scene)
        
        //addFixedListener(engine, msPerTick: 100)
        //addEventListener(scene)
        //newWindow.drawable = engine
        
    }
}

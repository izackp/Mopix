//
//  AppDelegate.swift
//  TestGame
//
//  Created by Isaac Paul on 4/13/22.
//

import Foundation
import GameEngine
import SDL2Swift
import SDL2

class NoIdea {
    
}

/*
 Originally I was planning on abstracting the renderer like a server / client
 
 I'm always mentally fighting about what owns the drawing code.
 We have a ball that rolls around the map
 It's pure state. It doesn't care what its being drawn as
 Though we need to draw it. Events, collisions, walking
 They all need their own animation. Who decides the animation.
 
 ok so lets pretend this is getting rendered in a different process
 let engine = Engine()
 let server //Render Server
 
 server.offsetTime(16ms)
 server.un/loadResources([a, b, c])
 server.draw(ball, x, y)
 Orr
 server.draw([commandList]) //Makes more sense because its compressible
 
 I suppose this an advantage of an ECS.
 
 --=-=-=-=-=-
 In a headless environment (server mode) (not 'render server')
 All the instructions above are not neccessary.
 WE can have traditional draw() functions for the objects
 
 or
 
 we read the state of the world and produce draw commands
 We have the whole world but what to draw?
 What does the client care to see? Stats? a Character? An arbiturary location
 Cameras can be game objects.. Maybe camera is the draw command producer?
 
 how would one produce draws anyways? player walks from 0 to 40 executing 10 different animation frames
 What frame is the player at 40ms in? Does the game know? does the camera know?
 Persistance here is an issue.
 In previous games I used animation anchors which I would play an animation on the anchor
 Over such a long period we would need to store the start time on the game object??
 
 Maybe we can do something more interesting... store each command list like a key frame.
 During a rollback do we rebuild this list? or interpolate from the last frame? I think I would rather
 pop the frame.
 I think it would be neat or user simple to keep track of the animations automatically.
*/

class EngineWrapped : IUpdate {
    
    let scene:SIScene
    var time:UInt64 = 0
    var pacing:UInt64 = 0
    let client:RendererClient = RendererClient()
    
    init(scene: SIScene) {
        self.scene = scene
    }

    func step(_ delta: UInt64) {
        scene.step(delta)
        let commandList = scene.draw(client) //16ms
        //so ideally we should be told how far in the future this list is
        //but we'll assume it's delta
        pacing = delta
        
    }
    
    func draw(_ delta: UInt64) {
        time += delta
        
    }
}

class Forwarder:IUpdate {
    let cb:(_ delta: UInt64)->()
    
    init(cb: @escaping (UInt64) -> ()) {
        self.cb = cb
    }
    func step(_ delta: UInt64) {
        cb(delta)
    }
}

extension Bundle {
    public static var SpaceInvaders: Bundle = .module
}

class TestGameApp : Application {
    
    let commandRepeater = CommandRepeater()
    let scene = SIScene()
    static var shared:TestGameApp! = nil
    
    override init() throws {
        try super.init()
        TestGameApp.shared = self
        
        //TODO: Automatically handle this in window
        #if os(iOS)
        let frame = Frame(x: 0, y: 0, width: 0, height: 0)
        let options:BitMaskOptionSet<SDLWindow.Option> = [.fullscreen]
        #else
        let frame = Frame(x: 0, y: 0, width: 800, height: 600)
        let options:BitMaskOptionSet<SDLWindow.Option> = []
        #endif
        
        let newWindow = try CustomWindow(parent: self, title: "My Test Game", frame: frame, windowOptions: options)
        addWindow(newWindow)
        
        let resources = URL(fileURLWithPath: Bundle.SpaceInvaders.resourcePath!).appendingPathComponent("ExternalFiles")
        print("Mounting: \(resources)")
        try vd.mountPath(path: resources)
        
        addFixedListener(scene, msPerTick: 16)
        addEventListener(scene)
        newWindow.drawable = scene
        
        
    }
    
    
    
}

//
//  Scene.swift
//  
//
//  Created by Isaac Paul on 4/22/23.
//

import SDL2Swift
public protocol IScene {
    func awake()
    func logic(_ delta:UInt64)
    func draw(_ renderer:BatchRenderer)
}
/*
public class Scene {
    
    var engine:Engine
    init(_ engine:Engine) {
        self.engine = engine
    }
    
    open func awake() {
        
    }
    
    open func logic() {
        
    }
    
    open func draw(_ renderer:RendererWrapped) {
        
    }
}*/

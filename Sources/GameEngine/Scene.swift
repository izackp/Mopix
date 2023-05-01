//
//  Scene.swift
//  
//
//  Created by Isaac Paul on 4/22/23.
//

import SDL2Swift

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
}

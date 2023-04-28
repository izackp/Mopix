//
//  PTEngine.swift
//  
//
//  Created by Isaac Paul on 4/25/23.
//

import GameEngine
import SDL2
import SDL2Swift

//TODO: Move into window. Engine not needed
class PTEngine : IEngine {
    internal init(emitter: Emitter? = nil, windowSize: Size<Int16> = .zero) throws {
        self.emitter = emitter ?? buildEmitter(false)
        self.surface = try EditableImage(windowSize.toInt())
        self.windowSize = windowSize
    }
    
    var emitter:Emitter
    var surface:EditableImage
    var windowSize:Size<Int16> = .zero
    
    func updateWindowSize(_ size:Size<Int16>) {
        windowSize = size
        do {
            try surface.resize(size.toInt())
        } catch let error as SDLError {
            print("Error: \(error.debugDescription)")
        } catch {
            print("Error: \(error.localizedDescription)")
        }
    }
    
    func start() { }
    
    func onCommand(_ list: InputCommandList) {
        
    }
    
    func onLogic() {
        //guard let conv = eachWindow as? CustomWindow else { continue }
        //if surface == nil {
        //    surface = try Surface(rgb: (0, 0, 0, 0), size: eachWindow.sdlWindow.size)
        //}
    }
    
    func onDraw(_ renderer: RendererWrapped) {
        try? emitter.logic(true, surface, windowSize)
        renderer.draw(surface, rect: surface.bounds())
    }
    
    
}

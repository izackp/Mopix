//
//  PTWindow.swift
//  
//
//  Created by Isaac Paul on 4/26/23.
//

import GameEngine
import SDL2Swift
import SDL2

public final class PTWindow: LiteWindow {
    
    let engine:PTEngine
    let rendererWrapped:RendererWrapped
    
    init(parent: Application,
                  title: String,
                  frame: Frame<Int>,
                  engine: PTEngine,
                  windowOptions: BitMaskOptionSet<SDLWindow.Option> = [.resizable, .shown],
                  driver: Renderer.Driver = .default,
                  options: BitMaskOptionSet<Renderer.Option> = []) throws {
        
        let sdlWindow = try SDLWindow(title: title,
                                  frame: frame.toSDLTuple(),
                                   options: windowOptions)
        
        let renderer = try Renderer(window: sdlWindow, driver: driver, options: options)
        rendererWrapped = RendererWrapped(renderer: renderer)
        let windowSize = sdlWindow.rendererSize ?? sdlWindow.drawableSize
        self.engine = engine
        engine.updateWindowSize(Size(Int16(windowSize.width), Int16(windowSize.height)))
        try super.init(parent: parent, sdlWindow: sdlWindow, renderer: renderer)
    }
    
    public override func handleEvents(_ events:[SDL_Event]) {
        super.handleEvents(events)
    }
    
    public override func step(_ events: [SDL_Event], _ delta: UInt64) {
        super.step(events, delta)
    }
    
    public override func drawStart() throws {
        try super.drawStart()
    }

    public override func draw(time: UInt64) throws {
        engine.onDraw(rendererWrapped)
    }
}

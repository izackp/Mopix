//
//  PTWindow.swift
//  
//
//  Created by Isaac Paul on 4/26/23.
//

import GameEngine
import SDL2Swift
import SDL2
/*
public final class PTWindow: LiteWindow {
    
    let rendererWrapped:RendererWrapped
    
    //
    var emitter:Emitter
    var surface:EditableImage
    var windowSize:Size<Int16> = .zero
    
    init(parent: Application,
                  title: String,
                  frame: Frame<Int>,
                  emitter: Emitter? = nil,
                  windowOptions: BitMaskOptionSet<SDLWindow.Option> = [.resizable, .shown],
                  driver: Renderer.Driver = .default,
                  options: BitMaskOptionSet<Renderer.Option> = []) throws {
        
        let sdlWindow = try SDLWindow(title: title,
                                  frame: frame.toSDLTuple(),
                                   options: windowOptions)
        
        let renderer = try Renderer(window: sdlWindow, driver: driver, options: options)
        rendererWrapped = RendererWrapped(renderer: renderer)
        let windowSize = sdlWindow.rendererSize ?? sdlWindow.drawableSize
        let wSize = Size(Int16(windowSize.width), Int16(windowSize.height))
        self.windowSize = wSize
        self.emitter = emitter ?? buildEmitter(false)
        self.surface = try EditableImage(wSize.toInt())
        try super.init(parent: parent, sdlWindow: sdlWindow, renderer: renderer)
    }
    
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
        try? emitter.logic(true, surface, windowSize)
        rendererWrapped.draw(surface, rect: surface.bounds())
    }
}
*/

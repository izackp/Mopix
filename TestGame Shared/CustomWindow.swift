//
//  CustomWindow.swift
//  TestGame
//
//  Created by Isaac Paul on 4/13/22.
//

import Foundation
import SDL2

final class CustomWindow: Window {
    
    let rootView = View()
    let atlas:ImageAtlas
    let imageManager:ImageManager
    var randomImage:Image? = nil
    
    override init(parent: Application, title: String, frame: Frame<Int>, windowOptions: BitMaskOptionSet<SDLWindow.Option> = [.resizable, .shown], driver: SDLRenderer.Driver = .default, options: BitMaskOptionSet<SDLRenderer.Option> = []) throws {
        
        let sdlWindow = try SDLWindow(title: title,
                                  frame: frame.toSDLTuple(),
                                   options: windowOptions)
        
        let renderer = try SDLRenderer(window: sdlWindow, driver: driver, options: options)
        atlas = ImageAtlas(renderer)
        imageManager = ImageManager(atlas: atlas, drive: parent.vd)
        
        try super.init(parent: parent, sdlWindow: sdlWindow, renderer: renderer)
        rootView.frame = Frame(origin: Point(0, 0), size: Size(100, 100))
        
        Task { [weak self] in
            do {
                let resources = Bundle.main.bundleURL.appendingPathComponent("Contents").appendingPathComponent("Resources")
                print("Mounting: \(resources)")
                try await self?.parentApp.vd.mountPath(path: resources)
                print("Loading Textures..")
                let sprite = try imageManager.sprite(named:"oryx_16bit_scifi_vehicles_105.bmp")
                print("idk: \(String(describing: sprite?.texture.sourceRect))")
                self?.randomImage = sprite
                
            } catch {
                print("Error: \(error.localizedDescription)")
            }
        }
    }
    
    var _pixelTexture:SDLTexture? = nil
    var pixelTexture:SDLTexture {
        get {
            if let texture = _pixelTexture {
                return texture
            }
            let other = try! buildTexture()
            _pixelTexture = other
            return other
        }
    }
    
    override func draw(time: UInt64) throws {
        try renderer.setDrawColor(red: 0x00, green: 0x00, blue: 0x00, alpha: 0xFF)
        try renderer.clear()
        let texture = pixelTexture
        
        try rootView.draw(renderer, texture: texture)
        if let randomImage = randomImage {
            let dest = randomImage.texture.sourceRect.sdlRect()
            randomImage.draw(renderer, dest)
        }
        
        // render to screen
        renderer.present()
    }
    
    func buildTexture() throws -> SDLTexture {
        let surface = try SDLSurface(rgb: (0, 0, 0, 0), size: (width: 1, height: 1), depth: 32)
        let color = SDLColor.white
        try surface.fill(color: color)
        let surfaceTexture = try SDLTexture(renderer: renderer, surface: surface)
        //try surfaceTexture.setBlendMode([.alpha])
        return surfaceTexture
    }
}

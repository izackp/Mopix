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
        imageManager.loadSystemFonts()
        let results = parent.vd.findByExt("ttf")
        for eachItem in results {
            imageManager.loadFont(eachItem)
        }
        
        try super.init(parent: parent, sdlWindow: sdlWindow, renderer: renderer)
        rootView.frame = Frame(origin: Point(0, 0), size: Size(100, 100))
        
        let lbl = TextView(text: "Abcdefghijklmnopqrstuvwxyz.")//
        lbl.frame = Frame(origin: Point(0, 0), size: Size(300, 40))
        lbl.backgroundColor = SDLColor.pink
        //lbl.textColor = SDLColor.white
        rootView.children.append(lbl)
        
        Task { [weak self] in
            do {

                print("Loading Textures..")
                let sprite = try imageManager.sprite(named:"oryx_16bit_scifi_vehicles_105.bmp")
                print("idk: \(String(describing: sprite?.texture.sourceRect))")
                self?.randomImage = sprite
                
            } catch {
                print("Error: \(error.localizedDescription)")
            }
        }
    }
    
    override func draw(time: UInt64) throws {
        
        let context = UIRenderContext(renderer: renderer, imageManger: imageManager)
        try rootView.draw(context)
        try context.drawAtlas(320, 0)
        /*
        let texture = pixelTexture
        
        try rootView.draw(renderer, texture: texture)
        if let randomImage = randomImage {
            let dest = randomImage.texture.sourceRect.sdlRect()
            randomImage.draw(renderer, dest)
        }*/
        
    }
    
}

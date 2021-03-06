//
//  CustomWindow.swift
//  TestGame
//
//  Created by Isaac Paul on 4/13/22.
//

import Foundation
import SDL2

final class CustomWindow: Window {
    
    var rootViewController:ViewController? = nil
    var rootView:View? = nil
    let atlas:ImageAtlas
    let imageManager:SimpleImageManager
    var randomImage:Image? = nil
    
    override init(parent: Application, title: String, frame: Frame<Int>, windowOptions: BitMaskOptionSet<SDLWindow.Option> = [.resizable, .shown], driver: SDLRenderer.Driver = .default, options: BitMaskOptionSet<SDLRenderer.Option> = []) throws {
        
        let sdlWindow = try SDLWindow(title: title,
                                  frame: frame.toSDLTuple(),
                                   options: windowOptions)
        
        let renderer = try SDLRenderer(window: sdlWindow, driver: driver, options: options)
        atlas = ImageAtlas(renderer)
        imageManager = SimpleImageManager(atlas: atlas, drive: parent.vd)
        imageManager.loadSystemFonts()
        let results = parent.vd.findByExt("ttf")
        for eachItem in results {
            imageManager.loadVDFont(eachItem)
        }
        
        try super.init(parent: parent, sdlWindow: sdlWindow, renderer: renderer)
        let vc = TestViewController.build()
        setRootViewController(vc)
        
        Task { [weak self] in
            print("Loading Textures..")
            let sprite = imageManager.image(named:"oryx_16bit_scifi_vehicles_105.bmp")
            print("idk: \(String(describing: sprite?.texture.sourceRect))")
            self?.randomImage = sprite
        }
    }
    
    func setRootViewController(_ vc:ViewController) {
        self.rootViewController = vc
        let view = vc.view
        self.rootView = view
        view.layout()
        vc.viewWillAppear(false)
        vc.viewDidAppear(false)
    }
    
    override func draw(time: UInt64) throws {
        
        let context = UIRenderContext(renderer: renderer, imageManger: imageManager)
        try rootView?.draw(context)
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

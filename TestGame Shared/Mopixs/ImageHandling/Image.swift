//
//  Image.swift
//  TestGame
//
//  Created by Isaac Paul on 7/2/22.
//

import Foundation
import SDL2

public class Image {
    public init(texture: SubTexture, atlas: ImageAtlas) {
        self.texture = texture
        self.atlas = atlas
    }
    
    let texture:SubTexture
    let atlas:ImageAtlas
    
    deinit {
        atlas.returnTexture(texture)
    }
    
    func draw(_ renderer:SDLRenderer, _ dest:SDL_Rect, _ color:SDLColor = SDLColor.white) {
        let sdlTexture = atlas.listPages[texture.texturePageIndex]
        let source = texture.sourceRect.sdlRect()
        let texture = sdlTexture.texture
        //let test = SDL_Rect(x: 0, y: 0, w: 1024, h: 1024)
        do {
            try texture.setColorModulation(color)
            try renderer.copy(texture, source: source, destination: dest)
            //try renderer.copy(sdlTexture.texture, source: test, destination: test)
        } catch {
            print("Couldn't draw image")
        }
    }
}

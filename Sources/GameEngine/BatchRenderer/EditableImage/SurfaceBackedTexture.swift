//
//  SurfaceBackedTexture.swift
//  
//
//  Created by Isaac Paul on 5/9/23.
//

import SDL2Swift

struct SurfaceBackedTexture {
    internal init(texture: Texture, editIteration:UInt) {
        self.texture = texture
        self.editIteration = editIteration
    }
    
    var editIteration:UInt = 0
    let texture:Texture
}

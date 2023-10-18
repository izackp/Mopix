//
//  SDLFont+Shortcuts.swift
//  
//
//  Created by Isaac Paul on 9/26/23.
//

import Foundation
import SDL2
import SDL2_TTF

extension SDLFont {
    public convenience init(data:Data, ptSize:Int, index:Int = 0, hdpi:UInt32 = 0, vdpi:UInt32 = 0) throws {
        
        var fontPtr:OpaquePointer? = nil
        try data.withUnsafeBytes { (dataPtr:UnsafeRawBufferPointer) in
            let rwops = SDL_RWFromMem(UnsafeMutableRawPointer(mutating: dataPtr.baseAddress), Int32(dataPtr.count))
            fontPtr = TTF_OpenFontIndexDPIRW(rwops, 0, Int32(ptSize), CLong(index), hdpi, vdpi)
        }
        
        let ptr = try fontPtr.sdlThrow(type: type(of: self))
        try self.init(fontPtr: ptr)
    }
}

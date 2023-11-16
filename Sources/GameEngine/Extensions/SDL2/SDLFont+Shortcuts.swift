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
        let throwType = type(of: self)
        var fontPtr:OpaquePointer? = nil
        try data.withUnsafeBytes { (dataPtr:UnsafeRawBufferPointer) in
            let rwopsOpt = SDL_RWFromMem(UnsafeMutableRawPointer(mutating: dataPtr.baseAddress), Int32(dataPtr.count))
            let rwops = try rwopsOpt.sdlThrow(type: throwType)
            fontPtr = TTF_OpenFontIndexDPIRW(rwops, 0, Int32(ptSize), CLong(index), hdpi, vdpi)
        }
        
        let ptr = try fontPtr.sdlThrow(type: throwType)
        self.init(fontPtr: ptr)
    }
    
    public convenience init(data:[UInt8], ptSize:Int, index:Int = 0, hdpi:UInt32 = 0, vdpi:UInt32 = 0) throws {
        let throwType = type(of: self)
        var fontPtr:OpaquePointer? = nil
        try data.withUnsafeBytes { (dataPtr:UnsafeRawBufferPointer) in
            //TODO: Add to SDLSwift api
            let rwopsOpt = SDL_RWFromMem(UnsafeMutableRawPointer(mutating: dataPtr.baseAddress), Int32(dataPtr.count))
            let rwops = try rwopsOpt.sdlThrow(type: throwType)
            fontPtr = TTF_OpenFontIndexDPIRW(rwops, 0, Int32(ptSize), CLong(index), hdpi, vdpi)
        }
        
        let ptr = try fontPtr.sdlThrow(type: throwType)
        self.init(fontPtr: ptr)
    }
}

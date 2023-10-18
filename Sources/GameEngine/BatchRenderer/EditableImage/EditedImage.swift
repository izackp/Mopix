//
//  EditedImage.swift
//  
//
//  Created by Isaac Paul on 5/9/23.
//

import SDL2
import SDL2Swift

public class EditedImage : ReadOnlyImage {
    
    public init(from:ReadOnlyImage) throws {
        let copy = try from._data.copy()
        super.init(id: from.id, data: copy)
    }

    public func editPixelData<Result>(_ body:(_ pixelData:MutableRawPixelData) throws -> (Result)) throws -> Result {
        return try _data.withMutablePixelData(body)
    }
    
    public func editPixelData(_ body:(_ pixelData:MutableRawPixelData) throws -> ()) throws {
        try _data.withMutablePixelData(body)
    }
}

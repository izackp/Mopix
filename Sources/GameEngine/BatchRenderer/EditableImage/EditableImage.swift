//
//  EditableImage.swift
//  
//
//  Created by Isaac Paul on 5/9/23.
//

import SDL2
import SDL2Swift

//TODO: Make cached compositions drop on resource reset
public class EditableImage {
    let id:UInt64
    let _data:PixelData
    var _dirty:Bool = false //incr editIter when uploading
    //var editIteration:UInt = 0
    
    public init(id: UInt64, data: PixelData, editIteration: UInt = 0) {
        self.id = id
        _data = data
        //self.editIteration = editIteration
    }
    
    public init(id: UInt64, _ size:Size<Int>, editIteration: UInt = 0) throws {
        self.id = id
        _data = try PixelData(size)
        //self.editIteration = editIteration
    }

    public func size() -> Size<Int> {
        return _data.size()
    }
    
    public func bounds() -> Rect<Int> {
        return Rect(origin: .zero, size: size())
    }
    
    func withPixelData<Result>(_ body:(_ pixelData:RawPixelData) throws -> (Result)) throws -> Result {
        return try _data.withPixelData(body)
    }
    
    func editPixelData<Result>(_ body:(_ pixelData:MutableRawPixelData) throws -> (Result)) throws -> Result {
        _dirty = true
        return try _data.withMutablePixelData(body)
    }
    
    internal func getSurface() -> Surface {
        return _data._surface
    }
    /*
    internal func incrementEdit() {
        if (editIteration == UInt.max) {
            editIteration = 0
        } else {
            editIteration += 1
        }
    }*/
    
    func applyChanges() {
        
    }
}

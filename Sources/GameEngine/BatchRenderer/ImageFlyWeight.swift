//
//  File.swift
//  
//
//  Created by Isaac Paul on 8/3/23.
//

public class ImageFlyWeight : ImageResource {
    
    internal var _id:UInt64
    
    public var id:UInt64 {
        get { return _id }
        //internal set(value) { _id = value }
    }
    
    public init(id: UInt64) {
        self._id = id
    }
    
    deinit {
        
    }
}

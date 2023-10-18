//
//  Image.swift
//  
//
//  Created by Isaac Paul on 9/20/23.
//

public class Image : ImageResource {
    public init(id: UInt64, size: Size<UInt>) {//, url: VDUrl) {
        self._id = id
        //self.url = url
        self.size = size
    }
    
    private let _id:UInt64
    //let url:VDUrl
    let size:Size<UInt>
    
    public var id:UInt64 {
        get { return _id }
        //private set(value) { _id = value }
    }
    
    deinit {
        
    }
}

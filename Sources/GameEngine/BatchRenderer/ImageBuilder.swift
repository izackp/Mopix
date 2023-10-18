//
//  ImageBuilder.swift
//  
//
//  Created by Isaac Paul on 9/21/23.
//

//TODO: make cmdList use enum. Some random testing seems to suggest
//that enum associated values will be contigous
public class ImageBuilder: IDraw {
    public init(client: RendererClient, cmdList: [DrawCmdImage] = []) {
        self.client = client
        self.cmdList = cmdList
    }
    
    let client:RendererClient
    var cmdList:[DrawCmdImage] = []
    private var _clipRect:Rect<DValue>? = nil
    private var _offset:Point<DValue> = .zero
    
    public func draw(_ image:DrawCmdImage) {
        cmdList.append(image)
    }
    
    public func finalize() -> UInt64 {
        return 0
    }
    
    public func createImage(_ block:(_ context:IDraw) throws -> (), size:Size<DValue>) throws -> UInt64 {
        let builder = ImageBuilder(client: client)
        try block(builder)
        return builder.finalize()
    }
    
    func withClipRect(_ frame:Rect<DValue>?, _ block:(_ context:IDraw) throws -> ()) rethrows {
        let previousClipRect = _clipRect
        setClipRect(frame)
        try block(self)
        setClipRect(previousClipRect)
    }
    
    func setClipRect(_ frame:Rect<DValue>?) {
        _clipRect = frame
    }
    
    func getClipRect() -> Rect<DValue>? {
        return _clipRect
    }
    
    func withOffset(_ point:Point<DValue>, _ block:(_ context:IDraw) throws -> ()) rethrows {
        let previousOffset = _offset
        setOffset(point)
        try block(self)
        setOffset(previousOffset)
    }
    
    func setOffset(_ offset:Point<DValue>) {
        _offset = offset
    }
    
    func getOffset() -> Point<DValue> {
        return _offset
    }
}

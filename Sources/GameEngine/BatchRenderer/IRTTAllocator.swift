//
//  IRTTAllocator.swift
//
//
//  Allocates an AtlasImage suitable for render-to-texture composition.
//  Used by UICommandContext.createAndDrawToTexture.
//

public protocol IRTTAllocator: AnyObject {
    func allocate(size: Size<DValue>) throws -> AtlasImage
}

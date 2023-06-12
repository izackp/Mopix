//
//  IResourceCache.swift
//  
//
//  Created by Isaac Paul on 5/22/23.
//

public protocol IResourceCache {
    //Called when references go bad
    func invalidateCache(_ client:RendererClient)

    //
    func loadResources(_ client:RendererClient) throws
    func unloadResources(_ client:RendererClient)
}

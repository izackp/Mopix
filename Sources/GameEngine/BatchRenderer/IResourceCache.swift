//
//  IResourceCache.swift
//  
//
//  Created by Isaac Paul on 5/22/23.
//

public protocol IResourceCache {
    //Called when references go bad
    func invalidateCache(_ client: DisplayRenderClient)

    func loadResources(_ client: DisplayRenderClient) throws
    func unloadResources(_ client: DisplayRenderClient)
}

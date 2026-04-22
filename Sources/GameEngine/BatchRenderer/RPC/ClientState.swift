//
//  ClientState.swift
//
//
//  Per-client state for the Display Server RPC layer.
//

import Foundation

@MainActor
public final class ClientState {
    public let clientId: ClientId
    public let name: String
    public let version: UInt32

    public var logicalSize: Size<Int>
    public var scale: Float
    public var resourceLingerMs: UInt32
    public var viewportFrame: Rect<Int>

    public var ownedResources: Set<ResHandle>
    public var activeSounds: Set<SoundHandle>
    public var packNames: Set<String>
    public var rawViewportCommands: [DrawCmd]

    public init(
        clientId: ClientId,
        name: String,
        version: UInt32,
        logicalSize: Size<Int>,
        scale: Float = 1.0,
        resourceLingerMs: UInt32,
        viewportFrame: Rect<Int> = .zero,
        ownedResources: Set<ResHandle> = [],
        activeSounds: Set<SoundHandle> = [],
        packNames: Set<String> = [],
        rawViewportCommands: [DrawCmd] = []
    ) {
        self.clientId = clientId
        self.name = name
        self.version = version
        self.logicalSize = logicalSize
        self.scale = scale
        self.resourceLingerMs = resourceLingerMs
        self.viewportFrame = viewportFrame
        self.ownedResources = ownedResources
        self.activeSounds = activeSounds
        self.packNames = packNames
        self.rawViewportCommands = rawViewportCommands
    }
}

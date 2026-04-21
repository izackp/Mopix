//
//  DisplayRPCTypes.swift
//
//
//  Shared RPC types for the Display Server protocol.
//  See docs/display-server-rpc-spec.md.
//

import Foundation

public typealias ClientId    = UInt32
public typealias ResHandle   = UInt64
public typealias SoundHandle = UInt64
public typealias RequestId   = UInt64

public enum ResourceKind {
    case image
    case sound
    case font
}

public struct WindowConfig {
    public var title: String
    public var fullscreen: Bool
    public var vsync: Bool

    public init(title: String, fullscreen: Bool, vsync: Bool) {
        self.title = title
        self.fullscreen = fullscreen
        self.vsync = vsync
    }
}

public struct EdgeInsets {
    public var top: Int
    public var right: Int
    public var bottom: Int
    public var left: Int

    public init(top: Int, right: Int, bottom: Int, left: Int) {
        self.top = top
        self.right = right
        self.bottom = bottom
        self.left = left
    }

    public static var zero: EdgeInsets {
        EdgeInsets(top: 0, right: 0, bottom: 0, left: 0)
    }
}

public enum CompositionCmd {
    case createEditableImage(handle: ResHandle, size: Size<Int>)
    case createProceduralImage(handle: ResHandle, size: Size<Int>)
    case copyToEditable(handle: ResHandle, source: ResHandle)
    case copyToProceduralImage(handle: ResHandle, source: ResHandle)
}

public struct SoundParams {
    public var volume: Float
    public var pan: Float
    public var pitch: Float
    public var loop: Bool
    public var fadeInMs: UInt32

    public init(
        volume: Float = 1.0,
        pan: Float = 0.0,
        pitch: Float = 1.0,
        loop: Bool = false,
        fadeInMs: UInt32 = 0
    ) {
        self.volume = volume
        self.pan = pan
        self.pitch = pitch
        self.loop = loop
        self.fadeInMs = fadeInMs
    }
}

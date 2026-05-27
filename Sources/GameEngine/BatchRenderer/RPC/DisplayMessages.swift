//
//  DisplayMessages.swift
//
//
//  Client ↔ Server message envelopes for the Display Server protocol.
//  See docs/display-server-rpc-spec.md.
//

import Foundation

public enum ClientMessage {

    // MARK: - Session

    case connect(
        requestId: RequestId,
        name: String,
        version: UInt32,
        logicalSize: Size<Int>,
        resourceLingerMs: UInt32
    )

    case disconnect

    case ping(requestId: RequestId, clientTick: UInt64)

    case setDisplayConfig(
        requestId: RequestId,
        logicalSize: Size<Int>,
        scale: Float
    )

    case setWindowConfig(requestId: RequestId, config: WindowConfig)

    // MARK: - Resource Packs

    case uploadPack(
        requestId: RequestId,
        name: String,
        data: [UInt8]
    )

    // MARK: - Resources

    case loadResource(
        requestId: RequestId,
        url: VDUrl,
        kind: ResourceKind,
        density: Float = 1.0,
        preferredHandle: ResHandle? = nil
    )

    case uploadResource(
        requestId: RequestId,
        url: VDUrl,
        kind: ResourceKind,
        density: Float = 1.0,
        data: [UInt8],
        preferredHandle: ResHandle? = nil
    )

    case requestPixelData(
        requestId: RequestId,
        handle: ResHandle
    )

    case uploadRawPixels(
        requestId: RequestId,
        url: VDUrl,
        size: Size<Int>,
        data: [UInt8],
        preferredHandle: ResHandle? = nil
    )

    case updateResource(
        requestId: RequestId,
        handle: ResHandle,
        size: Size<Int>,
        data: [UInt8]
    )

    case releaseResource(handle: ResHandle)

    // MARK: - Render

    case sendFrame(
        clientTick: UInt64,
        compositions: [CompositionCmd],
        cmds: [DrawCmd]
    )

    case screenshot(requestId: RequestId)

    // MARK: - Audio

    case playSound(
        requestId: RequestId,
        handle: ResHandle,
        params: SoundParams
    )

    case stopSound(handle: SoundHandle, fadeOutMs: UInt32 = 0)
    case pauseSound(handle: SoundHandle)
    case resumeSound(handle: SoundHandle)

    case updateSound(handle: SoundHandle, params: SoundParams)

    case stopAllSounds
}

public enum ServerMessage {
    case response(Response)
    case event(ServerEvent)
}

public struct Response {
    public let requestId: RequestId
    public let status: ResponseStatus
    public let body: ResponseBody?

    public init(requestId: RequestId, status: ResponseStatus, body: ResponseBody? = nil) {
        self.requestId = requestId
        self.status = status
        self.body = body
    }
}

public enum ResponseStatus: UInt16 {
    case ok          = 200
    case badRequest  = 400
    case notFound    = 404
    case conflict    = 409
    case serverError = 500
}

public enum ResponseBody {
    case pong(serverTick: UInt64)
    case image(handle: ResHandle, size: Size<Int>)
    case sound(handle: ResHandle, durationMs: UInt32, channels: UInt8)
    case font(handle: ResHandle, family: String)
    case pixelData(handle: ResHandle, size: Size<Int>, data: [UInt8])
    case soundStarted(handle: SoundHandle)
    case errorDetail(String)
}

public enum ServerEvent {

    case viewportChanged(
        physicalSize: Size<Int>,
        safeArea: EdgeInsets
    )

    case drawError(
        clientTick: UInt64,
        handle: ResHandle,
        reason: String
    )

    case compositionError(
        clientTick: UInt64,
        compositionIndex: Int,
        handle: ResHandle,
        reason: String
    )

    case soundFinished(handle: SoundHandle)
}

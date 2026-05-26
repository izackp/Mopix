//
//  DisplayClient.swift
//
//
//  Game-friendly client for the Display Server RPC protocol.
//  Sends ClientMessage values over a DisplayTransport and receives ServerMessage
//  responses and events. All request/response pairs are matched by RequestId via
//  CheckedContinuation. Fire-and-forget messages use Task and never block the caller.
//
//  No SDL2 imports — depends only on shared RPC types and engine geometry.
//

import Foundation

// MARK: - Errors

public enum DisplayClientError: Error, LocalizedError {
    case notConnected
    case unexpectedResponseBody
    case serverError(ResponseStatus, String)

    public var errorDescription: String? {
        switch self {
        case .notConnected:
            return "DisplayClient is not connected"
        case .unexpectedResponseBody:
            return "Server returned an unexpected response body"
        case let .serverError(status, detail):
            return "Server error \(status.rawValue): \(detail)"
        }
    }
}

// MARK: - DisplayClient

/// Client for the Display Server RPC protocol.
///
/// Usage:
/// 1. Create with a `DisplayTransport` (e.g. `InProcessTransport.makePair().client`)
/// 2. Call `connect(...)` to establish a session and start the receive loop
/// 3. Use `loadResource`, `sendFrame`, `playSound`, etc.
/// 4. Consume events via `events` (an `AsyncStream<ServerEvent>`)
/// 5. Call `disconnect()` when done
///
/// Thread-safety: all methods are `async` or fire-and-forget via `Task`. The
/// internal state (pending continuations, frame buffers) is guarded by an actor.
/// The public drawing methods (`drawCmd`, `bufferComposition`, etc.) are actor-isolated
/// to `DisplayClientActor`.
public actor DisplayClient {

    // MARK: - Public state

    /// Server-assigned client ID. Valid only after `connect` succeeds.
    public private(set) var clientId: ClientId = 0

    /// Current logical size as reported by setDisplayConfig / connect.
    public private(set) var logicalSize: Size<Int>

    /// Current physical viewport size as reported by the server.
    public private(set) var viewportSize: Size<Int> = Size(0, 0)

    /// Unsolicited server events delivered to the caller.
    public let events: AsyncStream<ServerEvent>

    // MARK: - Private state

    private let transport: any DisplayTransport

    /// Yields to the `events` stream.
    private let eventContinuation: AsyncStream<ServerEvent>.Continuation

    /// Pending request continuations keyed by RequestId.
    private var pending: [RequestId: CheckedContinuation<Response, Error>] = [:]

    /// Monotonically increasing request ID counter.
    private var nextRequestId: RequestId = 1

    /// DrawCmds buffered until `sendFrame` is called.
    private var cmdBuffer: [DrawCmd] = []

    /// CompositionCmds buffered until `sendFrame` is called.
    private var compositionBuffer: [CompositionCmd] = []

    /// Background task consuming the transport's incoming stream.
    private var receiveTask: Task<Void, Never>?

    // MARK: - Init

    public init(transport: any DisplayTransport, logicalSize: Size<Int> = Size(320, 240)) {
        self.transport = transport
        self.logicalSize = logicalSize

        var cont: AsyncStream<ServerEvent>.Continuation!
        self.events = AsyncStream { cont = $0 }
        self.eventContinuation = cont
    }

    deinit {
        receiveTask?.cancel()
        eventContinuation.finish()
    }

    // MARK: - Connection lifecycle

    /// Connect to the display server and start the receive loop.
    ///
    /// - Parameters:
    ///   - name: Friendly name for this client (for logging/debug)
    ///   - version: Client protocol version
    ///   - logicalSize: Logical canvas size in client coordinate space
    ///   - resourceLingerMs: How long released resources are held before being freed (for rollback support)
    public func connect(
        name: String,
        version: UInt32,
        logicalSize: Size<Int>,
        resourceLingerMs: UInt32 = 0
    ) async throws {
        self.logicalSize = logicalSize

        // Start the background receive loop before sending connect so we don't miss the response.
        startReceiveLoop()

        let requestId = nextId()
        let response = try await sendRequest(
            .connect(
                requestId: requestId,
                name: name,
                version: version,
                logicalSize: logicalSize,
                resourceLingerMs: resourceLingerMs
            ),
            requestId: requestId
        )
        guard response.status == .ok else {
            throw errorFrom(response)
        }
        // clientId is server-assigned; the current spec sends no body for connect.
        // We track it once we have it (future: server could send it in body).
    }

    /// Disconnect from the server. Outstanding pending requests will be cancelled.
    public func disconnect() {
        receiveTask?.cancel()
        receiveTask = nil
        fireAndForget(.disconnect)
        failAllPending(with: DisplayClientError.notConnected)
        eventContinuation.finish()
    }

    // MARK: - Ping

    /// Ping the server and return the server tick.
    public func ping(clientTick: UInt64) async throws -> UInt64 {
        let requestId = nextId()
        let response = try await sendRequest(.ping(requestId: requestId, clientTick: clientTick), requestId: requestId)
        guard response.status == .ok else { throw errorFrom(response) }
        if case let .pong(serverTick) = response.body {
            return serverTick
        }
        throw DisplayClientError.unexpectedResponseBody
    }

    // MARK: - Display config

    /// Update logical canvas size and scale together.
    public func setDisplayConfig(logicalSize: Size<Int>, scale: Float) async throws {
        let requestId = nextId()
        let response = try await sendRequest(
            .setDisplayConfig(requestId: requestId, logicalSize: logicalSize, scale: scale),
            requestId: requestId
        )
        guard response.status == .ok else { throw errorFrom(response) }
        self.logicalSize = logicalSize
    }

    /// Update window properties (title, fullscreen, vsync).
    public func setWindowConfig(_ config: WindowConfig) async throws {
        let requestId = nextId()
        let response = try await sendRequest(
            .setWindowConfig(requestId: requestId, config: config),
            requestId: requestId
        )
        guard response.status == .ok else { throw errorFrom(response) }
    }

    // MARK: - Resource packs

    /// Upload a resource pack for the server to mount as a VirtualDrive package.
    /// Re-uploading the same name hot-reloads the pack.
    public func uploadPack(name: String, data: [UInt8]) async throws {
        let requestId = nextId()
        let response = try await sendRequest(
            .uploadPack(requestId: requestId, name: name, data: data),
            requestId: requestId
        )
        guard response.status == .ok else { throw errorFrom(response) }
    }

    // MARK: - Resources

    /// Load a resource from a mounted pack by VDUrl. Returns the response body
    /// (`.image`, `.sound`, or `.font`).
    public func loadResource(url: VDUrl, kind: ResourceKind, density: Float = 1.0, preferredHandle: ResHandle? = nil) async throws -> ResponseBody {
        let requestId = nextId()
        let response = try await sendRequest(
            .loadResource(requestId: requestId, url: url, kind: kind, density: density, preferredHandle: preferredHandle),
            requestId: requestId
        )
        guard response.status == .ok else { throw errorFrom(response) }
        guard let body = response.body else { throw DisplayClientError.unexpectedResponseBody }
        return body
    }

    /// Upload a single resource as raw bytes. Returns the response body.
    public func uploadResource(url: VDUrl, kind: ResourceKind, density: Float = 1.0, data: [UInt8], preferredHandle: ResHandle? = nil) async throws -> ResponseBody {
        let requestId = nextId()
        let response = try await sendRequest(
            .uploadResource(requestId: requestId, url: url, kind: kind, density: density, data: data, preferredHandle: preferredHandle),
            requestId: requestId
        )
        guard response.status == .ok else { throw errorFrom(response) }
        guard let body = response.body else { throw DisplayClientError.unexpectedResponseBody }
        return body
    }

    /// Request raw pixel data (RGBA, row-major) for a server-held resource.
    public func requestPixelData(handle: ResHandle) async throws -> ResponseBody {
        let requestId = nextId()
        let response = try await sendRequest(
            .requestPixelData(requestId: requestId, handle: handle),
            requestId: requestId
        )
        guard response.status == .ok else { throw errorFrom(response) }
        guard let body = response.body else { throw DisplayClientError.unexpectedResponseBody }
        return body
    }

    /// Release a resource handle. Fire-and-forget — the server holds it for the
    /// `resourceLingerMs` declared at connect before freeing.
    public func releaseResource(handle: ResHandle) {
        fireAndForget(.releaseResource(handle: handle))
    }

    // MARK: - Render / frame submission

    /// Buffer a composition command to be processed before DrawCmds in the next frame.
    public func bufferComposition(_ cmd: CompositionCmd) {
        compositionBuffer.append(cmd)
    }

    // Composition helpers — buffer the matching CompositionCmd.

    public func createEditableImage(handle: ResHandle, size: Size<Int>) {
        compositionBuffer.append(.createEditableImage(handle: handle, size: size))
    }

    public func createProceduralImage(handle: ResHandle, size: Size<Int>) {
        compositionBuffer.append(.createProceduralImage(handle: handle, size: size))
    }

    public func copyToEditable(handle: ResHandle, source: ResHandle) {
        compositionBuffer.append(.copyToEditable(handle: handle, source: source))
    }

    public func copyToProceduralImage(handle: ResHandle, source: ResHandle) {
        compositionBuffer.append(.copyToProceduralImage(handle: handle, source: source))
    }

    /// Send the buffered draw and composition commands as a single frame.
    /// Fire-and-forget per spec — does not await an acknowledgement.
    public func sendFrame(clientTick: UInt64) {
        let compositions = compositionBuffer
        let cmds = cmdBuffer
        compositionBuffer.removeAll(keepingCapacity: true)
        cmdBuffer.removeAll(keepingCapacity: true)
        fireAndForget(.sendFrame(clientTick: clientTick, compositions: compositions, cmds: cmds))
    }

    /// Send the buffered draw and composition commands and await transport delivery.
    public func sendFrameAndWait(clientTick: UInt64) async {
        let compositions = compositionBuffer
        let cmds = cmdBuffer
        compositionBuffer.removeAll(keepingCapacity: true)
        cmdBuffer.removeAll(keepingCapacity: true)
        await transport.send(.sendFrame(clientTick: clientTick, compositions: compositions, cmds: cmds))
    }

    /// Take a screenshot of the current composed frame. Returns (size, RGBA bytes).
    public func screenshot() async throws -> (Size<Int>, [UInt8]) {
        let requestId = nextId()
        let response = try await sendRequest(.screenshot(requestId: requestId), requestId: requestId)
        guard response.status == .ok else { throw errorFrom(response) }
        if case let .pixelData(_, size, data) = response.body {
            return (size, data)
        }
        throw DisplayClientError.unexpectedResponseBody
    }

    // MARK: - Audio

    /// Start playback of a sound resource. Returns the active playback handle.
    public func playSound(handle: ResHandle, params: SoundParams) async throws -> SoundHandle {
        let requestId = nextId()
        let response = try await sendRequest(
            .playSound(requestId: requestId, handle: handle, params: params),
            requestId: requestId
        )
        guard response.status == .ok else { throw errorFrom(response) }
        if case let .soundStarted(soundHandle) = response.body {
            return soundHandle
        }
        throw DisplayClientError.unexpectedResponseBody
    }

    /// Stop playback with an optional fade-out. Fire-and-forget.
    public func stopSound(handle: SoundHandle, fadeOutMs: UInt32 = 0) {
        fireAndForget(.stopSound(handle: handle, fadeOutMs: fadeOutMs))
    }

    /// Pause active playback. Fire-and-forget.
    public func pauseSound(handle: SoundHandle) {
        fireAndForget(.pauseSound(handle: handle))
    }

    /// Resume paused playback. Fire-and-forget.
    public func resumeSound(handle: SoundHandle) {
        fireAndForget(.resumeSound(handle: handle))
    }

    /// Apply live parameter update (volume, pan, pitch). Fire-and-forget.
    public func updateSound(handle: SoundHandle, params: SoundParams) {
        fireAndForget(.updateSound(handle: handle, params: params))
    }

    /// Stop all active sounds immediately. Fire-and-forget.
    public func stopAllSounds() {
        fireAndForget(.stopAllSounds)
    }

    // MARK: - ID generation

    /// Generate a new unique ResHandle. Mirrors the `genId()` pattern used elsewhere.
    public func genHandle() -> ResHandle {
        Xoroshiro.shared.randomBytes()
    }

    // MARK: - Internal receive loop

    private func startReceiveLoop() {
        guard receiveTask == nil else { return }
        let transport = self.transport

        receiveTask = Task { [weak self] in
            // Capture the stream before the first suspension so the actor
            // isolation check in InProcessTransport.ClientEnd.incoming is satisfied.
            if let clientEnd = transport as? InProcessTransport.ClientEnd {
                for await message in clientEnd.incoming {
                    guard let self else { break }
                    await self.receive(message)
                }
            }
            // For other transport kinds the caller is expected to forward
            // ServerMessages by calling receive(_:) directly.
        }
    }

    /// Deliver an incoming ServerMessage (called by the receive loop or externally
    /// for transport implementations that aren't InProcessTransport).
    public func receive(_ message: ServerMessage) {
        switch message {
        case let .response(response):
            handleResponse(response)
        case let .event(event):
            handleEvent(event)
        }
    }

    // MARK: - Private helpers

    private func handleResponse(_ response: Response) {
        if let continuation = pending.removeValue(forKey: response.requestId) {
            continuation.resume(returning: response)
        } else {
            // Response arrived for an unknown or already-timed-out requestId — discard.
            // Note: timeout is not yet implemented; responses are held indefinitely.
        }
    }

    private func handleEvent(_ event: ServerEvent) {
        // Update local state for certain events before forwarding.
        switch event {
        case let .viewportChanged(physicalSize, _):
            viewportSize = physicalSize
        default:
            break
        }
        eventContinuation.yield(event)
    }

    /// Send a message that expects a Response keyed by `requestId`.
    /// The caller awaits the returned Response directly.
    private func sendRequest(_ message: ClientMessage, requestId: RequestId) async throws -> Response {
        return try await withCheckedThrowingContinuation { continuation in
            pending[requestId] = continuation
            Task { [transport] in
                await transport.send(message)
            }
        }
    }

    /// Send a message that never expects a response (fire-and-forget).
    private func fireAndForget(_ message: ClientMessage) {
        let transport = self.transport
        Task {
            await transport.send(message)
        }
    }

    /// Produce the next monotonically-increasing RequestId.
    private func nextId() -> RequestId {
        let id = nextRequestId
        nextRequestId &+= 1
        return id
    }

    /// Convert a non-OK Response into a thrown error.
    private func errorFrom(_ response: Response) -> Error {
        if case let .errorDetail(detail) = response.body {
            return DisplayClientError.serverError(response.status, detail)
        }
        return DisplayClientError.serverError(response.status, "no detail")
    }

    /// Fail all outstanding pending continuations with `error`.
    private func failAllPending(with error: Error) {
        let all = pending
        pending.removeAll()
        for continuation in all.values {
            continuation.resume(throwing: error)
        }
    }
}

// MARK: - IDraw conformance

extension DisplayClient: @preconcurrency IDraw {
    /// Buffer a draw command. Satisfies `IDraw.drawCmd(_:)`.
    /// Called from actor-isolated context only.
    public func drawCmd(_ cmd: DrawCmd) {
        cmdBuffer.append(cmd)
    }

    /// Create a composed image by executing `block` on an `IDraw` context.
    /// Returns a new `ResHandle` that game code can use in subsequent draw commands.
    ///
    /// Implementation note: this creates an editable image on the server and draws
    /// into it. It returns the handle immediately; the frame must be sent before
    /// the image is visible on the viewport.
    nonisolated public func createImage(_ block: (_ context: IDraw) throws -> (), size: Size<DValue>) throws -> UInt64 {
        let handle = Xoroshiro.shared.randomBytes()
        let intSize = Size<Int>(Int(size.width), Int(size.height))

        // Capture the draw commands produced by `block`.
        let builder = DisplayClientImageBuilder(target: handle)
        try block(builder)
        let cmds = builder.commands

        Task { [weak self] in
            guard let self else { return }
            await self.bufferCreateEditableImage(handle: handle, size: intSize, cmds: cmds)
        }
        return handle
    }

    private func bufferCreateEditableImage(handle: ResHandle, size: Size<Int>, cmds: [DrawCmd]) {
        compositionBuffer.append(.createEditableImage(handle: handle, size: size))
        cmdBuffer.append(contentsOf: cmds)
    }
}

// MARK: - ImageBuilder helper for createImage

/// Collects DrawCmds targeted at a specific editable image handle.
/// Used by `DisplayClient.createImage(_:size:)`.
private final class DisplayClientImageBuilder: IDraw {
    let target: ResHandle
    private(set) var commands: [DrawCmd] = []

    init(target: ResHandle) {
        self.target = target
    }

    func drawCmd(_ cmd: DrawCmd) {
        // Re-target the command to the editable image handle.
        let retargeted = DrawCmd(
            target: target,
            animationId: cmd.animationId,
            parentAnimationId: cmd.parentAnimationId,
            dest: cmd.dest,
            color: cmd.color,
            alpha: cmd.alpha,
            z: cmd.z,
            rotation: cmd.rotation,
            rotationPoint: cmd.rotationPoint,
            clippingRect: cmd.clippingRect,
            flip: cmd.flip,
            time: cmd.time,
            type: cmd.type
        )
        commands.append(retargeted)
    }

    func createImage(_ block: (IDraw) throws -> (), size: Size<DValue>) throws -> UInt64 {
        // Nested image creation is not supported inside a composition block.
        // Return a zero handle so callers fail visibly rather than silently.
        return 0
    }
}

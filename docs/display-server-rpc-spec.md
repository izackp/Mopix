# Display Server RPC Specification — MVP

A network-capable display server supporting rendering, audio, and multi-client split screen.
The spec defines the abstraction layer only; serialization format and transport are implementation details.

---

## Key Decisions

### Clients own resource metadata, server owns resources
When a resource is loaded, the server returns metadata (image size, sound duration, font family)
to the client. The client caches this locally and can answer queries like "how wide is this sprite?"
without round-tripping the server. The server holds the actual texture/audio data.

### Logical coordinates, server scales
Each client declares a `logicalSize` at connect time (e.g. 320×240). All draw commands are
submitted in that coordinate space. The server scales to fit the client's physical viewport.
The client never thinks about physical pixels unless it explicitly reads `scaleFactor` from the
connection response (e.g. to select a higher-density asset variant).

### Camera / game world scaling is the client's problem
The server scales a fixed logical canvas. Whether to scale up or reveal more game world when
the viewport changes is a game design decision — the client's camera does that transform before
submitting draw commands. The server never knows about world space.

### Viewports are automatic, not an API
Clients do not request or configure viewports. The server assigns screen regions automatically
based on how many clients are connected and rebalances when they join or leave. All affected
clients receive a `viewportChanged` notification and adapt their own camera/UI layout.

### Split screen layout policy
| Clients | Layout |
|---|---|
| 1 | Full screen |
| 2 | 50/50 horizontal split |
| 3 | Left half (client 1) + right half split vertically (clients 2 & 3) |
| 4 | Quadrants |
| 5+ | Uniform grid (TBD) |

### Fixed tick + interpolation
The server runs a fixed-tick loop with interpolation for smooth display, mirroring the existing
`RendererClient` / `DrawCmdInterpolator` pattern. Clients tag each frame batch with their
`clientTick`. The server interpolates between the last two received batches.

### Fire-and-forget frames, async resource responses
`sendFrame` is fire-and-forget for MVP — no per-frame ack. Resource operations
(`declareResource`, `uploadResource`) are matched by `requestId` so clients can track load state
asynchronously.

### Missing resource: skip + error
If a `DrawCmd` references a resource that hasn't been loaded yet, the server silently skips
that command and emits a `drawError` response. The client is responsible for ensuring resources
are ready before drawing.

### Audio is part of the same server
Sound playback is handled by the display server, not a separate service. Audio resources follow
the same declare/upload/release lifecycle as image and font resources.

### Resource handles on disconnect
When a client disconnects ungracefully (connection lost), its resources are held briefly to
support reconnection. On clean `disconnect`, resources are released. This is an implementation
detail not exposed in the protocol.

### Error codes are strings in MVP
`reason` fields are human-readable strings for MVP. A future revision should replace them with
a typed enum to avoid stringly-typed error handling across language boundaries.

---

## Conventions

- All messages are fire-and-forget unless marked `// → response`.
  The server sends responses asynchronously; clients match them by `requestId`.
- `ResHandle` and `SoundHandle` IDs are random and client-generated (mirrors existing `genId()`
  pattern), except `ClientId` which is server-assigned on connect.
- Draw commands referencing an unloaded resource are silently skipped; the server emits a
  `drawError` response.

---

## Shared Types

```swift
typealias ClientId    = UInt32
typealias ResHandle   = UInt64   // image, font, or sound resource
typealias SoundHandle = UInt64   // active playback instance
typealias RequestId   = UInt64   // client-generated, for matching async responses

struct Size<T>    { let width: T; let height: T }
struct Rect<T>    { let x: T; let y: T; let width: T; let height: T }
struct EdgeInsets { let top, right, bottom, left: Int }

enum ResourceKind { case image, sound, font }
```

---

## Draw Commands

Extends the existing `DrawCmd` / `DrawCmdType` with a `text` case.
The server implicitly targets the submitting client's viewport — there is no viewport field.

```swift
struct DrawCmd {
    let animationId: UInt64
    let parentAnimationId: UInt64
    let dest: Rect<Int>
    let color: SDLColor
    let alpha: Float
    let z: Int
    let rotation: Float
    let rotationPoint: Point<Int>
    let clippingRect: Rect<Int>
    let flip: RendererFlip
    var time: UInt64
    let type: DrawCmdType
}

enum DrawCmdType {
    case image(resourceId: ResHandle)
    case fill
    case view(borderColor: SDLColor, borderWidth: Int)
    case text(fontHandle: ResHandle, content: String, size: Float, align: TextAlignment)
    case rtt  // reserved
}

enum TextAlignment { case left, center, right }
```

---

## Client → Server Messages

```swift
enum ClientMessage {

    // ── Session ──────────────────────────────────────────────────────────────

    /// → Connected | ErrorResponse
    case connect(
        requestId: RequestId,
        name: String,
        version: UInt32,
        logicalSize: Size<Int>      // client's coordinate space, e.g. 320×240
    )

    case disconnect

    /// → Pong
    case ping(requestId: RequestId, clientTick: UInt64)


    // ── Resources ────────────────────────────────────────────────────────────

    /// Server loads from its own VirtualDrive.
    /// → ImageReady | SoundReady | FontReady | ResourceError
    case declareResource(
        requestId: RequestId,
        url: VDUrl,
        kind: ResourceKind,
        density: Float = 1.0        // for selecting @2x/@4x asset variants
    )

    /// Client pushes raw bytes to the server.
    /// → ImageReady | SoundReady | FontReady | ResourceError
    case uploadResource(
        requestId: RequestId,
        url: VDUrl,
        kind: ResourceKind,
        density: Float = 1.0,
        data: [UInt8]
    )

    case releaseResource(handle: ResHandle)


    // ── Render ───────────────────────────────────────────────────────────────

    /// Submit one frame's draw commands. Fire-and-forget.
    /// Implicitly targets this client's viewport.
    /// Commands referencing unloaded resources are skipped; server emits DrawError.
    case sendFrame(
        clientTick: UInt64,
        cmds: [DrawCmd]
    )


    // ── Audio ─────────────────────────────────────────────────────────────────

    /// → SoundStarted | ErrorResponse
    case playSound(
        requestId: RequestId,
        handle: ResHandle,
        params: SoundParams
    )

    case stopSound(handle: SoundHandle, fadeOutMs: UInt32 = 0)
    case pauseSound(handle: SoundHandle)
    case resumeSound(handle: SoundHandle)

    /// Live parameter update — takes effect immediately (volume fade, pan shift, etc.)
    case updateSound(handle: SoundHandle, params: SoundParams)

    case stopAllSounds
}

struct SoundParams {
    var volume: Float = 1.0       // 0–1
    var pan: Float = 0.0          // -1 left, +1 right
    var pitch: Float = 1.0
    var loop: Bool = false
    var fadeInMs: UInt32 = 0
}
```

---

## Server → Client Messages

```swift
enum ServerMessage {

    // ── Session ───────────────────────────────────────────────────────────────

    case connected(
        requestId: RequestId,
        clientId: ClientId,
        physicalSize: Size<Int>,    // actual pixels assigned to this client's viewport
        scaleFactor: Float,         // physical pixels per logical point
        safeArea: EdgeInsets        // margins for notch / overscan
    )

    /// Sent to all affected clients when layout rebalances (client joins or leaves).
    case viewportChanged(
        physicalSize: Size<Int>,
        scaleFactor: Float,
        safeArea: EdgeInsets
    )

    case pong(requestId: RequestId, serverTick: UInt64)


    // ── Resources ─────────────────────────────────────────────────────────────

    case imageReady(
        requestId: RequestId,
        handle: ResHandle,
        size: Size<Int>             // logical pixels at density 1.0
    )

    case soundReady(
        requestId: RequestId,
        handle: ResHandle,
        durationMs: UInt32,
        channels: UInt8             // 1 = mono, 2 = stereo
    )

    case fontReady(
        requestId: RequestId,
        handle: ResHandle,
        family: String
    )

    case resourceError(
        requestId: RequestId,
        url: VDUrl,
        reason: String
    )


    // ── Render ────────────────────────────────────────────────────────────────

    /// Emitted when a DrawCmd references a resource that is not loaded.
    /// clientTick identifies which frame the skipped command came from.
    case drawError(
        clientTick: UInt64,
        handle: ResHandle,
        reason: String
    )


    // ── Audio ─────────────────────────────────────────────────────────────────

    case soundStarted(requestId: RequestId, handle: SoundHandle)

    /// Emitted on natural playback end or after a stop-with-fade completes.
    case soundFinished(handle: SoundHandle)


    // ── Errors ────────────────────────────────────────────────────────────────

    case errorResponse(requestId: RequestId, reason: String)
}
```

---

## Error Reasons

Strings for MVP; replace with a typed enum in a future revision.

| Reason | Situation |
|---|---|
| `"resource_not_found"` | URL not present in server's VirtualDrive |
| `"unsupported_format"` | File format not supported |
| `"atlas_full"` | Texture atlas has no space remaining |
| `"resource_not_loaded"` | DrawCmd references a handle that was never loaded |
| `"unknown_client"` | Message received from an unrecognised ClientId |
| `"version_mismatch"` | Client and server protocol versions are incompatible |

---

## Session Flow Example

```
Client                              Server
  |                                   |
  |-- connect(logicalSize: 320×240) →|
  |←-- connected(clientId:1, physicalSize:1280×720, scaleFactor:2.0, safeArea:…)
  |                                   |
  |-- declareResource(player.bmp)   →|
  |←-- imageReady(handle:0xABCD, size:16×16)
  |                                   |
  |-- declareResource(jump.wav)     →|
  |←-- soundReady(handle:0xEF01, durationMs:400, channels:1)
  |                                   |
  |-- sendFrame(tick:1, cmds:[…])   →|   ← fire and forget each tick
  |-- sendFrame(tick:2, cmds:[…])   →|
  |                                   |
  |-- playSound(0xEF01, …)          →|
  |←-- soundStarted(handle:0x0002)
  |                                   |
  |                  [client 2 connects — layout rebalances]
  |←-- viewportChanged(physicalSize:640×720, scaleFactor:2.0, safeArea:…)
  |                                   |
  |-- disconnect                    →|
```

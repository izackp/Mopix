# Display Server RPC Specification — MVP

A network-capable display server supporting rendering, audio, and multi-client split screen.
The spec defines the abstraction layer only; serialization format, wire layout, and transport
are implementation details.

---

## Supported Features

- **Rendering** — images, solid fills, UI views, text, shapes
- **Image composition** — draw commands can target an editable image instead of the viewport; supports RTT, palette swaps, dynamic textures
- **Audio** — play, stop, pause, resume, live parameter updates (volume, pan, pitch)
- **Screenshot** — client requests pixel data of the current composed frame
- **Window configuration** — fullscreen, vsync, window title
- **Multi-client split screen** — automatic viewport assignment and rebalancing
- **Client-controlled scale** — client sets its own logical-to-physical scale
- **Resource packs** — client uploads a bundle; server mounts it as a VirtualDrive package
- **Resource management** — load from mounted pack (read-only, hot-reloadable), upload individual assets (client-owned), create editable images, release, linger
- **Image derivation** — client requests pixel data for a server-held resource, modifies locally, uploads result as a new resource
- **Rollback support** — released resources linger for a client-configured duration before the server frees them

---

## Key Decisions

> These are decisions made by the project owner. They represent intentional design choices,
> not defaults or suggestions.

### The client always initiates and is the source of all resources
The client produces resource packs and uploads them for the server to mount. Individual
resources are loaded from a mounted pack by VDUrl, or uploaded directly as raw bytes.
Atlas packing is a server implementation detail. Either side can compose images (RTT, text
rasterization); the client may retrieve server-composed results via `requestPixelData`.
The server never pulls.

### Logical coordinates, client sets scale
Each client declares a `logicalSize` at connect time (e.g. 320×240). All draw commands are
submitted in that coordinate space. The client may update both `logicalSize` and `scale`
at runtime via `setDisplayConfig`, typically in response to a `viewportChanged` event.
Both values are always required together to keep serialization simple. Scale is fractional.
The server applies whatever the client specifies — it does not compute or impose either value.

### Camera / game world scaling is the client's problem
The client submits draw commands in logical coordinates. Whether to scale up or reveal more
game world when the viewport changes is a game design decision — the client's camera does that
transform before submitting draw commands. The server never knows about world space.

### Viewport assignment is a server implementation detail
The server assigns physical screen regions to clients internally. How it divides the screen
(e.g. split screen policy) is not part of this spec. When the assignment changes, the server
emits a `viewportChanged` event with the new physical size. The client may call
`setDisplayConfig` in response, but is not required to.

### Fixed tick + interpolation
The server runs a fixed-tick loop with interpolation for smooth display, mirroring the existing
`RendererClient` / `DrawCmdInterpolator` pattern. Clients tag each frame batch with their
`clientTick`. The server interpolates between the last two received batches.

### Fire-and-forget frames, async resource responses
`sendFrame` is fire-and-forget for MVP — no per-frame ack. Resource operations are matched by
`requestId` so clients can track load state asynchronously.

### Missing resource: skip + error
If a `DrawCmd` references a resource that hasn't been loaded yet, the server silently skips
that command and emits a `drawError` event. The client is responsible for ensuring resources
are ready before drawing.

### Audio is part of the same server
Sound playback is handled by the display server, not a separate service. Audio resources follow
the same load/upload/release lifecycle as image and font resources.

### Resource linger duration is set by the client
When a client connects it declares a `resourceLingerMs` value. Released resources are held for
that duration before the server frees them. This exists to support rollback — when a rollback
occurs, resources the client had already released may still be needed in the frames that follow.
A value of `0` means immediate release.

### Procedural editable images maintain a command journal
The server records every DrawCmd targeting a `procedural` editable image. On hot-reload the
server re-copies the updated source into the image and replays the full journal on top. The
journal resets when `copyToEditable` or `createEditableImage` is called again for that handle.
`userGenerated` editable images are never recorded or affected by hot-reload — the client
explicitly opts out of server-managed regeneration to preserve user data exactly as drawn.

### Pack re-upload is a hot-reload
When a pack is re-uploaded with the same name, the server remounts it. Existing handles that
refer to resources still present in the new pack update to the new content. Resources removed
from the pack stay in memory while handles reference them, but new `loadResource` calls for
those URLs will fail.

### Responses use HTTP-inspired status codes with an opaque body
All request responses share a single envelope: a status code and an optional body. The body is
raw bytes deserialized by the caller into the appropriate type based on the request kind.
Unsolicited server messages (events) are a separate category with no `requestId`.
Wire layout is an implementation detail.

### Error body is a string
When a response has a non-200 status code, the body is a human-readable string describing the
error. No further structure is defined.

---

## Conventions

- All client messages are fire-and-forget unless they carry a `requestId`, in which case the
  server sends a `Response` asynchronously.
- `ResHandle` and `SoundHandle` IDs are random and client-generated (mirrors existing `genId()`
  pattern), except `ClientId` which is server-assigned on connect.
- Draw commands referencing an unloaded resource are silently skipped; the server emits a
  `drawError` event.

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

struct WindowConfig {
    var title: String
    var fullscreen: Bool
    var vsync: Bool
}

/// Processed before DrawCmds in sendFrame. Client generates the handle upfront.
/// Fails with a compositionError event if the handle is already in use — server logs and continues.
enum CompositionCmd {
    case createEditableImage(handle: ResHandle, size: Size<Int>, kind: EditableImageKind)
    case copyToEditable(handle: ResHandle, source: ResHandle, kind: EditableImageKind)
}

enum EditableImageKind {
    case procedural     // server records DrawCmd journal; re-copies source + replays on hot-reload
    case userGenerated  // server does not record; never affected by hot-reload
}
```

---

## Draw Commands

`DrawCmd` gains a `target` field and new shape types. `target` is a `UInt64` where `0` means
the client's viewport and any other value is the `ResHandle` of an editable image.

```swift
struct DrawCmd {
    let target: UInt64              // 0 = viewport; non-zero = editable image ResHandle
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
    case line(to: Point<Int>, thickness: Int)     // color from DrawCmd.color
    case circle(radius: Int, filled: Bool)         // centered on DrawCmd.dest origin
    case rect(filled: Bool)                        // uses DrawCmd.dest
}

enum TextAlignment { case left, center, right }
```

---

## Client → Server Messages

```swift
enum ClientMessage {

    // ── Session ──────────────────────────────────────────────────────────────

    /// → Response (body: none) | Response (error)
    case connect(
        requestId: RequestId,
        name: String,
        version: UInt32,
        logicalSize: Size<Int>,     // client's coordinate space, e.g. 320×240
        resourceLingerMs: UInt32    // how long released resources are held before freeing
    )

    case disconnect

    /// → Response (body: pong)
    case ping(requestId: RequestId, clientTick: UInt64)

    /// Update logical canvas size and scale together.
    /// → Response (body: none) | Response (error)
    case setDisplayConfig(
        requestId: RequestId,
        logicalSize: Size<Int>,
        scale: Float
    )

    /// Update window properties.
    /// → Response (body: none) | Response (error)
    case setWindowConfig(requestId: RequestId, config: WindowConfig)


    // ── Resource Packs ───────────────────────────────────────────────────────

    /// Upload a resource pack for the server to mount as a VirtualDrive package.
    /// Re-uploading the same name remounts with new content (hot-reload).
    /// → Response (body: none) | Response (error)
    case uploadPack(
        requestId: RequestId,
        name: String,               // becomes the vd:// host, e.g. vd://Assets/…
        data: [UInt8]               // complete pack bundle
    )


    // ── Resources ────────────────────────────────────────────────────────────

    /// Load a resource from a mounted pack by VDUrl.
    /// → Response (body: image | sound | font) | Response (error)
    case loadResource(
        requestId: RequestId,
        url: VDUrl,
        kind: ResourceKind,
        density: Float = 1.0        // for selecting @2x/@4x asset variants
    )

    /// Upload a single resource as raw bytes.
    /// → Response (body: image | sound | font) | Response (error)
    case uploadResource(
        requestId: RequestId,
        url: VDUrl,
        kind: ResourceKind,
        density: Float = 1.0,
        data: [UInt8]
    )

    /// Request raw pixel data for a server-held resource (e.g. a server-composed image).
    /// → Response (body: pixelData) | Response (error)
    case requestPixelData(
        requestId: RequestId,
        handle: ResHandle
    )

    /// Release the resource. Server holds it for resourceLingerMs before freeing.
    case releaseResource(handle: ResHandle)


    // ── Render ───────────────────────────────────────────────────────────────

    /// Submit one frame. Fire-and-forget.
    /// compositions are processed first in order, then cmds are executed.
    /// DrawCmds with target=0 draw to the viewport; non-zero targets draw to an editable image.
    /// Commands referencing unloaded resources are skipped; server emits drawError event.
    case sendFrame(
        clientTick: UInt64,
        compositions: [CompositionCmd],
        cmds: [DrawCmd]
    )

    /// → Response (body: pixelData) | Response (error)
    case screenshot(requestId: RequestId)


    // ── Audio ─────────────────────────────────────────────────────────────────

    /// → Response (body: soundStarted) | Response (error)
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

Server messages are either **responses** (tied to a `requestId`) or **events** (unsolicited).

```swift
enum ServerMessage {
    case response(Response)   // always tied to a requestId
    case event(ServerEvent)   // unsolicited
}

// ── Responses ────────────────────────────────────────────────────────────────

struct Response {
    let requestId: RequestId
    let status: ResponseStatus
    let body: ResponseBody?   // nil for ack-only success; wire layout is implementation detail
}

enum ResponseStatus: UInt16 {
    case ok          = 200
    case badRequest  = 400    // malformed message
    case notFound    = 404    // resource URL not found in mounted pack
    case conflict    = 409    // e.g. name collision
    case serverError = 500
}

enum ResponseBody {
    case pong(serverTick: UInt64)
    case image(handle: ResHandle, size: Size<Int>)          // logical pixels at density 1.0
    case sound(handle: ResHandle, durationMs: UInt32, channels: UInt8)
    case font(handle: ResHandle, family: String)
    case pixelData(handle: ResHandle, size: Size<Int>, data: [UInt8])  // raw RGBA, row-major; for requestPixelData and screenshot
    case soundStarted(handle: SoundHandle)
    case errorDetail(String)                                           // non-200 responses
}

// ── Events ───────────────────────────────────────────────────────────────────

enum ServerEvent {

    /// Sent to all affected clients when their physical viewport region changes.
    case viewportChanged(
        physicalSize: Size<Int>,
        safeArea: EdgeInsets
    )

    /// A DrawCmd was skipped because its resource handle was not loaded.
    /// clientTick identifies which frame the skipped command came from.
    case drawError(
        clientTick: UInt64,
        handle: ResHandle,
        reason: String
    )

    /// A CompositionCmd failed (e.g. handle already in use). Catastrophic programmer error.
    /// Server logs and continues; the handle retains its existing content.
    case compositionError(
        clientTick: UInt64,
        compositionIndex: Int,
        handle: ResHandle,
        reason: String
    )

    /// Natural playback end, or stop-with-fade completed.
    case soundFinished(handle: SoundHandle)
}
```

---

## Status Codes

| Code | Meaning |
|---|---|
| 200 | Success |
| 400 | Malformed message |
| 404 | Resource URL not found in any mounted pack |
| 409 | Name conflict |
| 500 | Server error |

## Error Body

When a response has a non-200 status code, the body is a human-readable string. Examples:

| Status | Example string |
|---|---|
| 404 | `"resource not found in any mounted pack"` |
| 400 | `"unsupported format"` |
| 500 | `"atlas full"` |
| 400 | `"unknown client"` |
| 400 | `"version mismatch"` |

---

## Supported Cases and Flows

### Basic Session

```
Client                              Server
  |                                   |
  |-- connect(logicalSize:320×240,  →|
  |     resourceLingerMs:500)         |
  |←-- response(200, body:none)       |  ← connected; clientId assigned
  |←-- event(.viewportChanged(        |  ← server reports initial physical size
  |     physicalSize:1280×720, …))    |
  |-- setDisplayConfig(             →|  ← client sets logical size + scale
  |     logicalSize:320×240,          |
  |     scale:4.0)                    |
  |←-- response(200, body:none)       |
  |                                   |
  |-- uploadPack(name:"Assets", …)  →|
  |←-- response(200, body:none)       |  ← pack mounted as vd://Assets/…
  |                                   |
  |-- loadResource(vd://Assets/      →|
  |     player.bmp, .image)           |
  |←-- response(200, body:.image(handle:0xABCD, size:16×16))
  |                                   |
  |-- loadResource(vd://Assets/      →|
  |     jump.wav, .sound)             |
  |←-- response(200, body:.sound(handle:0xEF01, durationMs:400, channels:1))
  |                                   |
  |-- sendFrame(tick:1, cmds:[…])   →|   ← fire and forget each tick
  |-- sendFrame(tick:2, cmds:[…])   →|
  |                                   |
  |-- playSound(0xEF01, …)          →|
  |←-- response(200, body:.soundStarted(handle:0x0002))
  |                                   |
  |             [client 2 connects — layout rebalances]
  |←-- event(.viewportChanged(physicalSize:640×720, …))
  |-- setDisplayConfig(             →|  ← client adapts to new physical size
  |     logicalSize:320×240,          |
  |     scale:2.0)                    |
  |                                   |
  |-- disconnect                    →|
```

---

### Server-Side Image Composition

The client creates an editable image, draws onto it within the same frame, then uses the
result as a source in subsequent frames.

```
Client                              Server
  |                                   |
  |  [client generates handle 0xCAFE] |
  |                                   |
  |-- sendFrame(tick:N,             →|
  |     compositions:[               |
  |       .copyToEditable(           |
  |          handle:0xCAFE,          |
  |          source:0xABCD)],        |  ← copy read-only sprite into editable image
  |     cmds:[                       |
  |       DrawCmd(target:0xCAFE,     |  ← draw a tint onto the editable image
  |         type:.fill, color:red),  |
  |       DrawCmd(target:0,          |  ← draw the original to viewport as normal
  |         type:.image(0xABCD))])   |
  |                                   |
  |-- sendFrame(tick:N+1, cmds:[    →|  ← use the composed result
  |     DrawCmd(target:0,            |
  |       type:.image(0xCAFE))])     |
```

---

### Client Creating an Image from Another Image

The client reads pixel data for a server-composed resource, modifies it locally
(e.g. palette swap, procedural overlay, masking), then uploads the result as a new resource.

```
Client                              Server
  |                                   |
  |  [handle 0xABCD already loaded]   |
  |                                   |
  |-- requestPixelData(0xABCD)      →|
  |←-- response(200, body:.pixelData(handle:0xABCD, size:16×16, data:[…]))
  |                                   |
  |  [client modifies pixels locally] |
  |                                   |
  |-- uploadResource(               →|
  |     vd://derived/player_hurt.bmp, |
  |     .image, data:[…])             |
  |←-- response(200, body:.image(handle:0xDEAD, size:16×16))
  |                                   |
  |-- sendFrame(tick:N, cmds:[      →|
  |     .image(resourceId:0xDEAD)…])  |
```

The source handle (`0xABCD`) is unaffected. The derived handle (`0xDEAD`) is a fully
independent resource with its own lifecycle.

---

### Rollback Support

The client sets `resourceLingerMs` at connect time. Released resources remain available on the
server for that duration. If the client rolls back to a prior tick and re-renders old frames,
those resources are still present without a reload round-trip.

```
Client                              Server
  |                                   |
  |-- connect(resourceLingerMs:2000)→|   ← 2 second linger window
  |←-- response(200, body:none)
  |                                   |
  |-- loadResource(explosion.bmp)   →|
  |←-- response(200, body:.image(handle:0xBEEF, …))
  |                                   |
  |-- sendFrame(tick:100, …)        →|
  |-- sendFrame(tick:101, …)        →|
  |-- releaseResource(0xBEEF)       →|   ← server holds for 2000ms
  |                                   |
  |  [rollback to tick 99 detected]   |
  |                                   |
  |-- sendFrame(tick:99, cmds:[     →|   ← 0xBEEF still valid; server draws fine
  |     .image(resourceId:0xBEEF)…])  |
  |-- sendFrame(tick:100, …)        →|
  |                                   |
  |  [2000ms elapses since release]   |
  |                                   |   ← server frees 0xBEEF
```

If the linger window expires before a rollback re-uses the resource, the next `sendFrame`
referencing it will produce a `drawError` event — the client must re-load or re-upload.

---

### User Draws Over a Read-Only Image

The client creates a procedural editable copy of a pack sprite. User strokes are DrawCmds
targeting that image — the server records them in the journal. On hot-reload the server
re-copies the updated sprite and replays all strokes automatically. No client intervention needed.

```
Client                              Server
  |                                   |
  |-- sendFrame(tick:1,             →|
  |     compositions:[               |
  |       .copyToEditable(           |
  |         handle:0xCANVAS,         |
  |         source:0xSPRITE,         |
  |         kind:.procedural)],      |  ← server copies sprite; starts recording journal
  |     cmds:[                       |
  |       DrawCmd(target:0xCANVAS,   |  ← user stroke; server records in journal
  |         type:.line(…))])         |
  |                                   |
  |-- sendFrame(tick:2, cmds:[      →|
  |     DrawCmd(target:0xCANVAS,     |  ← another stroke; appended to journal
  |       type:.line(…)),            |
  |     DrawCmd(target:0,            |  ← draw result to viewport
  |       type:.image(0xCANVAS))])   |
  |                                   |
  |        [pack hot-reloaded]        |
  |                                   |   ← server re-copies updated sprite into 0xCANVAS
  |                                   |   ← server replays both strokes from journal
  |                                   |
  |-- sendFrame(tick:3, cmds:[      →|  ← client unaware; result is correct automatically
  |     DrawCmd(target:0,            |
  |       type:.image(0xCANVAS))])   |
```

---

### Pack Hot-Reload

The client re-uploads a pack with the same name. Existing handles update to reflect new
content. Resources removed from the pack linger in memory while handles reference them,
but new `loadResource` calls for those URLs will fail with 404.

```
Client                              Server
  |                                   |
  |-- uploadPack(name:"Assets", v1) →|
  |←-- response(200, body:none)
  |                                   |
  |-- loadResource(vd://Assets/     →|
  |     player.bmp, .image)           |
  |←-- response(200, body:.image(handle:0xABCD, …))
  |                                   |
  |  [assets updated on disk]         |
  |                                   |
  |-- uploadPack(name:"Assets", v2) →|   ← remounts; 0xABCD updates to new content
  |←-- response(200, body:none)
  |                                   |
  |-- sendFrame(tick:N, cmds:[      →|   ← draws updated player.bmp automatically
  |     .image(resourceId:0xABCD)…])  |
```

<objective>
Implement the server side of the Display Server RPC protocol.

The server receives `ClientMessage` values, processes them, and sends back `ServerMessage`
responses and events. It wraps the existing rendering infrastructure (ResourceStore,
DrawCmdInterpolator, AtlasLoader) and adds multi-client support, audio, composition commands,
resource packs, and rollback linger.

Read `docs/display-server-rpc-spec.md` for the full specification.
</objective>

<context>
This is the Mopixs game engine — a 2D Swift engine built on SDL2 using Swift Package Manager.
Read CLAUDE.md for build commands and project conventions.

**Prompt 001 has already been completed.** The following now exist:
- `Sources/GameEngine/BatchRenderer/RPC/DisplayRPCTypes.swift` — shared types (ClientId, ResHandle, CompositionCmd, SoundParams, etc.)
- `Sources/GameEngine/BatchRenderer/RPC/DisplayMessages.swift` — ClientMessage, ServerMessage, Response, ServerEvent enums
- `Sources/GameEngine/BatchRenderer/RPC/DisplayTransport.swift` — DisplayTransport protocol
- `Sources/GameEngine/BatchRenderer/RPC/InProcessTransport.swift` — in-process transport
- `Sources/GameEngine/BatchRenderer/DrawCmd.swift` — extended with `target` field and new DrawCmdType cases

Existing server infrastructure to wrap/delegate to:
- `RendererServer.swift` — thin wrapper around renderer + ResourceStore + DrawCmdInterpolator
- `ResourceStore.swift` — image resource lifecycle (load, unload, fetch by ID)
- `DrawCmdInterpolator.swift` — frame interpolation, z-sorting, parent-relative positions, drawing
- `AtlasLoader` — texture atlas and font management
- `VirtualDrive` — virtual filesystem for resource packs

The existing `IRendererServer` protocol is the current async interface. The new DisplayServer
does NOT implement IRendererServer — it's a higher-level abstraction that processes RPC messages.
</context>

<research>
Before writing code:
1. Read `docs/display-server-rpc-spec.md` — especially Key Decisions, Conventions, and all flow diagrams
2. Read all files in `Sources/GameEngine/BatchRenderer/RPC/` — understand what prompt 001 created
3. Read `Sources/GameEngine/BatchRenderer/RendererServer.swift` — current server
4. Read `Sources/GameEngine/BatchRenderer/ResourceStore.swift` — resource lifecycle
5. Read `Sources/GameEngine/BatchRenderer/DrawCmdInterpolator.swift` — interpolation and draw
6. Read `Sources/GameEngine/Resources/VirtualDrive.swift` or similar — how packs are mounted
7. Read `Sources/GameEngine/BatchRenderer/EditableImage/` — PixelData, ReadOnlyImage, EditedImage
8. Search for any existing audio/sound infrastructure in the project
</research>

<requirements>

## 1. DisplayServer class

Create `Sources/GameEngine/BatchRenderer/RPC/DisplayServer.swift`:

A class that:
- Holds per-client state: `ClientId`, `logicalSize`, `scale`, `resourceLingerMs`, loaded resources, active sounds
- Assigns `ClientId` on connect (server-generated, incrementing)
- Dispatches incoming `ClientMessage` to handler methods
- Sends `ServerMessage` responses and events back via the transport

### Message handlers (implement all ClientMessage cases):

**Session:**
- `connect` — validate, assign ClientId, store client state, respond 200, emit `viewportChanged`
- `disconnect` — clean up client resources, remove client
- `ping` — respond with `pong(serverTick:)`
- `setDisplayConfig` — update client's logicalSize and scale, respond 200
- `setWindowConfig` — apply window title/fullscreen/vsync via SDL, respond 200

**Resource Packs:**
- `uploadPack` — pack names use the format `name_major.minor.patch` (e.g. `basegame_1.1.0`); parse via `PackageMeta.parseMetaFromName`. Decode pack data via `PackArchive` and store to a deterministic temp path keyed by the sanitized pack name (no UUID, no client-id prefix). Mount via VirtualDrive and respond 200. On re-upload with the same name, replace and remount (hot-reload). Packs are globally keyed by name; track which names each client owns only for cleanup on disconnect.

**Resources:**
- `loadResource` — delegate to ResourceStore, respond with image/sound/font body. Track handle→client ownership.
- `uploadResource` — accept raw bytes as PixelData, load into ResourceStore, respond with handle
- `requestPixelData` — fetch pixel data for a handle, respond with pixelData body
- `releaseResource` — mark for linger (per client's `resourceLingerMs`), schedule actual free

**Render:**
- `sendFrame` — process CompositionCmds first, then pass DrawCmds to DrawCmdInterpolator. For composition commands, handle all four cases (createEditableImage, createProceduralImage, copyToEditable, copyToProceduralImage). Emit `compositionError` events on failure. Skip DrawCmds with missing resources and emit `drawError` events.
- `screenshot` — capture current frame pixels, respond with pixelData

**Audio:**
- `playSound`, `stopSound`, `pauseSound`, `resumeSound`, `updateSound`, `stopAllSounds` — if SDL_mixer or similar audio exists in the project, wire it up. If no audio infrastructure exists yet, create stub handlers that respond with 500/"audio not yet implemented". Do NOT build a full audio system from scratch.

### Resource linger / rollback support:
- When `releaseResource` is called, don't free immediately. Hold for `resourceLingerMs` milliseconds.
- Use a timer or tick-based approach (integrate with the existing tick system).
- After linger expires, actually free the resource via ResourceStore.

### Procedural image journal:
- For `createProceduralImage` and `copyToProceduralImage`, record all subsequent DrawCmds targeting that handle in a journal.
- On hot-reload (pack re-upload), re-copy source and replay journal.
- `createEditableImage` and `copyToEditable` do NOT record journals.
- Re-initializing a procedural handle via another composition command resets its journal.

### Multi-client:
- Support multiple simultaneous clients, each with independent state.
- Viewport assignment logic is a server implementation detail — for MVP, divide the screen equally (vertical split for 2 clients, grid for 3-4).
- Emit `viewportChanged` to affected clients when layout changes.

## 2. Wire into existing RendererServer

The DisplayServer should own or wrap a `RendererServer` instance (or directly use `ResourceStore` + `DrawCmdInterpolator`). It should NOT replace RendererServer — the existing class continues to work for non-RPC usage. DisplayServer is an additional entry point.

## 3. File organization

New files under `Sources/GameEngine/BatchRenderer/RPC/`:
- `DisplayServer.swift` — main server class
- `ClientState.swift` — per-client state struct/class (if complex enough to warrant its own file)

</requirements>

<constraints>
- Do NOT break existing RendererServer usage. DisplayServer is additive.
- Do NOT build a full audio system. Stub audio handlers if no infrastructure exists.
- All message handling must be on MainActor or properly synchronized — ResourceStore and SDL calls are not thread-safe.
- Error responses must use the spec's status codes (400, 404, 409, 500) with human-readable string bodies.
- Fire-and-forget messages (sendFrame, disconnect, releaseResource, stopSound, etc.) must NOT produce a Response.
- Only messages with `requestId` produce a Response.
</constraints>

<output>
New files:
- `Sources/GameEngine/BatchRenderer/RPC/DisplayServer.swift`
- `Sources/GameEngine/BatchRenderer/RPC/ClientState.swift` (if needed)

Possibly modified:
- Existing files only if strictly necessary for wiring (e.g., making something public that was internal)
</output>

<verification>
1. Run `swift build` — must compile with zero errors
2. Trace through the "Basic Session" flow from the spec mentally — connect, uploadPack, loadResource, sendFrame, disconnect — and verify each step has a handler
3. Verify that compositionError and drawError events are emitted for the failure cases described in the spec
4. Confirm resource linger logic: releaseResource doesn't immediately free; handles remain usable during linger window
</verification>

<success_criteria>
- All ClientMessage cases have handlers
- Responses use correct status codes and body types per the spec
- Multi-client state is isolated (one client's resources don't leak to another)
- Resource linger and procedural image journal are implemented
- Existing RendererServer/DrawCmdInterpolator code is reused, not duplicated
- `swift build` succeeds
</success_criteria>

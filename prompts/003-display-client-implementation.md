<objective>
Implement the client side of the Display Server RPC protocol.

The DisplayClient sends `ClientMessage` values to the server and receives `ServerMessage`
responses and events. It provides a high-level API that game code calls (load resources, draw,
play sounds) and translates those into RPC messages. It replaces direct `IRendererServer` usage
with the message-based protocol.

Read `docs/display-server-rpc-spec.md` for the full specification.
</objective>

<context>
This is the Mopixs game engine — a 2D Swift engine built on SDL2 using Swift Package Manager.
Read CLAUDE.md for build commands and project conventions.

**Prompts 001 and 002 have already been completed.** The following now exist:
- `Sources/GameEngine/BatchRenderer/RPC/` — shared types, messages, transport, DisplayServer
- `DrawCmd.swift` — extended with `target` field and new DrawCmdType cases

The existing client is `Sources/GameEngine/BatchRenderer/RendererClient.swift`:
- Implements `IDraw` and `IResourceContainer` protocols
- Generates client-side IDs via `genId()` using Xoroshiro
- Talks directly to `IRendererServer` via async calls
- Buffers DrawCmds in `cmdList`, sends via `sendCommands()`
- Has delayed unload support (`unloadResourceDelayed`)
- Manages `IResourceCache` instances

The new DisplayClient should provide a similar API surface so existing game code can migrate
with minimal changes, but communicate through `ClientMessage`/`ServerMessage` instead of
calling `IRendererServer` directly.
</context>

<research>
Before writing code:
1. Read `docs/display-server-rpc-spec.md` — especially Client → Server Messages and all flow diagrams
2. Read all files in `Sources/GameEngine/BatchRenderer/RPC/` — understand what prompts 001-002 created
3. Read `Sources/GameEngine/BatchRenderer/RendererClient.swift` — the existing client to model after
4. Read `Sources/GameEngine/BatchRenderer/IDraw.swift` — the drawing protocol
5. Read `Sources/GameEngine/BatchRenderer/IResourceContainer.swift` — resource container protocol
6. Read `Sources/GameEngine/BatchRenderer/IResourceCache.swift` — cache protocol
7. Read `Sources/GameEngine/BatchRenderer/Image.swift`, `ImageFlyWeight.swift`, `ImageResource.swift` — resource types
8. Search for how RendererClient is used in game code (SpaceInvaders, UITest) to understand the API surface
</research>

<requirements>

## 1. DisplayClient class

Create `Sources/GameEngine/BatchRenderer/RPC/DisplayClient.swift`:

A class that provides a game-friendly API and communicates via the RPC message protocol.

### Connection lifecycle:
- `connect(name:version:logicalSize:resourceLingerMs:)` — sends connect message, awaits response
- `disconnect()` — sends disconnect message, cleans up local state
- Expose `clientId` (assigned by server on connect)

### Event handling:
- Consume `ServerMessage` events from the transport's `AsyncStream`
- Expose events to game code via `AsyncStream<ServerEvent>` or a delegate/callback
- Handle `viewportChanged` — update local viewport state, notify game code
- Handle `drawError` / `compositionError` — log or expose to game code
- Handle `soundFinished` — notify game code

### Resource management:
- `loadResource(url:kind:density:) async throws -> ResponseBody` — sends loadResource message, awaits response, returns the body (image/sound/font)
- `uploadResource(url:kind:density:data:) async throws -> ResponseBody` — uploads raw bytes
- `uploadPack(name:data:) async throws` — uploads a resource pack
- `requestPixelData(handle:) async throws -> ResponseBody` — gets pixel data
- `releaseResource(handle:)` — fire-and-forget release

For async request/response matching:
- Generate `RequestId` values (client-generated, incrementing or random)
- Maintain a dictionary of pending requests: `[RequestId: CheckedContinuation<Response, Error>]`
- When a Response arrives, look up the continuation and resume it
- Throw on non-200 status codes, using the errorDetail string as the error message

### Drawing:
- Implement `IDraw` protocol (or a similar interface) so game code can call `draw()` methods
- Buffer `DrawCmd` and `CompositionCmd` values during a frame
- `sendFrame(clientTick:)` — sends the buffered commands as a sendFrame message (fire-and-forget), then clears buffers
- Support the `target` field on DrawCmd for drawing to editable images

### Composition:
- `createEditableImage(handle:size:)` — buffers a CompositionCmd
- `createProceduralImage(handle:size:)` — buffers a CompositionCmd
- `copyToEditable(handle:source:)` — buffers a CompositionCmd
- `copyToProceduralImage(handle:source:)` — buffers a CompositionCmd

### Audio:
- `playSound(handle:params:) async throws -> SoundHandle` — sends playSound, awaits soundStarted response
- `stopSound(handle:fadeOutMs:)` — fire-and-forget
- `pauseSound(handle:)` — fire-and-forget
- `resumeSound(handle:)` — fire-and-forget
- `updateSound(handle:params:)` — fire-and-forget
- `stopAllSounds()` — fire-and-forget

### Display config:
- `setDisplayConfig(logicalSize:scale:) async throws` — sends setDisplayConfig, awaits response
- `setWindowConfig(config:) async throws` — sends setWindowConfig, awaits response
- `screenshot() async throws -> (Size<Int>, [UInt8])` — sends screenshot, awaits pixelData response

### ID generation:
- Reuse the existing `genId()` pattern (Xoroshiro-based random UInt64) for ResHandle values
- Client generates handles before sending requests, matching the spec convention

## 2. Compatibility with existing code

The DisplayClient should be usable as a drop-in for RendererClient where possible:
- If it can implement `IDraw`, do so
- If it can implement `IResourceContainer`, do so
- If the protocols don't fit cleanly with the async RPC model, document what changed and why

The goal is NOT perfect backward compatibility — it's making migration straightforward.
Existing game code will need some changes; the DisplayClient just needs to minimize them.

## 3. File organization

New files under `Sources/GameEngine/BatchRenderer/RPC/`:
- `DisplayClient.swift` — main client class

</requirements>

<constraints>
- Do NOT modify RendererClient.swift. The new DisplayClient is a separate class. Existing code using RendererClient continues to work.
- All request/response matching must be robust: handle timeouts (or at least document that timeout is not yet implemented), handle responses arriving for unknown requestIds (log and discard).
- Fire-and-forget messages must NOT block or await.
- Use Swift concurrency: async/await for request/response, AsyncStream for events, Task for fire-and-forget sends.
- Do NOT import SDL2 or SDL2Swift in DisplayClient — it should only depend on the shared RPC types and engine geometry types.
</constraints>

<output>
New files:
- `Sources/GameEngine/BatchRenderer/RPC/DisplayClient.swift`
</output>

<verification>
1. Run `swift build` — must compile with zero errors
2. Trace through the "Basic Session" flow: connect → uploadPack → loadResource → sendFrame → disconnect. Verify each step maps to a DisplayClient method that sends the correct ClientMessage.
3. Verify request/response matching: a loadResource call should block until the matching Response arrives, then return the body or throw on error.
4. Verify fire-and-forget methods (sendFrame, releaseResource, stopSound) do not block the caller.
5. Verify event stream: viewportChanged events from the server are surfaced to game code.
</verification>

<success_criteria>
- All ClientMessage types can be sent through DisplayClient's public API
- Async request/response matching works correctly via continuations
- Events are exposed via AsyncStream or equivalent
- Drawing API buffers commands and sends via sendFrame
- Composition commands are buffered and sent with the frame
- Audio API covers all spec operations
- No SDL2 imports in the client file
- `swift build` succeeds
</success_criteria>

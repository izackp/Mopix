<objective>
Define all shared RPC types and the transport layer for the Display Server protocol.

This is the foundation layer that both client and server depend on. It must compile independently
of both sides. The goal is a strict protocol boundary: client and server only communicate through
these message types and transport interface — never by importing each other's internals.

Read `docs/display-server-rpc-spec.md` for the full specification. This prompt implements the
types and transport only — handler logic comes in follow-up prompts.
</objective>

<context>
This is the Mopixs game engine — a 2D Swift engine built on SDL2 using Swift Package Manager.
Read CLAUDE.md for build commands and project conventions.

The project already has a partial implementation in `Sources/GameEngine/BatchRenderer/`:
- `DrawCmd.swift` — existing DrawCmd struct and DrawCmdType enum (image, fill, view, rtt)
- `IRendererServer.swift` — async protocol for the server surface
- `RendererClient.swift` — in-process client that talks directly to IRendererServer
- `ResourceStore.swift` — server-side resource lifecycle management
- `DrawCmdInterpolator.swift` — frame interpolation and rendering

Key existing types to be aware of (do NOT redefine these):
- `VDUrl` (typealias for URL) — used for vd:// resource URLs
- `SDLColor` — color type used throughout
- `Rect<T>`, `Point<T>`, `Size<T>` — generic geometry types in `Sources/GameEngine/Geometry/`
- `BitMaskOptionSet<Renderer.RendererFlip>` — flip flags on DrawCmd
- `PixelData` — raw pixel data wrapper in BatchRenderer/EditableImage/

The existing `DrawCmd` needs to be **extended** (add `target` field, new DrawCmdType cases)
rather than replaced, because DrawCmdInterpolator and other code depends on the current shape.
</context>

<research>
Before writing any code:
1. Read `docs/display-server-rpc-spec.md` thoroughly — all shared types, message enums, and conventions
2. Read `Sources/GameEngine/BatchRenderer/DrawCmd.swift` — current DrawCmd and DrawCmdType
3. Read `Sources/GameEngine/BatchRenderer/IRendererServer.swift` — current server protocol
4. Read `Sources/GameEngine/BatchRenderer/RendererClient.swift` — understand existing ID generation and async patterns
5. Read `Sources/GameEngine/BatchRenderer/EditableImage/PixelData.swift` — existing pixel data type
6. Check `Sources/GameEngine/Geometry/` for Size, Rect, Point, EdgeInsets definitions
7. Read `Package.swift` to understand target structure
</research>

<requirements>

## 1. Extend DrawCmd (modify existing file)

Modify `Sources/GameEngine/BatchRenderer/DrawCmd.swift`:

- Add `target: UInt64` field to `DrawCmd` (default `0` = viewport). Ensure the existing `lerp()` method and all call sites still compile — `target` should pass through unchanged during interpolation.
- Add new cases to `DrawCmdType`:
  - `text(fontHandle: UInt64, content: String, size: Float, align: TextAlignment)`
  - `line(to: Point<Int>, thickness: Int)`
  - `circle(radius: Int, filled: Bool)`
  - `rect(filled: Bool)`
- Add `TextAlignment` enum: `left`, `center`, `right`
- Keep the existing `.rtt` case for now (it can be deprecated later)

## 2. Create shared RPC types (new file)

Create `Sources/GameEngine/BatchRenderer/RPC/DisplayRPCTypes.swift`:

All typealiases and types from the spec's "Shared Types" section:
- `ClientId`, `ResHandle`, `SoundHandle`, `RequestId` typealiases
- `ResourceKind` enum
- `WindowConfig` struct
- `CompositionCmd` enum (all four cases from spec)
- `SoundParams` struct with defaults matching spec
- `EdgeInsets` — check if one already exists in Geometry/; if so, use it; if not, define here

## 3. Create message enums (new file)

Create `Sources/GameEngine/BatchRenderer/RPC/DisplayMessages.swift`:

- `ClientMessage` enum — all cases from the spec's "Client → Server Messages" section
- `ServerMessage` enum — `response(Response)` and `event(ServerEvent)`
- `Response` struct — `requestId`, `status`, `body`
- `ResponseStatus` enum with raw UInt16 values (200, 400, 404, 409, 500)
- `ResponseBody` enum — all cases from spec (pong, image, sound, font, pixelData, soundStarted, errorDetail)
- `ServerEvent` enum — all cases (viewportChanged, drawError, compositionError, soundFinished)

## 4. Create transport protocol and in-process implementation (new files)

Create `Sources/GameEngine/BatchRenderer/RPC/DisplayTransport.swift`:

```swift
/// The transport abstraction. Both sides hold one end.
/// In-process: direct function calls. Network: serialize + send.
public protocol DisplayTransport: AnyObject {
    func send(_ message: ClientMessage) async
    func send(_ message: ServerMessage) async
}
```

Create `Sources/GameEngine/BatchRenderer/RPC/InProcessTransport.swift`:

An in-process transport where client and server are in the same process:
- Client-side sends go directly to a server handler callback
- Server-side sends go to an `AsyncStream<ServerMessage>` the client consumes
- Use `AsyncStream.Continuation` for the server→client direction
- The transport should be created as a pair: one end for the client, one for the server

## 5. File organization

All new files go under `Sources/GameEngine/BatchRenderer/RPC/`. The only existing file modified
is `DrawCmd.swift`.

</requirements>

<constraints>
- Do NOT break existing call sites. `DrawCmd` initializers that don't pass `target` must still work (use a default value).
- Do NOT import SDL2 or SDL2Swift in the RPC types files — they must be pure Swift so they can eventually move to a shared target.
  Exception: `SDLColor` is currently used in `DrawCmd` which already imports SDL2Swift — that's fine for the DrawCmd modifications.
- Do NOT define types that already exist in the engine (Size, Rect, Point, SDLColor, PixelData, VDUrl). Import and use them.
- All new types must be `public`.
- Use Swift concurrency (async/await, AsyncStream) — no Combine, no third-party deps.
- Follow existing code style: no doc comments on obvious things, minimal comments.
</constraints>

<output>
Modified files:
- `Sources/GameEngine/BatchRenderer/DrawCmd.swift` — extended with target field and new DrawCmdType cases

New files:
- `Sources/GameEngine/BatchRenderer/RPC/DisplayRPCTypes.swift`
- `Sources/GameEngine/BatchRenderer/RPC/DisplayMessages.swift`
- `Sources/GameEngine/BatchRenderer/RPC/DisplayTransport.swift`
- `Sources/GameEngine/BatchRenderer/RPC/InProcessTransport.swift`
</output>

<verification>
1. Run `swift build` — everything must compile with zero errors
2. Verify that existing DrawCmd usage in DrawCmdInterpolator.swift still compiles (the `target` default keeps it compatible)
3. Verify no SDL2/SDL2Swift imports leaked into the RPC/ files (except through existing types like DrawCmd)
4. Confirm all spec message types are covered by diffing against `docs/display-server-rpc-spec.md`
</verification>

<success_criteria>
- All types from the spec's Shared Types, Client Messages, Server Messages sections are defined
- DrawCmd extended with `target` and new DrawCmdType cases without breaking existing code
- Transport protocol defined with working in-process implementation
- `swift build` succeeds
- Clean separation: RPC/ files have no knowledge of RendererServer, ResourceStore, or SDL internals
</success_criteria>

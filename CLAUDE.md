# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Mopixs** — a 2D game engine in Swift built on SDL2. Code-centric (MonoGame style), deterministic, and highly portable. Uses Swift Package Manager exclusively (no Xcode required).

## Build & Run Commands

```bash
# Build everything
swift build

# Build a specific product (debug or release)
swift build --product SpaceInvaders -c debug
swift build --product UITest -c debug
swift build --product ParticleTweenTest -c debug

# Run an executable (note: swift run may not find SDL on Windows)
swift build --product SpaceInvaders && .build/debug/SpaceInvaders

# Run tests
swift test

# Run a single test
swift test --filter GameEngineTests.<TestName>
```

**macOS prerequisite**: The `icu-swift` dependency requires that `libicuuc` is code-signed, or that Hardened Runtime > Library Validation is disabled in the app's signing settings. This is a local path dependency (`/Users/isaacpaul/Projects/swift-projects/icu-swift`), so it must exist on the machine.

## Architecture

### Targets

| Target | Type | Description |
|---|---|---|
| `GameEngine` | Library | Core engine: windowing, rendering, UI, resources, serialization |
| `AniTween` | Library | Tweening/animation system backed by `ChunkedPool` |
| `ChunkedPool` | Library | Memory-efficient chunked object pool |
| `SystemFonts` | Obj-C Library | macOS-only bridge to Core Text for system font data |
| `SpaceInvaders` | Executable | Demo game; primary integration test of the engine |
| `UITest` | Executable | Sandbox for testing UI views and layout |
| `ParticleTest` | Executable | Sandbox for testing particles and tweening |

### Core Loop: `Application` → `LiteWindow`/`FullWindow`

`Application` owns the SDL game loop (`runLoop()`). It dispatches:
- **Fixed-step updates** via `addFixedListener(_ listener, msPerTick:)` — listeners implement `IUpdate`; called at a fixed rate using `TickBank`
- **Delta updates** via `addDeltaListener(_:)` — called every frame with elapsed ms
- **Events** via `addEventListener(_:)` — listeners implement `IEventListener` and receive `[SDL_Event]`

`LiteWindow` is a thin SDL window wrapper implementing `IUpdate` and `IEventListener`. Its `step()` drives `drawStart()` → `draw(time:)` → `drawFinish()`.

`FullWindow` extends `LiteWindow` with the full rendering stack:
- `RendererServer` + `RendererClient` — decoupled draw command pipeline
- `ImageManager` + `ImageAtlas` — texture atlas and font management
- `rootViewController`/`rootView` — optional UI tree

### Rendering: `RendererClient` / `RendererServer`

Rendering is separated into a client/server model to support determinism and future rollback:
- The **client** (`RendererClient`) collects `DrawCmdImage` structs during `draw()` and calls `sendCommands()` at the end of the frame.
- The **server** (`RendererServer` → `DrawCmdInterpolator`) stores command lists and interpolates between them for smooth display even with a fixed-step logic tick.
- `DrawCmdImage.lerp()` provides per-command linear interpolation between frames.

### Resource System: `VirtualDrive` + `ImageManager`

`VirtualDrive` (singleton `VirtualDrive.shared`) is a virtual filesystem that aggregates `MountedDir` packages. Resources are addressed with `vd://` URLs. Call `vd.mountPath(path:)` to register a directory. `VirtualDrive` implements `IDataSource`.

`ImageManager` wraps an `ImageAtlas` (bin-packed texture atlas using `EtagerePacker`). It resolves fonts via TTF files in the VD and macOS system fonts via `SystemFonts`.

### UI System

The UI tree mirrors UIKit patterns:
- `View` is `Codable`, has `frame`, `children`, `backgroundColor`, `alpha`, `clipBounds`, and layout lists.
- `ViewController` manages a root `View`.
- Layout is driven by `LayoutElement`/`LayoutChild` (Yoga-style layout via `YogaLayout`).
- `UIRenderContext` wraps the SDL `Renderer` for UI drawing operations.
- UI definitions can be loaded from JSON5 files in `ExternalFiles/` (see `ViewBuilder.json5`).

### Serialization

Extended `Codable` with support for:
- **Dynamic type resolution**: objects include a `_type` JSON key mapping to Swift types via `TypeMap` / `CodableTypeResolver`.
- **ID-based references**: objects include a `_id` key; `InstanceCache` resolves references.
- `Resolver<T>` wraps array deserialization for root-level arrays.
- Custom container helpers: `decodeArray`, `decodeElementInArray`, `decodeDynamicItemIfPresent` in `CodingContainers+Features.swift`.
- To register a new decodable type, add it to `TypeMap.customDecodeSwitch()`.

### AniTween

`Tweener<T>` manages a `ChunkedPool<T>` of tween objects implementing `SomeTween`. Call `tweener.animate(duration:modifier:action:onComplete:)` to start a tween. Call `tweener.processFrame(deltaTime)` each frame. Supports parallel processing via `DispatchQueue.concurrentPerform`.

### Input

`Commands.swift` defines input commands. `CommandRepeater` handles key-repeat logic. SDL events are raw `SDL_Event` values; convert with helpers in `Extensions/Commands+SDL.swift`.

## Key Conventions

- `DValue` is a type alias for `Int16` used for UI dimensions (see `Common.swift`).
- `VDUrl` is a type alias for `URL`; `vd://` scheme URLs route through `VirtualDrive`.
- `MutableIteratableArray` allows safe mutation (add/remove) while iterating.
- `Rect`, `Point`, `Size`, `Vector` are generic structs in `Geometry/`; SDL bridging is in `Geometry+SDL.swift`.
- The engine uses `SDL_GetTicks64()` for all timing (milliseconds as `UInt64`).
- `LabeledColor` / `LabeledColorMap` are named, serializable color references.

### Extra
Ignore the .build folder

## Claude Workflow Rules

- **Commit after every change.** Make a git commit immediately before reporting a task as done.
- **Never modify branches that do not begin with `claude`.** If the current branch does not start with `claude`, stop and ask the user before making any changes.
- **Commit footer format.** End every commit message with `Automated-By: <model name>` (no email address). Do not use `Co-Authored-By`.

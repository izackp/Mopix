<objective>
Refactor the UI rendering system so that View, UIRenderContext, and FullWindow draw through the RendererClient command pipeline instead of making direct SDL Renderer calls.

Currently, game objects draw via `RendererClient` → `RendererServer` → `DrawCmdInterpolator`, but the UI system (`View.draw()`, `UIRenderContext`) bypasses this entirely and calls `Renderer` directly. The goal is to unify all rendering through the command pipeline.

The pipeline must be kept pure — RendererServer receives no information from the game/UI side except through commands. This is required for eventual networked rendering support.

See `DECISIONS.md` at the repo root for the full rationale behind every architectural choice made here.
</objective>

<context>
Read the CLAUDE.md for full project conventions.

Key files to understand before making changes:

**Current command pipeline (game rendering):**
- `@Sources/GameEngine/BatchRenderer/IDraw.swift` — protocol with `draw(DrawCmdImage)` and `createImage()`
- `@Sources/GameEngine/BatchRenderer/DrawCmd.swift` — `DrawCmdImage` struct (the only command type currently)
- `@Sources/GameEngine/BatchRenderer/RendererClient.swift` — collects `DrawCmdImage` commands, sends to server. Contains a commented-out `DrawItem` enum showing the original intent for multiple command types.
- `@Sources/GameEngine/BatchRenderer/RendererServer.swift` — receives commands, passes to interpolator. Must remain pipeline-pure.
- `@Sources/GameEngine/BatchRenderer/DrawCmdInterpolator.swift` — stores two frames, interpolates, and draws
- `@Sources/GameEngine/BatchRenderer/ImageBuilder.swift` — stub `IDraw` implementation; `finalize()` currently returns 0 (unfinished)
- `@Sources/GameEngine/BatchRenderer/IRendererServer.swift` — the async server protocol

**UI rendering (currently bypasses pipeline):**
- `@Sources/GameEngine/UI/UIRenderContext.swift` — wraps SDL Renderer for UI drawing (`drawSquare`, `drawText`, `drawTextLine`, `drawImage`, `setClipRect`, `createAndDrawToTexture`). ALL of these methods must be preserved with the same public signatures.
- `@Sources/GameEngine/UI/View.swift` — `draw(_ context:UIRenderContext, _ rect)` calls UIRenderContext directly
- `@Sources/GameEngine/Windowing/FullWindow.swift` — `draw(time:)` sends game commands via RendererClient then draws UI directly via UIRenderContext
</context>

<research>
Before implementing, thoroughly explore the codebase to understand:

1. **All View subclasses** that override `draw()` or `drawContent()`. Search for `drawContent\(` and `func draw\(_ context:UIRenderContext` across the entire project including executables (UITest, SpaceInvaders).

2. **All UIRenderContext methods actually called** from View subclasses — confirm which of `drawSquare`, `drawText`, `drawTextLine`, `drawImage`, `setClipRect`, `createAndDrawToTexture` are used in practice.

3. **How `Font` stores glyphs** — `font.glyph(c)` returns an `AtlasImage`. Trace the full path from `FontDesc` → `Font` → `AtlasImage` → `SubTextureIndex` to understand where to attach stable resource IDs at font load time.

4. **How the atlas blank texture is located** — `atlas.blankTextureIndex(_lastTexture)` in `drawSquare`. Understand when this is created so you can replace it with a `DrawCmdFill` (no texture lookup needed).

5. **How `ResourceStore` maps resource IDs to textures** — understand the async `loadResource` flow so you can register glyph `AtlasImage`s with stable IDs at font load time.

6. **How `DrawCmdInterpolator.draw()` handles clipping** — it reads `clippingRect` on each command but has a bug: `currentClip` is set but never used to update the actual SDL clip rect. Note this for Phase 4.

7. **`ImageBuilder.finalize()`** — currently returns 0 and does nothing. Understand its intended role before deciding whether to repurpose or replace it for `DrawCmdRTT`.
</research>

<requirements>
**Phase 1: Introduce `DrawCmd` enum and new command types**

Replace the flat `[DrawCmdImage]` command list with a typed `[DrawCmd]` enum throughout the pipeline.

Add `parentAnimationId: UInt64` to the existing `DrawCmdImage` struct (default 0, no breaking change to game rendering). Update its `lerp()` and `compare()` as needed.

Define in `DrawCmd.swift`:

```swift
public indirect enum DrawCmd {
    case image(DrawCmdImage)
    case fill(DrawCmdFill)
    case view(DrawCmdView)
    case rtt(DrawCmdRTT)
}
```

**`DrawCmdFill`** — solid color rectangle, no texture:
```swift
public struct DrawCmdFill {
    let animationId: UInt64
    let parentAnimationId: UInt64
    let dest: Rect<Int>       // relative to parent when parentAnimationId != 0, else absolute
    let color: SDLColor
    let alpha: Float
    let z: Int
    let clippingRect: Rect<Int>
}
```

**`DrawCmdView`** — one per View, encodes background and border in a single command:
```swift
public struct DrawCmdView {
    let animationId: UInt64
    let parentAnimationId: UInt64
    let dest: Rect<Int>       // relative to parent when parentAnimationId != 0, else absolute
    let backgroundColor: SDLColor
    let backgroundAlpha: Float
    let borderColor: SDLColor
    let borderWidth: Int
    let z: Int
    let clippingRect: Rect<Int>
}
```
The server draws the background fill and up to four border lines from this single command. It may break these into individual SDL calls internally.

**`DrawCmdRTT`** — render-to-texture, compound command built incrementally via block-callback:
```swift
public struct DrawCmdRTT {
    let animationId: UInt64
    let parentAnimationId: UInt64
    let targetResourceId: UInt64
    let targetRect: Rect<Int>
    let z: Int
    let clippingRect: Rect<Int>
    var subCommands: [DrawCmd]   // nested DrawCmdRTT allowed
}
```

**Position semantics (applies to all command types):**
- `dest` is **relative to the parent's resolved position** when `parentAnimationId != 0`
- `dest` is **absolute screen coordinates** when `parentAnimationId == 0`
- Game rendering commands use `parentAnimationId: 0` — no change to existing behaviour
- UIRenderContext emits each view's own `frame` directly as `dest` — it does NOT accumulate parent offsets

Update throughout the pipeline:
- `RendererClient.cmdList` from `[DrawCmdImage]` to `[DrawCmd]`
- `RendererClient.draw(_:DrawCmdImage)` to emit `.image(cmd)`
- `RendererClient.sendCommands()` / `clearCommands()` to use `[DrawCmd]`
- `IRendererServer.receiveCmds` to accept `[DrawCmd]`
- `RendererServer.receiveCmds` accordingly
- `DrawCmdInterpolator.receiveCmds` and `draw()` (see Phase 4)

**Phase 2: Stable resource IDs for glyphs**

Every glyph that UIRenderContext will draw needs a stable `UInt64` resource ID registered with `ResourceStore` before any drawing occurs. Register eagerly at font load time.

- When a `Font` is loaded and its glyphs are rasterised into the atlas, register each glyph's `AtlasImage` with `ResourceStore` and store the resource ID alongside the glyph in the `Font`'s glyph table.
- Atlas images loaded via `AtlasLoader.image(_:)` (used by `drawImage`) must already have gone through `RendererClient.loadResource` — verify this is the case.
- `drawSquare` becomes `DrawCmdFill` — no texture or resource ID needed, remove the blank texture lookup entirely.
- Add a lookup helper (e.g. on `Font` or `AtlasLoader`) so `UIRenderContext` can retrieve a resource ID for any glyph it needs to draw.

**Phase 3: Update UIRenderContext to emit commands**

Change `UIRenderContext`'s init to accept `IDraw` (RendererClient) instead of `Renderer`. Remove the `renderer` property. Keep `imageManager`.

UIRenderContext must track two pieces of context as it walks the view tree:
- `currentParentAnimationId: UInt64` — the animationId of the view currently being drawn into (set when entering a view's draw, restored when leaving)
- `currentZ: Int` — monotonically increasing counter; each emitted command gets the current value, incremented after

Update each method:

- **`drawSquare`** → emit `DrawCmd.fill(DrawCmdFill(dest, color, alpha, currentZ, clippingRect))`. No texture lookup.
- **`drawImage`** → look up resource ID, emit `DrawCmd.image(DrawCmdImage(..., parentAnimationId: currentParentAnimationId))`.
- **`drawText`** → for each character, look up glyph resource ID from `Font`, emit `DrawCmd.image(...)` per glyph with `parentAnimationId: currentParentAnimationId`.
- **`drawTextLine`** → for each `RenderableCharacter`: if `c.background` is set, emit `DrawCmd.fill(...)` as a sibling; then emit `DrawCmd.image(...)` for the glyph. Both use `parentAnimationId: currentParentAnimationId`.
- **`setClipRect`** → update `currentClipRect` local state only; each subsequent command carries the current clip rect when emitted.
- **`createAndDrawToTexture`**:
  1. Generate a new resource ID
  2. Allocate the target region in the atlas (`atlas.saveBlankImage(size)`) and register it under that resource ID
  3. Push a new `[DrawCmd]` sub-command buffer onto a stack
  4. Execute the caller's block — all draw calls inside append into the current sub-command buffer
  5. Pop the buffer, wrap as `DrawCmd.rtt(DrawCmdRTT(targetResourceId, targetRect, subCommands: buffer))`
  6. Append the RTT command to the parent buffer (or main command list)
  7. Return an `AtlasImage` backed by the allocated region so callers can reference the result immediately

  Nesting: inner `createAndDrawToTexture` calls push their own buffer, complete, and their `DrawCmdRTT` becomes a sub-command in the outer buffer.

**`View.draw()` integration:**

When `View.draw()` is called, before emitting any commands it must:
1. Emit `DrawCmd.view(DrawCmdView(..., animationId: self.animationId, parentAnimationId: context.currentParentAnimationId, dest: self.frame, ...))` — this is the view's single own command
2. Save and set `context.currentParentAnimationId = self.animationId`
3. Call `drawContent(context, ...)` — subclass content becomes child commands
4. Draw children — each child's commands become grandchild commands
5. Restore `context.currentParentAnimationId`

Each `View` needs a stable `animationId: UInt64`. Derive it from `ObjectIdentifier(self)` cast to `UInt64` — stable for the lifetime of the object.

**`shouldRasterize` must never be made the default.** It remains an explicit opt-in that uses `createAndDrawToTexture`.

**Phase 4: Update DrawCmdInterpolator**

The server must resolve parent-relative positions to absolute before drawing. Since commands are sorted by z (parents always have lower z than their children), process the sorted list in order and cache each command's resolved absolute position in a `[UInt64: Rect<Int>]` map keyed by `animationId`.

For each command:
1. If `parentAnimationId == 0`, resolved position = `dest` (already absolute)
2. If `parentAnimationId != 0`, resolved position = parent's cached absolute position + `dest`

Handle all `DrawCmd` cases in `draw()`:

- **`.view(DrawCmdView)`** — draw background fill rect, then up to four border rects if `borderWidth > 0`. Apply `clippingRect`. No interpolation (animationId: 0 behaviour) unless the view has a non-zero animationId matched in `_lastCmdList`.
- **`.fill(DrawCmdFill)`** — SDL fill rect with color and alpha. Apply `clippingRect`.
- **`.image(DrawCmdImage)`** — existing behaviour. Fix the existing clipping bug: `currentClip` must actually update the SDL clip rect when `clippingRect` changes.
- **`.rtt(DrawCmdRTT)`** — recursive render-to-texture:
  1. Fetch target texture via `resourceStore.fetchResource(targetResourceId)`
  2. `renderer.setTarget(targetTexture)`
  3. Recursively process `subCommands`
  4. Restore previous render target

Interpolation: only `.image` and `.view` commands with non-zero `animationId` participate in lerp. `.fill` and `.rtt` pass through unchanged.

**Phase 5: Update FullWindow.draw()**

```swift
public override func draw(time: UInt64) throws {
    totalDrawTime += time
    renderClient.clearCommands()
    drawable?.draw(time, renderClient)
    if let view = rootView {
        let context = UIRenderContext(client: renderClient, imageManager: imageManager)
        try view.draw(context, view.frame)
    }
    renderClient.sendCommands()
    renderServer.drawingInterpolator.draw(totalDrawTime - 100)
}
```

Remove the old `UIRenderContext(renderer: renderer, ...)` construction and the separate UI draw pass.

**Phase 6: Update View subclasses**

With `UIRenderContext`'s public method signatures preserved, most subclasses should compile unchanged. Verify each one. The `draw(_ context:IDraw)` stub in `View.swift` can be removed if it no longer serves a purpose.
</requirements>

<constraints>
- Do NOT break existing game rendering. Game `DrawCmdImage` commands use `parentAnimationId: 0` — no change to their behaviour.
- Do NOT remove UIRenderContext. Preserve all public method signatures exactly. Only internals change.
- RendererServer must remain pipeline-pure — no references to view tree, layout, or client-side state.
- `shouldRasterize` must never be made the default. It is an explicit opt-in only.
- `dest` is relative to parent when `parentAnimationId != 0`, absolute when `parentAnimationId == 0`. UIRenderContext emits each view's own `frame` directly — it does NOT accumulate parent offsets.
- Each `View` needs a stable `animationId` for the lifetime of the object. Derive from `ObjectIdentifier`.
- Glyph `animationId`s are derived from `textViewAnimationId + glyphIndex`. A text content change causes a one-frame lerp mismatch — this is acceptable.
- `DValue` is `Int16`; commands use `Int` for coordinates. Convert at the UIRenderContext boundary.
- The `indirect` keyword may be required on `DrawCmd` due to `DrawCmdRTT` containing `[DrawCmd]`. Verify this compiles.
- Run `swift build` after each phase before proceeding.
</constraints>

<implementation>
1. Read all files in `<context>` and complete `<research>` first
2. Implement one phase at a time; run `swift build` after each before proceeding
3. Phase order is strict: Phase 1 → Phase 2 → Phase 3 → Phase 4 → Phase 5 → Phase 6
4. Do not skip ahead — each phase depends on the previous compiling cleanly
</implementation>

<verification>
Before declaring complete:
1. `swift build` compiles without errors
2. `FullWindow.draw()` no longer constructs `UIRenderContext` with a raw `Renderer`
3. `UIRenderContext` has no references to `renderer` — no `renderer.draw()`, `renderer.copy()`, `renderer.setClipRect()`, `renderer.setTarget()`, or `renderer.swapTarget()`
4. `RendererServer` has no new references to the view tree, layout, or `AtlasLoader` beyond what it already held
5. All View subclasses compile unchanged
6. `swift build --product UITest && .build/debug/UITest` renders visually without regression
</verification>

<success_criteria>
- All UI rendering flows through RendererClient → RendererServer → DrawCmdInterpolator
- No direct SDL Renderer calls from View or UIRenderContext
- One `DrawCmdView` command per View; glyphs and images are child commands
- `dest` is parent-relative; server resolves absolute positions before drawing
- Render-to-texture (`createAndDrawToTexture`) works including nested calls
- Project compiles cleanly with `swift build`
- Existing game rendering (drawable path) unchanged
</success_criteria>

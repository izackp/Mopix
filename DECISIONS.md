# Architecture Decisions

## UI Rendering Pipeline (2026-03-04)

**Goal:** Route all UI rendering through the RendererClient command pipeline instead of making direct SDL Renderer calls. The pipeline must be pure enough to support networked commands.

---

### Decision 1: Solid color fills → `DrawCmdFill` (new command type)

`drawSquare` currently looks up a blank atlas pixel and tints it. Instead, introduce a dedicated `DrawCmdFill` command that the server handles with a direct fill call (e.g. `SDL_RenderFillRect`). Chosen because we anticipate needing other primitive shape commands in the future and a dedicated type is extensible without polluting `DrawCmdImage`.

---

### Decision 2: Render-to-texture → `DrawCmdRTT` with embedded sub-command list

`createAndDrawToTexture` becomes a compound command `DrawCmdRTT { targetResourceId, targetRect, subCommands: [DrawCmd] }` where sub-commands are collected synchronously via the existing block-callback pattern. Nesting is supported — inner RTTs become sub-commands of outer RTTs through recursive block execution. The server processes them via recursive descent (push render target → draw sub-commands → pop render target).

`shouldRasterize` remains an explicit opt-in only. It must never be made the default.

**Rejected alternative (Option A — begin/end markers):** A flat stream with `DrawCmdBeginRTT`/`DrawCmdEndRTT` sentinels was rejected because interleaved markers are fragile for a networked pipeline — a dropped or reordered marker silently corrupts the render-target stack. Option B's compound command is an atomic unit, easier to serialize and validate.

---

### Decision 3: Resource IDs for atlas images/glyphs → eager registration at load time

Each glyph and atlas image gets a stable `UInt64` resource ID registered at load time (font load, image load). By the time `UIRenderContext` draws anything, all resource IDs are pre-registered and stable. A lookup table (e.g. on `Font` or `ImageManager`) maps `AtlasImage`/glyph → resource ID.

Stable IDs are a hard requirement — the pipeline is designed for eventual networked rendering where IDs must be consistent and durable.

**Rejected alternatives:**
- On-demand (register on first draw): requires per-draw lookup and cache invalidation.
- Atlas pages as resources (Option C): requires adding `sourceRect` to every draw command and a "replace resource" mechanism for mutable atlas pages.

---

### Decision 4: `UIRenderContext` stays on the client side

`UIRenderContext` becomes a command emitter wrapping `IDraw` (RendererClient) rather than wrapping the raw SDL `Renderer`. Its public API is preserved so View subclasses require minimal changes. Only the internals change.

---

### Decision 5: `RendererServer` must remain pipeline-pure

`RendererServer` receives no information from the game/UI side except through the command pipeline. It holds no reference to the view tree, layout, or any client-side state. This is required for eventual networked rendering support.

---

### Decision 6: One command per view — `DrawCmdView` (new command type)

Each `View` produces exactly one command covering its own visual output: background fill and borders. This is `DrawCmdView`, a distinct command type with `backgroundColor`, `borderColor`, and `borderWidth` fields. The server handles drawing both the fill and border lines from this single command, and may break it down internally for performance.

Content drawn by `drawContent()` overrides (images, glyphs, custom drawing) is expressed as **child commands** with `parentAnimationId` referencing the view's `animationId`. This keeps the one-command-per-view rule intact.

**Rejected alternative:** Emitting separate sibling `DrawCmdFill` commands for background and borders would require multiple animationIds per view, breaking the one-to-one view/command/ID relationship.

---

### Decision 7: Glyphs are children — each glyph gets its own `animationId`

Text rendering treats each glyph as a child command of the `TextView`'s `DrawCmdView`. Each glyph instance gets a unique `animationId` (derived from the TextView's animationId + glyph index within the string). Per-character background colors (from `RenderableCharacter.background`) are emitted as sibling `DrawCmdFill` commands with their own animationIds, drawn immediately before the glyph they belong to.

Glyph IDs are stable as long as text content and order don't change. Text changes cause a one-frame lerp mismatch, which is imperceptible.

---

### Decision 8: `parentAnimationId` on all command types; `dest` is parent-relative

All command types (`DrawCmdImage`, `DrawCmdFill`, `DrawCmdView`, `DrawCmdRTT`) carry two ID fields:
- `animationId: UInt64` — this command's stable unique identity
- `parentAnimationId: UInt64` — the animationId of the parent command (0 = no parent, position is absolute)

The `dest` field is **relative to the parent's resolved position** when `parentAnimationId != 0`, and **absolute screen coordinates** when `parentAnimationId == 0`. This allows children to animate independently within a moving parent while the server correctly resolves absolute positions and interpolation.

Game rendering commands continue to use `parentAnimationId: 0` (absolute positions). No breaking change.

`UIRenderContext` emits each view's own `frame` directly as `dest` rather than accumulating parent offsets. The server resolves absolute positions by walking the parent chain (sorted by z, parents before children) before drawing.

---

### Decision 9: Z-index assigned by the view tree

The view tree assigns a monotonically increasing z-index to each emitted command as it walks the tree (depth-first, parent before children, earlier siblings before later ones). The server sorts commands by z before resolving positions and drawing, guaranteeing correct draw order without the server needing any knowledge of the tree structure.

# Sources/Tennis/TennisScene.swift [Tennis]

```text
// TARGET: Tennis executable
// OWNED BY: TennisScene owns the renderer-facing court projection and draw-layer IDs. It reads
// immutable snapshots from the injected coordinator; it does not own match or simulation state.
// DEPENDENCIES: GameEngine IDrawable/DisplayRenderClient/DrawCmd APIs and SDL2Swift value types;
// TennisMatchCoordinator and TennisMatchSnapshot. No TennisInput dependency and no renderer-to-
// simulation mutation.

TennisScene < IDrawable
  priv coordinator: TennisMatchCoordinator
  priv viewport: Rect<Int>
  priv court: Rect<Int>
  priv lineColor: SDLColor
  priv backgroundColor: SDLColor
  priv courtColor: SDLColor
  priv netColor: SDLColor
  priv lowerPlayerColor: SDLColor
  priv upperPlayerColor: SDLColor
  priv ballColor: SDLColor
  init(coordinator: TennisMatchCoordinator)
  draw(_ delta: UInt64, _ renderer: DisplayRenderClient)
    >> TennisMatchCoordinator.snapshot() render(_:renderer:)
  priv render(_ snapshot: TennisMatchSnapshot, renderer: DisplayRenderClient)
    >> playerRect(for:in:) ballRect(for:in:)
       fill(_:id:rect:color:z:) view(_:id:rect:fill:border:borderWidth:z:)
  priv playerRect(for player: TennisPlayerState, in court: Rect<Int>) -> Rect<Int>
  priv ballRect(for ball: TennisBallState, in court: Rect<Int>) -> Rect<Int>
  priv projectedPoint(_ point: TennisPoint, in court: Rect<Int>) -> Point<Int>
    << playerRect(for:in:) ballRect(for:in:)
  priv fill(_ renderer: DisplayRenderClient, id: UInt64, rect: Rect<Int>, color: SDLColor, z: Int)
    >> DisplayRenderClient.drawCmd(_:)
  priv view(_ renderer: DisplayRenderClient, id: UInt64, rect: Rect<Int>, fill: SDLColor, border: SDLColor, borderWidth: Int, z: Int)
    >> DisplayRenderClient.drawCmd(_:)

  Layer
    background
    court
    courtBorder
    topServiceLine
    bottomServiceLine
    centerServiceLine
    netBand
    netPosts
    topCenterMark
    bottomCenterMark
    lowerPlayer
    upperPlayer
    ball
```

`DisplayRenderClient` is the current GameEngine renderer API used by this source file. Each draw
reads one `TennisMatchSnapshot` from the coordinator and maps fixed-point player/ball positions
to integer court rectangles; placeholder player and ball positions are not part of the next slice.
Rendering is observational: it does not advance the fixed tick, consume input, or mutate TennisCore
state. The scene emits `DrawCmd` values through `drawCmd(_:)` and does not own renderer transport.

// TEST: after an input event and one fixed coordinator step, the scene reads the resulting
// snapshot and projects the simulation positions, not hard-coded positions.
// TEST: point reset is visible in the next snapshot without an extra simulation tick.

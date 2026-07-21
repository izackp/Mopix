# Sources/Tennis/TennisScene.swift [Tennis]

```text
// TARGET: Tennis executable
// OWNED BY: TennisScene owns the current renderer-facing court projection and draw-layer IDs.
// DEPENDENCIES: GameEngine IDrawable/DisplayRenderClient/DrawCmd APIs and SDL2Swift value types.
// This source slice has no dependency on TennisCore state or TennisInput controllers.

TennisScene < IDrawable
  priv viewport: Rect<Int>
  priv court: Rect<Int>
  priv lineColor: SDLColor
  priv backgroundColor: SDLColor
  priv courtColor: SDLColor
  priv netColor: SDLColor
  priv lowerPlayerColor: SDLColor
  priv upperPlayerColor: SDLColor
  priv ballColor: SDLColor
  draw(_ delta: UInt64, _ renderer: DisplayRenderClient)
    >> fill(_:id:rect:color:z:) view(_:id:rect:fill:border:borderWidth:z:)
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

This is the current presentation source-map contract. It draws the fixed logical court and its
layered primitive projections; it does not feed rendered/interpolated values into simulation.
`DisplayRenderClient` is the current GameEngine renderer API used by this source file. The
scene emits `DrawCmd` values through `drawCmd(_:)`; it does not own renderer transport or
simulation state.

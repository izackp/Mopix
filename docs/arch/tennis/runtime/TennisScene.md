# Sources/Tennis/TennisScene.swift [Tennis]

```text
// TARGET: Tennis executable
// OWNED BY: TennisScene owns the current renderer-facing court projection and draw-layer IDs.
// DEPENDENCIES: GameEngine IDrawable/RendererClient/DrawCmd APIs and SDL2Swift value types.
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
  draw(_ delta: UInt64, _ renderer: RendererClient)
    >> fill(_:id:rect:color:z:) view(_:id:rect:fill:border:borderWidth:z:)
  priv fill(_ renderer: RendererClient, id: UInt64, rect: Rect<Int>, color: SDLColor, z: Int)
    >> RendererClient.drawCmd(_:)
  priv view(_ renderer: RendererClient, id: UInt64, rect: Rect<Int>, fill: SDLColor, border: SDLColor, borderWidth: Int, z: Int)
    >> RendererClient.drawCmd(_:)

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
`RendererClient` is the actual current GameEngine API used by this source file; package-green
failure of that existing boundary remains a release concern outside this docs-only milestone.

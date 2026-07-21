# Sources/Tennis/TennisPresentation.swift — TennisHUD Signature

```text
// TARGET: Tennis executable
// OWNED BY: TennisHUD owns match-overlay layout and visual state. TennisScene creates it and calls
// it for match frames; it does not own score, simulation, input, or event history.
// DEPENDENCIES: TennisMatchSnapshot, TennisMatchFeedbackState, TennisChargeSnapshot, and
// TennisFaultCallout from this source file/runtime; GameEngine Font, DisplayRenderClient, DrawCmd,
// SDLColor, Rect, Point, and TTF glyph APIs. No direct TennisCore mutation or TennisInput access.

TennisChargeSnapshot | Equatable
  pub activeSide
  pub value
  pub capReached
  pub init(activeSide: TennisSide, value: Int, capReached: Bool)

TennisHUD
  priv scoreLayout: Rect<Int>
  priv serverLayout: Rect<Int>
  priv chargeLayout: Rect<Int>
  priv font: Font
  pub init(font: Font)
  pub draw(_ snapshot: TennisMatchSnapshot, feedback: TennisMatchFeedbackState, renderer: DisplayRenderClient)
    >> drawText(_:at:color:renderer:) fill(_:rect:color:z:)
       TennisMatchSnapshot.charge TennisMatchFeedbackState.faultCallout
  priv drawText(_ text: String, at point: Point<Int>, color: SDLColor, renderer: DisplayRenderClient)
    >> Font.resourceId(for:) DisplayRenderClient.draw(_:_:_:_:_:_:_:_:_:_:)
  priv fill(_ renderer: DisplayRenderClient, rect: Rect<Int>, color: SDLColor, z: Int)
    >> DisplayRenderClient.drawCmd(_:)
```

The current implementation draws score/server text with TTF glyph resources, anchors the charge
bar to the projected active-side player position, and draws the `FAULT` callout when feedback
contains one. It does not split score/server/charge into separate private methods; `draw` is the
single HUD rendering entry point. Menu text is separated behind `TennisTextRenderer`; HUD text uses
its injected `Font` directly.

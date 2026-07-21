# Tennis Match HUD Signature

```text
// TARGET: Tennis executable
// OWNED BY: TennisHUD owns match-overlay layout and visual state for the active match. It is
// created and drawn by TennisScene; it does not own score, simulation, input, or event history.
// DEPENDENCIES: TennisMatchSnapshot and TennisMatchPresentationEvent from Tennis runtime;
// GameEngine DisplayRenderClient, DrawCmd, SDLColor, Rect, Point, and TTF font APIs. No direct
// TennisCore mutation, TennisInput dependency, or VirtualDrive access outside the asset boundary.

TennisHUD
  priv scoreLayout: Rect<Int>
  priv serverLayout: Rect<Int>
  priv chargeLayout: Rect<Int>
  priv font: Font
  init(font: Font)
  draw(_ snapshot: TennisMatchSnapshot, feedback: TennisMatchFeedbackState, renderer: DisplayRenderClient)
    >> drawScore(_:renderer:) drawServer(_:renderer:) drawCharge(_:renderer:)
  priv drawScore(_ score: TennisMatchScore, renderer: DisplayRenderClient)
  priv drawServer(_ server: TennisSide, renderer: DisplayRenderClient)
  priv drawCharge(_ charge: TennisChargeSnapshot, renderer: DisplayRenderClient)

TennisChargeSnapshot | Equatable
  pub activeSide: TennisSide
  pub value: Int
  pub capReached: Bool
  pub init(activeSide: TennisSide, value: Int, capReached: Bool)
```

The score uses the engine TTF font and is laid out for unscaled `160x144` readability. The server
indicator is derived from the snapshot's authoritative server. The charge indicator is anchored
to the active player's projected sprite position, not a fixed HUD corner; `capReached` drives the
RVK-6 cue. `TennisScene` owns court/player/ball projection and delegates overlay drawing to this
type, so the HUD cannot become a second scene or a second simulation observer.

The coordinator must expose the latest human/CPU charge in its presentation snapshot. The value
is produced by fixed-step controller intents and copied at the snapshot boundary; HUD code must
not inspect `TennisInputRouter` or infer charge from frame timing.

// TEST: constructing the app graph creates one HUD with the same logical 160x144 layout used by
// TennisScene and does not create a second coordinator.
// TEST: a snapshot with score/server/charge changes produces the corresponding visible state;
// full charge sets the cap cue and point reset clears it.
// TEST: score digits remain legible at native logical resolution with the engine TTF font.

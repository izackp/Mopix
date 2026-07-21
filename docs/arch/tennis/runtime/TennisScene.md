# Sources/Tennis/TennisScene.swift [Tennis]

```text
// TARGET: Tennis executable
// OWNED BY: TennisScene owns renderer-facing court projection, draw-layer IDs, feedback reduction
// consumption, and delegation to HUD/menu presentation. It reads immutable snapshots/events from
// injected runtime objects; it does not own match or simulation state.
// DEPENDENCIES: GameEngine IDrawable, DisplayRenderClient, DrawCmd, SDL2Swift value types;
// TennisMatchCoordinator/TennisMatchSnapshot; TennisHUD; TennisPresentationFlow; and
// TennisMatchFeedbackReducer. No TennisInput dependency and no renderer-to-simulation mutation.

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
  priv hud: TennisHUD?
  priv presentation: TennisPresentationFlow?
  priv feedback: TennisMatchFeedbackReducer
  init(coordinator: TennisMatchCoordinator)
  init(coordinator: TennisMatchCoordinator, hud: TennisHUD, presentation: TennisPresentationFlow? = nil)
  draw(_ delta: UInt64, _ renderer: DisplayRenderClient)
    >> TennisPresentationFlow.state TennisPresentationFlow.draw(renderer:)
       TennisMatchCoordinator.snapshot() TennisMatchCoordinator.consumePresentationEvents()
       TennisMatchFeedbackReducer.consume(_:tick:) TennisMatchFeedbackReducer.advance(to:)
       render(_:renderer:) TennisHUD.draw(_:feedback:renderer:)
  priv render(_ snapshot: TennisMatchSnapshot, renderer: DisplayRenderClient)
    >> playerRect(for:in:) ballRect(for:in:)
       TennisMatchFeedbackReducer.state fill(_:id:rect:color:z:)
       view(_:id:rect:fill:border:borderWidth:z:)
  priv playerRect(for player: TennisPlayerState?, in court: Rect<Int>) -> Rect<Int>
  priv ballRect(for ball: TennisBallState, in court: Rect<Int>) -> Rect<Int>
  priv projectedPoint(_ point: TennisPoint, in court: Rect<Int>) -> Point<Int>
    << playerRect(for:in:) ballRect(for:in:)
  priv fill(_ renderer: DisplayRenderClient, id: UInt64, rect: Rect<Int>, color: SDLColor, z: Int)
    >> DisplayRenderClient.drawCmd(_:)
  priv view(_ renderer: DisplayRenderClient, id: UInt64, rect: Rect<Int>, fill: SDLColor, border: SDLColor, borderWidth: Int, z: Int)
    >> DisplayRenderClient.drawCmd(_:)

  Layer
    background court courtBorder topServiceLine bottomServiceLine centerServiceLine
    netBand netPosts topCenterMark bottomCenterMark lowerPlayer upperPlayer ball
```

The legacy initializer creates a match-only scene with no HUD or menu flow. The app initializer
uses the presentation initializer, so non-match screens draw the flow after the background and
return before court rendering. Match frames render court/player/ball geometry, consume queued
presentation events at the coordinator tick, advance transient feedback, and draw the HUD.
Airborne ball shadow, shot/point-end cues, and surface-specific bounce cues are emitted as draw
commands from `render`; hard, clay, and grass use distinct cue IDs/colors. The coordinator
injected here must be the same selected coordinator registered with Application's fixed-tick and
event loops; scene injection is not a passive reference to the initial coordinator.

// TEST: the legacy scene projects snapshot positions to the expected 160x144 court rectangles.
// TEST: the presentation scene draws title/surface-select/result through the flow and match frames
// consume each coordinator event once before drawing HUD and feedback.
// TEST: a selected-surface replacement leaves scene snapshots, fixed ticks, event delivery, and
// feedback events sourced from one coordinator identity.

# Sources/Tennis/TennisPresentation.swift — Menu and Result Flow Signature

```text
// TARGET: Tennis executable
// OWNED BY: TennisPresentationFlow owns title/surface-select/match/result screen state and the
// player-controlled continuation transition. It owns selected-surface state, not TennisCore
// rules, score, fixed-tick stepping, or renderer transport.
// DEPENDENCIES: GameEngine IEventListener, SDL_Event/SDL_KEYDOWN, DisplayRenderClient, DrawCmd,
// Font, SDLColor/Point; CourtSurface, PointEndReason, TennisMatchCoordinator,
// TennisMatchDelegate, TennisMatchScore, TennisResultSnapshot, and TennisTextRenderer. The match
// factory and text renderer are injected;
// this type does not load fonts or register event/fixed-tick listeners.

TennisScreen | Equatable
  title | surfaceSelect | match | result

TennisMenuCommand | Equatable
  start | chooseSurface(CourtSurface) | continue

TennisResultSnapshot | Equatable
  pub winner
  pub score
  pub init(winner: TennisSide, score: TennisMatchScore)

TennisPresentationState | Equatable
  pub screen
  pub selectedSurface
  pub result
  pub init(screen: TennisScreen = .title)

TennisTextRenderer
  draw(_ text: String, at point: Point<Int>, color: SDLColor, z: Int, renderer: DisplayRenderClient)

TennisFontTextRenderer < TennisTextRenderer
  priv font: Font
  init(font: Font)
  draw(_ text: String, at point: Point<Int>, color: SDLColor, z: Int, renderer: DisplayRenderClient)
    >> Font.resourceId(for:) DisplayRenderClient.draw(_:_:_:_:_:_:_:_:_:_:)

TennisPresentationFlow < TennisMatchDelegate | IEventListener
  pub private(set) state: TennisPresentationState
  priv matchFactory: (CourtSurface) -> TennisMatchCoordinator
  priv textRenderer: TennisTextRenderer
  priv coordinator: TennisMatchCoordinator?
  onCoordinatorChange: Void)?
  integrationCoordinator: TennisMatchCoordinator?
  pub init(matchFactory: @escaping (CourtSurface) -> TennisMatchCoordinator, textRenderer: TennisTextRenderer)
    >> TennisTextRenderer.draw(_:at:color:z:renderer:)
  pub onCommand(_ command: TennisMenuCommand)
  pub onEvents(_ events: [SDL_Event])
  pub draw(renderer: DisplayRenderClient)
  pub matchDidEndPoint(_ reason: PointEndReason, winner: TennisSide, score: TennisMatchScore)
  pub matchDidComplete(_ winner: TennisSide, score: TennisMatchScore)
  pub makeObservation(feedback: TennisMatchFeedbackState = TennisMatchFeedbackState(),
    glyphTexts: [String] = [], drawCommandIDs: [UInt64] = []) -> TennisPresentationObservation
  priv beginMatch(surface: CourtSurface)
    >> matchFactory(surface) TennisMatchCoordinator.delegate = self
       TennisPresentationState.setter:screen
       TennisPresentationState.setter:selectedSurface
       TennisPresentationState.setter:result
  priv beginSurfaceSelect()
    >> TennisPresentationState.setter:screen TennisPresentationState.setter:result
  priv drawText(_ text: String, x: Int, y: Int, renderer: DisplayRenderClient)
    >> TennisTextRenderer.draw(_:at:color:z:renderer:)
```

The legal state path is `title -> surfaceSelect -> match -> result -> surfaceSelect`. Keydown
events start the title, map keys 1/2/3 to hard/clay/grass selection, and continue from result;
match keydowns are left to the coordinator's input listener. `matchDidComplete` stores the winner
and enters result; no timer or automatic continuation exists. `beginSurfaceSelect` clears the
held coordinator/result reference.

`TennisApp` injects a per-surface coordinator factory and a font-backed text renderer. The factory
creates a new simulation/coordinator with selected `CourtRules.surface`; the flow assigns itself
as delegate, stores it, and invokes `onCoordinatorChange`. `TennisApp` then removes the old
coordinator and installs the selected instance in the scene and both Application listener loops.
Returning to surface select invokes the callback with nil, removing the active session and
clearing scene feedback. All live boundaries therefore refer to one coordinator identity.

// TEST: command/state transitions accept only the legal path and invalid commands leave state
// unchanged.
// TEST: result state holds winner/score until continue, then returns to surface select.
// TEST: app construction registers the flow as an SDL event listener and the coordinator as the
// fixed-tick/event listener used by the match scene.

## Deterministic headless evidence seam

The runtime exposes a deterministic observation seam that records visible state without a human,
wall-clock timing, or screenshot interpretation:

```text
TennisPresentationObservation | Equatable
  screen: TennisScreen
  selectedSurface: CourtSurface?
  activeMatchSurface: CourtSurface?
  coordinatorIdentity: ObjectIdentifier?
  result: TennisResultSnapshot?
  score: TennisMatchScore?
  charge: TennisChargeSnapshot?
  feedback: TennisMatchFeedbackState
  glyphTexts: [String]
  drawCommandIDs: [UInt64]
  init(screen: TennisScreen, selectedSurface: CourtSurface?, activeMatchSurface: CourtSurface?,
    coordinatorIdentity: ObjectIdentifier?, result: TennisResultSnapshot?, score: TennisMatchScore?,
    charge: TennisChargeSnapshot?, feedback: TennisMatchFeedbackState, glyphTexts: [String],
    drawCommandIDs: [UInt64])

TennisHeadlessEvidenceSink
  priv observations: [TennisPresentationObservation]
  init()
  observe(_ observation: TennisPresentationObservation)
  finish() -> [TennisPresentationObservation]
```

`makeObservation` snapshots the current screen, selected/active surface, coordinator identity,
result, score, charge, feedback, glyph text, and draw-command IDs. `TennisHeadlessEvidenceSink`
owns the ordered observation buffer; `observe` appends one frame and `finish` returns the trace.
`TennisHeadlessScenario` drives this seam from fixed and post-draw `IUpdate` adapters and writes
the finished trace when `TennisApp` is launched headlessly with `--tennis-evidence`.

The harness must use the same selected coordinator/session seam as the app graph, inject a
recording `TennisTextRenderer`, and use a recording `DisplayRenderClient`. A passing trace is:
title glyphs → `.start` → surface-select glyphs → `.chooseSurface(.hard/.clay/.grass)` → match
observation whose active surface and coordinator identity are selected → one fixed tick with
shot/fault or bounce feedback and HUD score/server/active-charge glyph commands → result
observation with winner/score held across at least two draws → `.continue` → surface-select with
the prior result cleared. The trace must show distinct `CourtRules.surface`, feedback cue, and
draw-command evidence for each selected surface; a title-only PNG is insufficient.

// TEST: the observation trace proves the exact sequence; glyphTexts and drawCommandIDs are
// non-empty for every visible text/cue assertion.
// TEST: result remains observable and unchanged during the hold interval, then continue produces
// exactly one surface-select transition and clears the held result.

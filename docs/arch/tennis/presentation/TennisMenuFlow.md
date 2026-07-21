# Sources/Tennis/TennisPresentation.swift — Menu and Result Flow Signature

```text
// TARGET: Tennis executable
// OWNED BY: TennisPresentationFlow owns title/surface-select/match/result screen state and the
// player-controlled continuation transition. It owns selected-surface state, not TennisCore
// rules, score, fixed-tick stepping, or renderer transport.
// DEPENDENCIES: GameEngine IEventListener, SDL_Event/SDL_KEYDOWN, DisplayRenderClient, DrawCmd;
// CourtSurface, TennisMatchCoordinator, TennisMatchDelegate, TennisMatchScore, and
// TennisResultSnapshot. The match factory is an injected closure, not a declared factory type.

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

TennisPresentationFlow < TennisMatchDelegate | IEventListener
  pub private(set) state: TennisPresentationState
  priv matchFactory: (CourtSurface) -> TennisMatchCoordinator
  priv coordinator: TennisMatchCoordinator?
  pub init(matchFactory: @escaping (CourtSurface) -> TennisMatchCoordinator)
  pub onCommand(_ command: TennisMenuCommand)
  pub onEvents(_ events: [SDL_Event])
  pub draw(renderer: DisplayRenderClient)
  pub matchDidEndPoint(_ reason: PointEndReason, winner: TennisSide, score: TennisMatchScore)
  pub matchDidComplete(_ winner: TennisSide, score: TennisMatchScore)
  priv beginMatch(surface: CourtSurface)
    >> matchFactory(surface) TennisMatchCoordinator.delegate = self
       TennisPresentationState.setter:screen
       TennisPresentationState.setter:selectedSurface
       TennisPresentationState.setter:result
  priv beginSurfaceSelect()
    >> TennisPresentationState.setter:screen TennisPresentationState.setter:result
  priv drawText(_ text: String, x: Int, y: Int, renderer: DisplayRenderClient)
    >> DisplayRenderClient.drawCmd(_:)
```

The legal state path is `title -> surfaceSelect -> match -> result -> surfaceSelect`. Keydown
events start the title, map keys 1/2/3 to hard/clay/grass selection, and continue from result;
match keydowns are left to the coordinator's input listener. `matchDidComplete` stores the winner
and enters result; no timer or automatic continuation exists. `beginSurfaceSelect` clears the
held coordinator/result reference.

`TennisApp` injects a closure that currently returns its single hard-court coordinator regardless
of the selected surface. The callback shape carries `CourtSurface`, but the current app graph is
not yet a per-surface factory; this is an implementation limitation, not an unrecorded dependency.

// TEST: command/state transitions accept only the legal path and invalid commands leave state
// unchanged.
// TEST: result state holds winner/score until continue, then returns to surface select.
// TEST: app construction registers the flow as an SDL event listener and the coordinator as the
// fixed-tick/event listener used by the match scene.

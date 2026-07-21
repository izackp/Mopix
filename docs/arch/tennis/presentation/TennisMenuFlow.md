# Tennis Menu and Result Flow Signature

```text
// TARGET: Tennis executable
// OWNED BY: TennisPresentationFlow owns title/surface-select/match/result screen state and the
// player-controlled continuation transition. It owns the selected surface, not TennisCore rules
// or match score.
// DEPENDENCIES: GameEngine IDrawable, DisplayRenderClient, input command boundary, CourtSurface,
// TennisMatchCoordinator factory, TennisMatchSnapshot, and TennisMatchDelegate callbacks. No
// direct simulation stepping and no renderer-to-gameplay mutation.

TennisScreen | title | surfaceSelect | match | result

TennisMenuCommand | start | chooseSurface(CourtSurface) | continue

TennisPresentationState
  pub screen: TennisScreen
  pub selectedSurface: CourtSurface?
  pub result: TennisResultSnapshot?
  pub init(screen: TennisScreen = .title)

TennisResultSnapshot | Equatable
  pub winner: TennisSide
  pub score: TennisMatchScore
  pub init(winner: TennisSide, score: TennisMatchScore)

TennisPresentationFlow < TennisMatchDelegate
  pub state: TennisPresentationState
  pub init(matchFactory: TennisMatchFactory)
  pub onCommand(_ command: TennisMenuCommand)
  pub draw(renderer: DisplayRenderClient)
  pub matchDidEndPoint(_ reason: PointEndReason, winner: TennisSide, score: TennisMatchScore)
  pub matchDidComplete(_ winner: TennisSide, score: TennisMatchScore)
  priv beginMatch(surface: CourtSurface)
    >> TennisMatchFactory.make(surface:)
  priv continueFromResult()
    >> beginSurfaceSelect()
  priv beginSurfaceSelect()

TennisMatchFactory
  make(surface: CourtSurface) -> TennisMatchCoordinator
```

The only legal screen transitions are `title -> surfaceSelect -> match -> result ->
surfaceSelect`. Surface selection is passed into the match factory; no surface is hardcoded past
that boundary. The factory applies the fixed MVP presets (human Balanced, CPU Power). Result state
is held until `continue`, with no timer or automatic restart. A new coordinator is created for the
next selected surface; the old completed coordinator is not reused or reset by the menu.

// TEST: app-graph construction starts at title, creates no match coordinator until a surface is
// chosen, and wires the created coordinator as the delegate source for the match screen.
// TEST: each accepted command produces only an allowed screen transition and invalid commands
// leave state unchanged.
// TEST: match completion visibly enters result, holds winner/score, and continue returns to
// surface select without auto-starting another match.

# Tennis Presentation Architecture

Source map: `Sources/Tennis/TennisPresentation.swift.map` generated from
`Sources/Tennis/TennisPresentation.swift`.

## Dependency and ownership boundary

```text
TennisApp
  owns -> TennisPresentationFlow
  owns -> TennisMatchCoordinator
  owns -> TennisHUD
  owns -> TennisScene

TennisMatchCoordinator
  publishes -> TennisMatchSnapshot
  queues -> TennisMatchPresentationEvent

TennisPresentationFlow
  owns -> current screen and selected surface

TennisScene
  consumes -> TennisMatchSnapshot, queued TennisMatchPresentationEvent
  draws -> court, players, ball, HUD, transient feedback
```

Presentation owns no gameplay rules, fixed-tick clock, controller state, score mutation, or asset
loading. `TennisCore` remains renderer-free. `TennisInput` remains responsible for command
translation and shot-sequence resolution; presentation receives read-only charge values through
the match snapshot rather than reaching into the input router.

All presentation types currently live in `Sources/Tennis/TennisPresentation.swift`; the slice is
documented as [TennisMatchHUD.md](TennisMatchHUD.md),
[TennisMatchFeedback.md](TennisMatchFeedback.md), and [TennisMenuFlow.md](TennisMenuFlow.md).

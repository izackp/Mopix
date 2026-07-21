# Tennis Presentation Architecture

## Dependency and ownership boundary

```text
TennisApp
  owns -> TennisPresentationFlow
  owns -> TennisMatchCoordinator
  owns -> TennisScene

TennisMatchCoordinator
  publishes -> TennisMatchSnapshot
  publishes -> TennisMatchPresentationEvent

TennisPresentationFlow
  owns -> current screen and selected surface

TennisScene
  reads -> TennisMatchSnapshot, TennisMatchPresentationEvent
  draws -> court, players, ball, HUD, transient feedback
```

Presentation owns no gameplay rules, fixed-tick clock, controller state, score mutation, or asset
loading. `TennisCore` remains renderer-free. `TennisInput` remains responsible for command
translation and shot-sequence resolution; presentation receives read-only charge values through
the match snapshot rather than reaching into the input router.

The slice is split into [TennisMatchHUD.md](TennisMatchHUD.md),
[TennisMatchFeedback.md](TennisMatchFeedback.md), and [TennisMenuFlow.md](TennisMenuFlow.md).

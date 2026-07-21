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
  delegates -> selected-surface match factory
  renders -> injected TennisTextRenderer glyphs

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

The selected coordinator is an application-graph invariant: the coordinator created for the
selected surface must be the exact instance injected into `TennisScene` and registered with
Application's fixed-tick and event loops. The flow's factory callback alone does not establish
that invariant. The integration accessors used by focused tests verify this identity and listener
registration; they are not runtime presentation state or a Tennis-specific headless evidence API.

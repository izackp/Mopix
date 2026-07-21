# Sources/Tennis/TennisApp.swift [Tennis]

```text
// TARGET: Tennis executable
// OWNED BY: TennisApp owns application/window construction and registration of the live runtime
// graph. Match state remains owned by TennisMatchCoordinator/TennisCore; presentation state
// remains owned by TennisPresentationFlow.
// DEPENDENCIES: GameEngine Application, FullWindow, fixed-update/event registration, FontDesc,
// Font, and GenericError; SDL2Swift value types; TennisCore; TennisInput; TennisMatchCoordinator;
// TennisPresentationFlow; TennisTextRenderer/TennisFontTextRenderer; TennisHUD; TennisScene.
// No gameplay mutation in the renderer graph.

TennisApp
  logicalSize: Size<Int>
  priv matchCoordinator: TennisMatchCoordinator!
  priv presentation: TennisPresentationFlow!
  priv scene: TennisScene!
  private(set) registeredFixedCoordinatorCount: Int
  private(set) registeredEventCoordinatorCount: Int
  init() throws
    >> TennisMatchCoordinator.init(simulation:scorekeeper:humanController:cpuController:)
       TennisPresentationFlow.init(matchFactory:textRenderer:)
       FullWindow.init(...)
       FullWindow.imageManager.fetchFont(desc:)
       TennisHUD.init(font:)
       TennisScene.init(coordinator:hud:presentation:)
       FullWindow.drawable = TennisScene
       Application.addFixedListener(_:msPerTick:)
       Application.addEventListener(_:)
       TennisPresentationFlow.onCoordinatorChange
  priv replaceCoordinator(_ replacement: TennisMatchCoordinator?)
    >> Application.removeFixedListener(_:)
       Application.removeEventListener(_:)
       TennisScene.replaceCoordinator(_:)
       TennisScene.resetPresentationFeedback()
       Application.addFixedListener(_:msPerTick:)
       Application.addEventListener(_:)
  var integrationPresentation: TennisPresentationFlow
  var integrationSceneCoordinator: TennisMatchCoordinator
  var integrationRegisteredCoordinator: TennisMatchCoordinator?
  static makeSimulation(surface: CourtSurface = .hard) -> TennisSimulation
  static makeCoordinator(surface: CourtSurface) -> TennisMatchCoordinator
  priv static makeCoordinator(surface: CourtSurface, simulation: TennisSimulation,
    humanRouter: TennisInputRouter) -> TennisMatchCoordinator
  #if DEBUG
  integrationGraph -> (coordinator: TennisMatchCoordinator, fixedCount: Int, eventCount: Int)
  #endif
    << wrapperMain(argc:argv:)

TennisVirtualControllerInputSource < TennisHumanInputSource
  frame(for controller: VirtualController) -> TennisInputFrame
```

`TennisApp.init()` currently constructs an initial hard-court coordinator, injects it into the
scene, registers it with both the fixed-tick and SDL event loops, and registers the flow as a
second SDL event listener. The flow receives a per-surface factory and a
`TennisFontTextRenderer` backed by the fetched TTF font. `makeSimulation(surface:)` and
`makeCoordinator(surface:)` create distinct surface-specific `CourtRules`/simulation graphs.

The logical play area is `160x144`. `makeSimulation(surface:)` constructs `CourtRules.surface`
from its argument and uses the fixed MVP seeds/presets; the default remains `.hard`. The
`replaceCoordinator(_:)` is the selected-session boundary. It removes the old coordinator from
both Application loops before installing the replacement in the scene and both loops. A nil
replacement removes the active session and resets scene feedback. The integration accessors and
DEBUG-only `integrationGraph` are observation seams, not runtime presentation state.

// TEST: app construction creates one coordinator shared by the scene and fixed listener, and
// registers exactly one coordinator fixed listener plus one coordinator event listener.
// TEST: makeSimulation(.hard), makeSimulation(.clay), and makeSimulation(.grass) expose the
// corresponding CourtRules.surface values while preserving fixed seeds/presets.

## REVIEW-25 required selected-session fix contract

The coordinator returned by `matchFactory(selectedSurface)` must become the one live match
coordinator. TennisApp must inject that exact instance into TennisScene and register that same
instance with `Application.addFixedListener(_:msPerTick:)` and `Application.addEventListener(_:)`.
The old coordinator must be removed from both loops before the new coordinator is installed; the
flow delegate must point at the new instance. The swap must be atomic at a fixed-tick boundary and
leave exactly one active coordinator in each loop.

The current stored-property graph cannot satisfy this after surface selection because the factory
result is not installed. The next implementation milestone must provide an explicit replacement
boundary that removes old registrations, creates the selected coordinator, injects it into the
scene, and adds both registrations. No second coordinator may run in parallel and no scene may
retain the pre-selection coordinator.

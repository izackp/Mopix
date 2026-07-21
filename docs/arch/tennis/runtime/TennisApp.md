# Sources/Tennis/TennisApp.swift [Tennis]

```text
// TARGET: Tennis executable
// OWNED BY: TennisApp owns application/window construction and the single live runtime graph:
// one TennisMatchCoordinator, one TennisPresentationFlow, and one TennisScene. Match state remains
// owned by TennisMatchCoordinator/TennisCore; presentation state remains owned by the flow.
// DEPENDENCIES: GameEngine Application, FullWindow, fixed-update/event registration, FontDesc,
// Font, and GenericError; SDL2Swift value types; TennisCore; TennisInput; TennisMatchCoordinator;
// TennisPresentationFlow; TennisHUD; TennisScene. No gameplay mutation in the renderer graph.

TennisApp
  logicalSize: Size<Int>
  priv matchCoordinator: TennisMatchCoordinator!
  priv presentation: TennisPresentationFlow!
  priv scene: TennisScene!
  priv registeredFixedCoordinatorCount: Int
  priv registeredEventCoordinatorCount: Int
  init() throws
    >> TennisMatchCoordinator.init(simulation:scorekeeper:humanController:cpuController:)
       TennisPresentationFlow.init(matchFactory:)
       FullWindow.init(...)
       FullWindow.imageManager.fetchFont(desc:)
       TennisHUD.init(font:)
       TennisScene.init(coordinator:hud:presentation:)
       FullWindow.drawable = TennisScene
       Application.addFixedListener(_:msPerTick:)
       Application.addEventListener(_:)
  static makeSimulation() -> TennisSimulation
  #if DEBUG
  integrationGraph -> (coordinator: TennisMatchCoordinator, fixedCount: Int, eventCount: Int)
  #endif
    << wrapperMain(argc:argv:)

TennisVirtualControllerInputSource < TennisHumanInputSource
  frame(for controller: VirtualController) -> TennisInputFrame
```

`TennisApp` constructs one hard-court coordinator through `makeSimulation()`, injects that same
coordinator into the presentation factory closure and scene, registers the coordinator as the
fixed-tick and SDL event listener, and registers `TennisPresentationFlow` as a second SDL event
listener. The app creates a TTF font through the window image manager and passes it to
`TennisHUD`. The current factory closure accepts a `CourtSurface` but returns the already-created
coordinator; it is therefore a callback boundary, not yet a per-surface coordinator factory.

The logical play area is `160x144`. `makeSimulation()` currently constructs `CourtRules.surface`
as `.hard` and uses the fixed MVP seeds/presets. The `integrationGraph` seam is DEBUG-only and
exists for app-graph verification; it is not runtime presentation state.

// TEST: app construction creates one coordinator shared by the scene and fixed listener, and
// registers exactly one coordinator fixed listener plus one coordinator event listener.
// TEST: two calls to makeSimulation() produce equal initial snapshots.

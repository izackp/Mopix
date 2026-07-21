# Sources/Tennis/TennisApp.swift [Tennis]

```text
// TARGET: Tennis executable
// OWNED BY: TennisApp owns application/window construction and the single live runtime graph:
// TennisMatchCoordinator plus the TennisScene that reads its snapshots. Match state remains
// owned by the coordinator/core.
// DEPENDENCIES: GameEngine application/window/fixed-update/event APIs and SDL2Swift;
// TennisCore; TennisInput; TennisMatchCoordinator; TennisScene. No renderer-owned gameplay
// mutation.

TennisApp
  logicalSize: Size<Int>
  priv matchCoordinator: TennisMatchCoordinator
  priv scene: TennisScene
  init()!
    >> TennisMatchCoordinator.init(simulation:scorekeeper:humanController:cpuController:)
       TennisScene.init(coordinator:)
       FullWindow.init(...)
       Window.drawable = TennisScene
    >> Application.addFixedListener(_:msPerTick:)
    >> Application.addEventListener(_:)
    << wrapperMain(argc:argv:)
```

The application logical size is `160x144`. `TennisApp` constructs one coordinator and injects that
same instance into the window drawable. It registers the coordinator once as both the
`IUpdate` fixed listener and the `IEventListener`; engine events therefore enter TennisInput
through the coordinator's queued `TennisInputRouter` path, and gameplay advances only from the
registered fixed callback. `TennisScene` never receives raw engine events and never mutates the
coordinator.

// TEST: application assembly uses one coordinator instance for scene, fixed updates, and events.
// TEST: an SDL command delivered by the engine reaches TennisInput on the next fixed callback.
// TEST: the fixed callback produces a post-simulation snapshot that the drawable renders.

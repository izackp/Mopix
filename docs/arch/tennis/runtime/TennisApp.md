# Sources/Tennis/TennisApp.swift [Tennis]

```text
// TARGET: Tennis executable
// OWNED BY: TennisApp owns application/window construction and installs TennisScene plus the
// fixed-tick TennisMatchCoordinator. Match state remains owned by the coordinator/core.
// DEPENDENCIES: GameEngine application/window/fixed-update/event APIs and SDL2Swift;
// TennisCore; TennisInput; TennisMatchCoordinator. No renderer-owned gameplay mutation.

TennisApp
  logicalSize: Size<Int>
  priv matchCoordinator: TennisMatchCoordinator
  init()!
    >> TennisMatchCoordinator.init(simulation:scorekeeper:humanController:cpuController:)
    >> Application.addFixedListener(_:msPerTick:)
    >> Application.addEventListener(_:)
    << wrapperMain(argc:argv:)
```

The application logical size is `160x144`. The window's drawable remains `TennisScene`; the
coordinator is registered separately as the fixed-tick/event owner. Gameplay contracts remain
split by map group: scoring in TennisCore, input/controllers in TennisInput, and orchestration in
the Tennis runtime.

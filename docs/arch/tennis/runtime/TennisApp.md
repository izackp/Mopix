# Sources/Tennis/TennisApp.swift [Tennis]

```text
// TARGET: Tennis executable
// OWNED BY: TennisApp owns application/window construction and installs TennisScene as the
// window drawable. It does not own simulation or input contracts.
// DEPENDENCIES: GameEngine application/window APIs and SDL2Swift. No TennisCore mutation.

TennisApp
  logicalSize: Size<Int>
  init()!
    << wrapperMain(argc:argv:)
```

The application logical size is `160x144`. The window's drawable is `TennisScene`; fixed-tick
gameplay contracts remain in the lower-level TennisCore/TennisInput documents.

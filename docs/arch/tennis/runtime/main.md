# Sources/Tennis/main.swift [Tennis]

```text
// TARGET: Tennis executable
// OWNED BY: this file owns platform entry-point and test-process delegation only.
// DEPENDENCIES: SDL2/SDL2Swift, Cocoa on macOS, and TennisApp.

AppDelegateTesting < NSObject | NSApplicationDelegate
  applicationDidFinishLaunching(_ aNotification: Notification)
  applicationWillTerminate(_ aNotification: Notification)

runTestsMacOs()
  >> AppDelegateTesting.init() NSApplication.shared NSApplication.run()

wrapperMain(argc: Int32, argv: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?) -> Int32
  >> TennisApp.init() Application.runLoop()
```

The platform wrapper owns process startup and test-process delegation. It does not own Tennis
simulation, controllers, or presentation state.

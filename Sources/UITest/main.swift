//
//  main.swift
//  TestGame
//
//  Created by Isaac Paul on 4/13/22.
//

import SDL2
import SDL2Swift

#if os(macOS)
import Cocoa

class AppDelegateTesting: NSObject, NSApplicationDelegate {
  func applicationDidFinishLaunching(_ aNotification: Notification) {
    print("Unit Testing Run")
    // Insert code here to initialize your application
  }

  func applicationWillTerminate(_ aNotification: Notification) {
    // Insert code here to tear down your application
  }
}

func runTestsMacOs() {
    let delegate = AppDelegateTesting()
    NSApplication.shared.delegate = delegate
    NSApplication.shared.run()
}

let isRunningTests = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
if isRunningTests {
    runTestsMacOs()
    exit(EXIT_SUCCESS)
}
#endif

public func wrapperMain(argc:Int32, argv:UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?) -> Int32 {
    do {
        let app = try UITestApp()
        try app.runLoop()
    }
    catch let error as SDLError {
        print("Error: \(error.debugDescription)")
        exit(EXIT_FAILURE)
    }
    catch {
        print("Error: \(error.localizedDescription)")
        exit(EXIT_FAILURE)
    }
    return 0
}

#if os(macOS)
    let _ = wrapperMain(argc: CommandLine.argc, argv: CommandLine.unsafeArgv)
#elseif os(iOS)
    SDL_UIKitRunApp(CommandLine.argc, CommandLine.unsafeArgv, wrapperMain)
#elseif os(Windows)
    SDL_RegisterApp("TestGame", 0, nil)
    let result = wrapperMain(argc: CommandLine.argc, argv: CommandLine.unsafeArgv)
    SDL_UnregisterApp()
#else
    let result = wrapperMain(argc: CommandLine.argc, argv: CommandLine.unsafeArgv)
#endif

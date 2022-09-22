//
//  main.swift
//  TestGame
//
//  Created by Isaac Paul on 4/13/22.
//

import Foundation

#if os(macOS)
class AppDelegateTesting: NSObject, NSApplicationDelegate {
  func applicationDidFinishLaunching(_ aNotification: Notification) {
    print("Unit Testing Run")
    // Insert code here to initialize your application
  }

  func applicationWillTerminate(_ aNotification: Notification) {
    // Insert code here to tear down your application
  }
}
#endif
func main() throws {
    let app = try TestGameApp()
    try app.runLoop()
}

public func wrapperMain(argc:Int32, argv:UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?) -> Int32 {
    do { try main() }
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

#if os(iOS)
import SDL2
#endif


#if os(macOS)
import Cocoa
#endif
//let isRunningTests = NSClassFromString("XCTestCase") != nil && ProcessInfo.processInfo.arguments.contains("-XCUnitTests")
let isRunningTests = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil

if isRunningTests {
    
#if os(macOS)
    let delegate = AppDelegateTesting()
    NSApplication.shared.delegate = delegate
    NSApplication.shared.run()
    #endif
} else {
    #if os(macOS)
    let _ = wrapperMain(argc: CommandLine.argc, argv: CommandLine.unsafeArgv)
    //SDL_UIKitRunApp(CommandLine.argc, CommandLine.unsafeArgv, wrapperMain)
    #else
    SDL_UIKitRunApp(CommandLine.argc, CommandLine.unsafeArgv, wrapperMain)
    #endif
}

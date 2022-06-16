//
//  Main.swift
//  TestGame
//
//  Created by Isaac Paul on 4/11/22.
//

import Foundation
import SDL2

typealias MainCallBack = @convention(c) (
    Int32,
    Optional<UnsafeMutablePointer<Optional<UnsafeMutablePointer<Int8>>>>
) -> Int32


@main
struct MyMain {
    static func main() -> Void {
        SDL_UIKitRunApp(CommandLine.argc, CommandLine.unsafeArgv, finalMain)
    }
    
    //Optional<@convention(c) (Int32, Optional<UnsafeMutablePointer<Optional<UnsafeMutablePointer<Int8>>>>) -> Int32>
    
}

public func finalMain(argc:Int32, argv:UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?) -> Int32 {
    return 0
}


@objc class Main: NSObject {

    @objc static func proxyMain(argc:Int32, argv:UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?) -> Int32 {
        return finalMain(argc: argc, argv: argv)
    }
}

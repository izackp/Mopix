//
//  Window+Ext.swift
//  TestGame
//
//  Created by Isaac Paul on 4/13/22.
//

import Foundation
public extension SDLWindow {
    func fpsHz() throws -> Int {
        let framesPerSecond = try displayMode().refreshRate
        return framesPerSecond
    }
}

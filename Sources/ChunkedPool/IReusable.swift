//
//  IReusable.swift
//  TestGame
//
//  Created by Isaac Paul on 1/26/23.
//

import Foundation

//Necessary functions to exist in the struct
public protocol IReusable {
    init()
    mutating func initHook()
    mutating func clean()
    
    var ID:ContiguousHandle { get set }
    var isAlive:Bool { get set }
}

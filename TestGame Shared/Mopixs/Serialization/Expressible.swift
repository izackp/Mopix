//
//  Expressible.swift
//  TestGame
//
//  Created by Isaac Paul on 8/10/22.
//

import Foundation

public protocol ExpressibleByString {
    init(_ value:String) throws
}

public protocol ExpressibleByInteger {
    init(_ value:Int64) throws
}

public protocol ExpressibleByFloat { //TODO: Float or double?
    init(_ value:Float) throws
}

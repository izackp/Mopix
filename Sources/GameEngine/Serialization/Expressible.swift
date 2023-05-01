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

public protocol ExpressibleByStringWithContext {
    init(_ value:String, _ context:[CodingUserInfoKey : Any]) throws
}

public protocol ExpressibleByInteger {
    init(_ value:Int64) throws
}

public protocol ExpressibleByIntegerWithContext {
    init(_ value:Int64, _ context:[CodingUserInfoKey : Any]) throws
}

public protocol ExpressibleByFloat { //TODO: Float or double?
    init(_ value:Float) throws
}

public protocol ExpressibleByFloatWithContext {
    init(_ value:Float, _ context:[CodingUserInfoKey : Any]) throws
}

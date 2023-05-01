//
//  Shadow.swift
//  TestGame
//
//  Created by Isaac Paul on 10/31/22.
//

import Foundation
public struct Shadow : Hashable, Codable {
    var offset:Point<Float>
    var blurRadius:Float
    var color:UInt32
}

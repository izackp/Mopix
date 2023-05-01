//
//  ContiguousHandle.swift
//  TestGame
//
//  Created by Isaac Paul on 4/19/23.
//

import Foundation
public struct ContiguousHandle {
    public init(index: UInt32) {
        self.index = index
    }
    
    var index:UInt32
    
    public func chunkIndex() -> UInt16 {
        let result = UInt16(index >> 16)
        return result
    }
    public func itemIndex() -> UInt16 {
        let result = UInt16(index & 0xFFFF)
        return result
    }
    
    public func indexes() -> (UInt16, UInt16) {
        let chunk = UInt16(index >> 16)
        let item = UInt16(index & 0xFFFF)
        return (chunk, item)
    }

    public static func buildHandle(chunkIndex:UInt16, index:UInt16) -> ContiguousHandle {
        let finalIndex = UInt32(chunkIndex) << 16 | UInt32(index)
        return ContiguousHandle(index: finalIndex)
    }
}

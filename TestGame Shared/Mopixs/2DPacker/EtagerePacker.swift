//
//  EtagerePacker.swift
//  TestGame
//
//  Created by Isaac Paul on 4/21/22.
//

//French for shelf
//https://nical.github.io/posts/etagere.html
//Not sure if I should port to swift or use c interface with rust
//Will just port because providing a binary seems unintuitive
//And providing source involves modifying the build process which
//I don't want to do yet.
import Foundation


public struct AllocatorOptions {
    
    /// Align item sizes to a multiple of this alignment.
    ///
    /// Default value: [1, 1] (no alignment).
    public var alignment: Size<Int32>
    
    /// Use vertical instead of horizontal shelves.
    ///
    /// Default value: false.
    public var vertical_shelves: Bool
    
    /// If possible split the allocator's surface into multiple columns.
    ///
    /// Having multiple columns allows having more (smaller shelves).
    ///
    /// Default value: 1.
    public var num_columns: Int32
    
    public static func new(alignment:Size<Int32> = Size<Int32>.one, vertical_shelves:Bool = false, num_columns:Int32 = 1) -> AllocatorOptions {
        return AllocatorOptions(alignment: alignment, vertical_shelves: vertical_shelves, num_columns: num_columns)
    }
}

/// The `AllocId` and `Rectangle` resulting from an allocation.
public struct Allocation {
    public var id:AllocId
    public var rectangle:Frame<Int32>
}

/// ID referring to an allocated rectangle.
public struct AllocId : ExpressibleByIntegerLiteral, Equatable {
    public typealias IntegerLiteralType = UInt32
    let value: UInt32

    public init(integerLiteral val: UInt32) {
        self.value = val
    }
    
    public init(_ index:UInt16, _ gen: UInt16) {
        self.value = UInt32(index) | (UInt32(gen) << 16)
    }
    
    @inline(__always) public func index() -> UInt16 {
        return UInt16(truncatingIfNeeded: value)
    }
    
    @inline(__always) public func generation() -> UInt16 {
        return UInt16(value >> 16)
    }
}

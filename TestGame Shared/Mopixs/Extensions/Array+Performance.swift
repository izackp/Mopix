//
//  Array+Performance.swift
//  TestGame
//
//  Created by Isaac Paul on 4/6/23.
//

import Foundation

extension Array {
    //NOTE: Slightly slower than inline
    mutating func iterateUnchecked(_ block: ( _ ptr:UnsafeMutablePointer<Element>, _ i:Int)->()) {
        self.withUnsafeMutableBufferPointer { (ptr:inout UnsafeMutableBufferPointer<Element>) in
            guard let buffer = ptr.baseAddress else { return }
            let len = ptr.count
            for t in 0 ..< len {
                let ptr:UnsafeMutablePointer<Element> = buffer.advanced(by: t)
                block(ptr, t)
            }
        }
    }
    
    mutating func forEachItem(_ block: ( _ item:inout Element)->()) {
        let len = self.count
        
        for i in 0 ..< len {
            block(&self[i])
        }
    }
}

extension ContiguousArray {

    //~0.7ms
    @inline(__always) mutating func iterateUnchecked(_ block: ( _ ptr:UnsafeMutablePointer<Element>, _ i:Int)->()) {
        self.withUnsafeMutableBufferPointer { (ptr:inout UnsafeMutableBufferPointer<Element>) in
            guard let buffer = ptr.baseAddress else { return }
            let len = ptr.count
            for t in 0 ..< len {
                let ptr:UnsafeMutablePointer<Element> = buffer.advanced(by: t)
                block(ptr, t)
            }
        }
    }
    
    //~2ms
    @inline(__always) mutating func forEachItem(_ block: ( _ item:inout Element)->()) {
        let len = self.count
        
        for i in 0 ..< len {
            block(&self[i])
        }
    }
    
    //~2ms
    @inline(__always) mutating func forEachItem(_ block: ( _ item:inout Element, _ i:Int)->()) {
        let len = self.count
        
        for i in 0 ..< len {
            block(&self[i], i)
        }
    }
    
    //~0.7ms - Best option for speed and clean code
    @inline(__always) mutating func forEachUnchecked(_ block: ( _ item:inout Element, _ i:Int)->()) {
        self.withUnsafeMutableBufferPointer { (ptr:inout UnsafeMutableBufferPointer<Element>) in
            guard let buffer = ptr.baseAddress else { return }
            let len = ptr.count
            for t in 0 ..< len {
                let ptr:UnsafeMutablePointer<Element> = buffer.advanced(by: t)
                block(&ptr.pointee, t)
            }
        }
    }
}

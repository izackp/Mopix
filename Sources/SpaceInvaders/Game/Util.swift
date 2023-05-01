//
//  Util.swift
//  TestGame
//
//  Created by Isaac Paul on 6/16/22.
//

import Foundation

struct Ref<T> {
    //http://dmitrysoshnikov.com/compilers/writing-a-pool-allocator/
    let ptr:UnsafeMutablePointer<T>
    
    func with(_ action:(inout T)->()) {
        action(&ptr.pointee)
    }
}

extension UnsafeMutablePointer {
    func with(_ action:(inout Pointee)->()) {
        action(&self.pointee)
    }
}

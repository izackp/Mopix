//
//  Compare.swift
//  
//
//  Created by Isaac Paul on 6/15/23.
//

import Foundation

extension BinaryInteger {
    func compare(_ other:any BinaryInteger) -> ComparisonResult {
        if (self > other) {
            return .orderedAscending
        }
        if (self < other) {
            return .orderedDescending
        }
        return .orderedSame
    }
}

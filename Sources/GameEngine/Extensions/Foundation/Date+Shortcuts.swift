//
//  Date+Shortcuts.swift
//  TestGame
//
//  Created by Isaac Paul on 7/22/22.
//

import Foundation

//NOTE: Thread safe as of iOS 7
fileprivate let formatter = DateFormatter().apply {
    $0.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
}

extension DateFormatter {
    func apply(toApply:(_ input:DateFormatter)->()) -> DateFormatter {
        toApply(self)
        return self
    }
}


extension Date {
    func toString() -> String {
        formatter.string(from: self)
    }
}

extension String {
    func toDate() -> Date? {
        return formatter.date(from: self)
    }
    
    func expectDate() throws -> Date {
        if let result = formatter.date(from: self) {
            return result
        }
        throw GenericError("Unable to convert string to date: \(self)")
    }
}

//
//  GenericError.swift
//  TestGame
//
//  Created by Isaac Paul on 4/26/22.
//

import Foundation


class GenericError: LocalizedError {
    
    let message: String
    
    init(_ message: String) {
        self.message = message
    }
    init(_ message: String, _ error:Error) {
        self.message = "\(message) : \(error)"
    }
    
    static func failure<T>(_ message: String) -> Result<T, GenericError> {
        return .failure(GenericError(message))
    }
    
    var errorDescription: String? {
        get {
            return message
        }
    }
}

func appFailure<T>(_ message:String) -> Result<T, GenericError> {
    return .failure(GenericError(message))
}

public func tryW(_ message:String, _ block:()throws ->()) throws {
    do {
        try block()
    } catch {
        throw GenericError("\(message) : \(error)")
    }
}

public func tryW<T>(_ message:String, _ block:()throws ->(T)) throws -> T {
    do {
        return try block()
    } catch {
        throw GenericError("\(message) : \(error)")
    }
}

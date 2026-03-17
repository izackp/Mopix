//
//  Util.swift
//  TestGame
//
//  Created by Isaac Paul on 4/13/22.
//

import Foundation
func tryOrLog<T>(_ block:() throws ->T) -> T? {
    do {
        let result = try block()
        return result
    } catch let error {
        logExceptionSilent(error)
    }
    return nil
}

func tryOrLog<T>(info:String, _ block:() throws ->T) -> T? {
    do {
        let result = try block()
        return result
    } catch let error {
        logExceptionSilent(error, info)
    }
    return nil
}

func tryOrLogInput<T, R>(_ info:R, _ block:(_ input:R) throws ->T) -> T? {
    do {
        let result = try block(info)
        return result
    } catch let error {
        logExceptionSilent(error, String.init(describing: info))
    }
    return nil
}

//Note: Silent == Silent to the user
func logExceptionSilent(_ error:Error, _ info:String? = nil) {
    print("Exception Thrown: \(String(describing:error)) - \(info ?? "")")
}

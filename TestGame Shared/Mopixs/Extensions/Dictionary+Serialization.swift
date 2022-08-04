//
//  Dictionary+Serialization.swift
//  TestGame
//
//  Created by Isaac Paul on 7/27/22.
//


//count:Int
//color:Color (int, string, or obj)
//crazines:SubColor (obj+type)

import Foundation

public protocol DictionarySerialization {
    init(_ dictionary:[String:Any], _ cache:InstanceCache?) throws
    func toDictionary() -> [String:Any]
}

extension DictionarySerialization {
    static func buildFrom(_ type:String, dict:[String:Any]) throws -> DictionarySerialization {
        switch type {
        case "View":
            return try View(from:dict as! Decoder)
        default:
            throw GenericError("No available mapping for type: \(type)")
        }
    }
}

public extension Dictionary where Key == String, Value:Any {
    func expect<T>(_ key:Key) throws -> T {
        guard let value = self[key] else {
            throw GenericError("Serialization Error: Expected key '\(key)' in dict.")
        }
        guard let result = value as? T else {
            throw GenericError("Serialization Error: Expected value in '\(key)' to be type \(type(of: T.self)).")
        }
        return result
    }
    
    func expectDictionary(_ key:Key) throws -> [String:Any] {
        return try self.expect(key)
    }
    
    func expectRaw(_ key:Key) throws -> [String:Any] {
        return try self.expect(key)
    }
    
    //What do we do if the type is a protocol
    func expectObject<T>(_ key:Key, _ cache:InstanceCache, _ expectedType:DictionarySerialization.Type) throws -> T where T: DictionarySerialization {
        let data = try expectDictionary(key)
        if let id = data["_id"] {
            
        }
        throw GenericError("ignore")
        //return try T.init(data)
    }
    
    func expectDate(_ key:Key) throws -> Date {
        let strValue:String = try expect(key)
        guard let date = strValue.toDate() else {
            throw GenericError("Serialization Error: Can't map \(strValue) to date.")
        }
        return date
    }
    
    func mapDate(_ key:Key) throws -> Date? {
        guard let strValue:String = map(key) else { return nil }
        guard let date = strValue.toDate() else {
            throw GenericError("Serialization Error: Can't map \(strValue) to date.")
        }
        return date
    }
    
    func map<T>(_ key:Key) -> T? {
        return self[key] as? T
    }
    
    //Common
    func id() throws -> String {
        return try expect("id")
    }
    
    func expectCreatedAt() throws -> Date {
        return try expectDate("created_at")
    }
    
    func expectUpdatedAt() throws -> Date {
        return try expectDate("updated_at")
    }
    
    func createdAt() throws -> Date? {
        return try mapDate("created_at")
    }
    
    func updatedAt() throws -> Date? {
        return try mapDate("updated_at")
    }
}

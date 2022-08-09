//
//  Codable+Features.swift
//  TestGame
//
//  Created by Isaac Paul on 8/1/22.
//

import Foundation

public protocol ExpressibleByString {
    init(_ value:String) throws
}

public protocol ExpressibleByInteger {
    init(_ value:Int64) throws
}

public protocol ExpressibleByFloat { //TODO: Float or double?
    init(_ value:Float) throws
}

public extension UnkeyedEncodingContainer {
    mutating func encodeElementInArray<T>(_ value:T) throws where T : Encodable, T : AnyObject {
        let encoder = self.superEncoder()
        try encoder.encode(value)
    }
}

public extension UnkeyedDecodingContainer {
    mutating func decodeElementInArray<T>(_ type: T.Type) throws -> T where T : Decodable, T : AnyObject {
        let decoder = try self.superDecoder()
        return try decoder.decode(type)
    }
    
    // Can't override :(
    /*
    mutating func decode<T>(_ type: T.Type) throws -> T where T : Decodable, T : AnyObject {
        return try decodeElementInArray(type)
    }*/
}

public extension KeyedEncodingContainer where Key : CodingKey {
    mutating func encodeDynamicItem<T>(_ value: T, forKey key: KeyedDecodingContainer<Key>.Key) throws where T : Encodable, T : AnyObject {
        let encoder = self.superEncoder(forKey: key)
        try encoder.encode(value)
    }
    
    mutating func encodeArray<T>(_ value: [T], forKey key: KeyedDecodingContainer<Key>.Key) throws where T : Encodable, T : AnyObject {
        var container = self.nestedUnkeyedContainer(forKey: key)
        for eachItem in value {
            try container.encodeElementInArray(eachItem)
        }
    }
}

public extension KeyedDecodingContainer where Key : CodingKey {
    
    func decodeArray<T>(_ type: T.Type, forKey key: KeyedDecodingContainer<Key>.Key) throws -> [T] where T : Decodable, T : AnyObject {
        var container = try self.nestedUnkeyedContainer(forKey: key)
        var elements:[T] = []
        while (container.isAtEnd == false) {
            let idk = try container.decodeElementInArray(type)
            elements.append(idk)
        }
        return elements
    }
    
    //! Big difference: Does not throw type mismatch.
    func decodeDynamicItemIfPresent<T>(_ type: T.Type, forKey key: KeyedDecodingContainer<Key>.Key) throws -> T? where T : Decodable, T : AnyObject {
        let decoder = try self.superDecoder(forKey: key)
        do {
            return try decoder.decode(type)
        } catch let error as DecodingError {
            //Dont hide typemismatch
            if case .typeMismatch(_, _) = error {
                throw error
            }
        }
        
        return nil
    }
    
    func decodeDynamicItem<T>(_ type: T.Type, forKey key: KeyedDecodingContainer<Key>.Key) throws -> T where T : Decodable, T : AnyObject {
        let decoder = try self.superDecoder(forKey: key)
        return try decoder.decode(type)
    }
    
    // Hack to avoid having to write serialization code.
    /* Overriding Works but it's against the intended language design */
    /* Doesn't work for arrays as root obj (?) because its not part of this module or because the calls are inlined. */
    func decode<T>(_ type: [T].Type, forKey key: KeyedDecodingContainer<K>.Key) throws -> [T] where T : Decodable, T : AnyObject {
        return try decodeArray(type.Element, forKey: key)
    }
    
    func decode<T>(_ type: T.Type, forKey key: KeyedDecodingContainer<K>.Key) throws -> T where T : Decodable, T : AnyObject {
        return try decodeDynamicItem(type, forKey: key)
    }
}


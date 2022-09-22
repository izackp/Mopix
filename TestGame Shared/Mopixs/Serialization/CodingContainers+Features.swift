//
//  Codable+Features.swift
//  TestGame
//
//  Created by Isaac Paul on 8/1/22.
//

import Foundation

extension DecodingError.Context {
    func prettyPath(separatedBy separator: String = ".") -> String {
        codingPath.map { $0.stringValue }.joined(separator: ".")
    }
}

public extension UnkeyedEncodingContainer {
    mutating func encodeElementInArray<T>(_ value:T) throws where T : Encodable {
        let encoder = self.superEncoder()
        try encoder.encode(value)
    }
    
    mutating func encodeElementInArray<T>(_ value:T) throws {
        let encoder = self.superEncoder()
        try encoder.encode(value)
    }
}

public extension UnkeyedDecodingContainer {
    mutating func decodeElementInArray<T>(_ type: T.Type) throws -> T where T : Decodable {
        let decoder = try self.superDecoder()
        return try decoder.decode(type)
    }
    
    mutating func decodeElementInArray<T>(_ type: T.Type) throws -> T {
        let decoder = try self.superDecoder()
        return try decoder.decode(type)
    }
}

public extension KeyedEncodingContainer where Key : CodingKey {
    mutating func encodeDynamicItem<T>(_ value: T, forKey key: KeyedDecodingContainer<Key>.Key) throws where T : Encodable {
        let encoder = self.superEncoder(forKey: key)
        try encoder.encode(value)
    }
    
    mutating func encodeArray<T>(_ value: [T], forKey key: KeyedDecodingContainer<Key>.Key) throws where T : Encodable {
        var container = self.nestedUnkeyedContainer(forKey: key)
        for eachItem in value {
            try container.encodeElementInArray(eachItem)
        }
    }
    
    mutating func encodeArray<T>(_ value: [T], forKey key: KeyedDecodingContainer<Key>.Key) throws {
        var container = self.nestedUnkeyedContainer(forKey: key)
        for eachItem in value {
            try container.encodeElementInArray(eachItem)
        }
    }
    mutating func encodeArray<T>(_ value: Arr<T>, forKey key: KeyedDecodingContainer<Key>.Key) throws {
        var container = self.nestedUnkeyedContainer(forKey: key)
        for eachItem in value {
            try container.encodeElementInArray(eachItem)
        }
    }
    /*
    mutating func encode(_ value: Float, forKey key: KeyedDecodingContainer<Key>.Key) throws {
        let encoder = self.superEncoder(forKey: key)
        let dbl = Double(value)
        let dec = Decimal.init(dbl)
        try dec.encode(to: encoder)
    }*/
}

public extension KeyedDecodingContainer where Key : CodingKey {
    
    func decodeArray<T>(_ type: T.Type, forKey key: KeyedDecodingContainer<Key>.Key) throws -> [T] {
        guard var container = try? self.nestedUnkeyedContainer(forKey: key) else { return [] }
        var elements:[T] = []
        while (container.isAtEnd == false) {
            let idk = try container.decodeElementInArray(type)
            elements.append(idk)
        }
        return elements
    }
    
    func decodeArray<T>(_ type: T.Type, forKey key: KeyedDecodingContainer<Key>.Key) throws -> [T] where T : Decodable {
        //TODO: Should this be in an ifPresent func?
        guard var container = try? self.nestedUnkeyedContainer(forKey: key) else { return [] }
        var elements:[T] = []
        while (container.isAtEnd == false) {
            let idk = try container.decodeElementInArray(type)
            elements.append(idk)
        }
        return elements
    }
    
    func decodeContiguousArray<T>(_ type: T.Type, forKey key: KeyedDecodingContainer<Key>.Key) throws -> Arr<T> {
        return Arr<T>(try decodeArray(type, forKey: key))
    }
    
    func decodeContiguousArray<T>(_ type: T.Type, forKey key: KeyedDecodingContainer<Key>.Key) throws -> Arr<T> where T : Decodable {
        return Arr<T>(try decodeArray(type, forKey: key))
    }
    
    func decodeDynamicItemIfPresent<T>(_ type: T.Type, forKey key: KeyedDecodingContainer<Key>.Key) throws -> T? where T : Decodable {
        if let decoder = try? self.superDecoder(forKey: key) {
            do {
                return try decoder.decode(type)
            } catch let DecodingError.valueNotFound(errKey, context) {
                print("Key: \(String(describing: errKey)) - Key: \(String(describing: key)) ")
                print("Value not found. -> \(context.prettyPath()) <- \(context.debugDescription)") //TODO: We could get the last path key and compare to key
                return nil
            }
        } else {
            return nil
        }
    }
    
    func decodeDynamicItem<T>(_ type: T.Type, forKey key: KeyedDecodingContainer<Key>.Key) throws -> T where T : Decodable {
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


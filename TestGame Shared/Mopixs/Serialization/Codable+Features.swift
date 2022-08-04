//
//  Codable+Features.swift
//  TestGame
//
//  Created by Isaac Paul on 8/1/22.
//

import Foundation


//count:Int
//color:Color (int, string, or obj)
//color:Color (int, string, or obj) ; As Final - No subclasses
//crazines:SubColor (obj+type)

/*
 what would be difficult to support:
 Color -> Obj
 SubTypeColor -> Obj, String
 {
    myColor:Color = "background"
 }
 in this case we would need to search all children of a type to see if any support ExpressableByString. Also, what do we do if multiple types use that protocol.
 */

public protocol ExpressibleByString {
    init(_ value:String) throws
}

public protocol ExpressibleByInteger {
    init(_ value:Int64) throws
}

//TODO: What type do we get from deserializing
public protocol ExpressibleByFloat {
    init(_ value:Float) throws
}

private enum InternalCodingKeys: String, CodingKey {
    case _type
    case _id
}

struct SerializedTypeInfo : Error {
    let type:String?
    let id:String?
}

struct Trickery : Codable {
    let _type:String?
    let _id:String?
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decodeIfPresent(String.self, forKey: ._type)
        let id = try container.decodeIfPresent(String.self, forKey: ._id)
        throw SerializedTypeInfo(type: type, id: id)
    }
}

struct Resolver<T> : Decodable where T : Decodable  {
    let type:String?
    let result:T
    
    init(from decoder: Decoder) throws {
        let userInfo = decoder.userInfo
        let cache = userInfo[CodingUserInfoKey(rawValue: "instanceCache")!] as? InstanceCache
        guard let block = KeyedDecodingContainerUtil.customDecoder else { throw GenericError("NOPE") }
        let container = try decoder.container(keyedBy: InternalCodingKeys.self)
        type = try container.decodeIfPresent(String.self, forKey: ._type)
        if let cache = cache {
            if let id = try? container.decodeIfPresent(Int64.self, forKey: InternalCodingKeys._id) {
                if let cachedInstance:AnyObject = try cache.instanceForId(id) {
                    result = cachedInstance as! T
                } else {
                    if let type = type {
                        result = try block(type, decoder) as! T
                    } else {
                        result = try T.init(from: decoder)
                    }
                    let _ = try cache.saveInstance(result as AnyObject, id: id)
                }
            } else if let id = try? container.decodeIfPresent(String.self, forKey: InternalCodingKeys._id) {
                if let cachedInstance:AnyObject = try cache.instanceForId(id) {
                    result = cachedInstance as! T
                } else {
                    if let type = type {
                        result = try block(type, decoder) as! T
                    } else {
                        result = try T.init(from: decoder)
                    }
                    let _ = try cache.saveInstance(result as AnyObject, id: id)
                }
            } else {
                if let type = type {
                    result = try block(type, decoder) as! T
                } else {
                    result = try T.init(from: decoder)
                }
            }
        } else {
            if let type = type {
                result = try block(type, decoder) as! T
            } else {
                result = try T.init(from: decoder)
            }
        }
        
    }
}

public extension UnkeyedDecodingContainer {
    mutating func decodeElementInArray<T>(_ type: T.Type) throws -> T where T : Decodable {
        if let subObj = try? self.decode(Resolver<T>.self) {
            return subObj.result
        }
        
        if
            let exType = T.self as? ExpressibleByString.Type,
            let value = try? self.decodeIfPresent(String.self)
        {
            return try exType.init(value) as! T
        }
        
        if
            let exType = T.self as? ExpressibleByInteger.Type,
            let value = try? self.decodeIfPresent(Int64.self)
        {
            return try exType.init(value) as! T
        }
        
        if
            let exType = T.self as? ExpressibleByFloat.Type,
            let value = try? self.decodeIfPresent(Float.self)
        {
            return try exType.init(value) as! T
        }
        throw GenericError("Cannot convert item at index \(self.currentIndex) to type \(T.self)")
    }
}

public typealias DecodableClass = Decodable & AnyObject

public class KeyedDecodingContainerUtil {
    static public var customDecoder:((_ type:String, _ decoder:Decoder) throws -> Any)? = nil
}

public extension KeyedDecodingContainer where Key : CodingKey {
    
    func decodeType<T>(_ type:String, decoder:Decoder) throws -> T {
        let any:Any
        //let decoder = try self.superDecoder()
        /*
        if (type == "View") {
            any = try View.init(from: decoder)
        } else {
            if let block = KeyedDecodingContainerUtil.customDecoder {
                any = try block(type, decoder)
            } else {
                throw GenericError("Unkown type: \(type)")
            }
        }*/
        if let block = KeyedDecodingContainerUtil.customDecoder {
            any = try block(type, decoder)
        } else {
            throw GenericError("Unkown type: \(type)")
        }
        if let result = any as? T {
            return result
        }
        
        throw GenericError("Serialization Error: Expected value in abc to be type \(String(describing: T.self)).")
    }
    
    func decodeInstance<T>(_ type: T.Type, forKey key: KeyedDecodingContainer<Key>.Key) throws -> [T] where T : Decodable {
        throw GenericError("ignore")
    }
    
    func decodeArray<T>(_ type: T.Type, forKey key: KeyedDecodingContainer<Key>.Key) throws -> [T] where T : Decodable {
        var container = try self.nestedUnkeyedContainer(forKey: key)
        var elements:[T] = []
        while (container.isAtEnd == false) {
            let idk = try container.decodeElementInArray(type)
            elements.append(idk)
        }
        return elements
    }
    
    fileprivate func decodeSubObj<T>(_ type: T.Type, forKey key: KeyedDecodingContainer<Key>.Key, subObj:KeyedDecodingContainer<InternalCodingKeys>, decoder:Decoder) throws -> T where T : Decodable {
        if let type = try? subObj.decodeIfPresent(String.self, forKey: ._type) {
            return try subObj.decodeType(type, decoder: decoder)
        } else {
            return try decode(type, forKey: key)
        }
    }
    
    //What if T is optional? let idk:SubClass?
    fileprivate func resolveInstanceThroughCache<T>(_ type: T.Type, forKey key: KeyedDecodingContainer<Key>.Key, subObj:KeyedDecodingContainer<InternalCodingKeys>, cache:InstanceCache, decoder:Decoder) throws -> T where T : DecodableClass {
        //TODO: What type
        if let id = try? subObj.decodeIfPresent(Int64.self, forKey: InternalCodingKeys._id) {
            if let cachedInstance:T = try cache.instanceForId(id) {
                return cachedInstance
            }
            let new = try decodeSubObj(type, forKey: key, subObj: subObj, decoder: decoder)
            let _ = try cache.saveInstance(new as AnyObject, id: id)
            return new
        } else if let id = try? subObj.decodeIfPresent(String.self, forKey: InternalCodingKeys._id) {
            if let cachedInstance:T = try cache.instanceForId(id) {
                return cachedInstance
            }
            let new = try decodeSubObj(type, forKey: key, subObj: subObj, decoder: decoder)
            let _ = try cache.saveInstance(new as AnyObject, id: id)
            return new
        }
        return try decodeSubObj(type, forKey: key, subObj: subObj, decoder: decoder)
    }

    fileprivate func resolveInstance<T>(_ type: T.Type, forKey key: KeyedDecodingContainer<Key>.Key, subObj:KeyedDecodingContainer<InternalCodingKeys>, decoder:Decoder) throws -> T where T : DecodableClass {
        if let cache = try? getInstanceCache() {
            return try resolveInstanceThroughCache(type, forKey: key, subObj: subObj, cache: cache, decoder: decoder)
        }
        return try decodeSubObj(type, forKey: key, subObj: subObj, decoder: decoder)
    }
    
    func getInstanceCache() throws -> InstanceCache? {
        
        let superD = try self.superDecoder()
        let userInfo = superD.userInfo
        let cache = userInfo[CodingUserInfoKey(rawValue: "instanceCache")!] as? InstanceCache
        return cache
    }
    
    func decodeDynamicItemIfPresent<T>(_ type: T.Type, forKey key: KeyedDecodingContainer<Key>.Key) throws -> T? where T : DecodableClass {
        
        if let subObj:KeyedDecodingContainer<InternalCodingKeys> = try? self.nestedContainer(keyedBy: InternalCodingKeys.self, forKey: key) {
            let test = try superDecoder(forKey: key)
            return try resolveInstance(type, forKey: key, subObj: subObj, decoder: test)
        }
        //There could be a collision? lets say its expressible, but stored as id
        //We can forbid it...
        //Lets say the id is 1 but its can be expressed as 1. If there is no instance even though there should have been.. it will still successfully decode
        //We can avoid collions by doing
        // "key": { "_id": 1 }  instead of
        // "key": 1
        if
            let exType = T.self as? ExpressibleByString.Type,
            let value = try? self.decodeIfPresent(String.self, forKey: key)
        {
            return try exType.init(value) as! T
        }
        
        if
            let exType = T.self as? ExpressibleByInteger.Type,
            let value = try? self.decodeIfPresent(Int64.self, forKey: key)
        {
            return try exType.init(value) as! T
        }
        
        if
            let exType = T.self as? ExpressibleByFloat.Type,
            let value = try? self.decodeIfPresent(Float.self, forKey: key)
        {
            return try exType.init(value) as! T
        }
        return nil
    }
    
    func decodeDynamicItem<T>(_ type: T.Type, forKey key: KeyedDecodingContainer<Key>.Key) throws -> T where T : DecodableClass {
        if let result = try decodeDynamicItemIfPresent(type, forKey: key) {
            return result
        }
        throw GenericError("Cannot convert item at key \(key.stringValue) to type \(T.self)")
    }
}

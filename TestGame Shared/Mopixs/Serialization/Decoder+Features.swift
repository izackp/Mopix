//
//  Decoder+Features.swift
//  TestGame
//
//  Created by Isaac Paul on 8/8/22.
//

import Foundation

public class CodableTypeResolver {
    static public var resolve:((_ type:String) throws -> Decodable.Type)? = nil
}

private enum InternalCodingKeys: String, CodingKey {
    case _type
    case _id
}

extension Decoder {
    
    func decode<T>(_ type: T.Type) throws -> T {
        if let container = try? self.container(keyedBy: InternalCodingKeys.self) {
            let cache = self.getInstanceCache()
            //TODO: Is this heap allocated? kinda gross
            let factory:(() throws -> T) = {
                do {
                    let strType = try container.decode(String.self, forKey: ._type)
                    return try self.decodeExpectedType(strType)
                } catch {
                    print("Cant decode type: \(error) \(error.localizedDescription)")
                    throw error
                }
            }
            if let result = try cache?.instanceForContainer(container, factory: factory) {
                return result
            }
            
            return try factory()
        }

        if let result = try decodeIfExpressible(type) {
            return result
        }
        throw GenericError("Unable to decode type: \(type)  without embedded _type info")
    }
    
    func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
        
        if let container = try? self.container(keyedBy: InternalCodingKeys.self) {
            let cache = self.getInstanceCache()
            let factory = { try self.decodeTypedObj(type, subObj: container) }
            if let result = try cache?.instanceForContainer(container, factory: factory) {
                return result
            }
            
            return try factory()
        }

        if let result = try decodeIfExpressible(type) {
            return result
        }

        return try T.init(from: self)
    }
    
    func decodeIfExpressible<T>(_ type: T.Type) throws -> T? {
        if
            let exType = T.self as? ExpressibleByString.Type,
            let value = try? String.init(from: self)
        {
            return Optional(try exType.init(value) as! T)
        }
        
        if
            let exType = T.self as? ExpressibleByInteger.Type,
            let value = try? Int64.init(from: self)
        {
            return Optional(try exType.init(value) as! T)
        }
        
        if
            let exType = T.self as? ExpressibleByFloat.Type,
            let value = try? Float.init(from: self)
        {
            return Optional(try exType.init(value) as! T)
        }
        return nil
    }

    func getInstanceCache() -> InstanceCache? {
        let userInfo = self.userInfo
        let cache = userInfo[CodingUserInfoKey(rawValue: "instanceCache")!] as? InstanceCache
        return cache
    }
    
    fileprivate func decodeTypedObj<T>(_ type: T.Type, subObj:KeyedDecodingContainer<InternalCodingKeys>) throws -> T {
        if let type = try? subObj.decodeIfPresent(String.self, forKey: ._type) {
            return try self.decodeExpectedType(type)
        }
        if let decodable = T.self as? Decodable.Type {
            return try decodable.init(from: self) as! T
        }
        throw GenericError("Unable to instantiate type: \(type)")
    }
    
    func decodeExpectedType<T>(_ type:String) throws -> T {
        let any:Decodable
        if let block = CodableTypeResolver.resolve {
            let type = try block(type)
            any = try type.init(from: self)
        } else {
            throw GenericError("No type resolver function set.")
        }
        if let result = any as? T {
            return result
        }
        
        throw GenericError("Serialization Error: Expected value in abc to be type \(String(describing: T.self)).")
    }
}

extension InstanceCache {
    fileprivate func instanceForContainer<T>(_ container:KeyedDecodingContainer<InternalCodingKeys>, factory:() throws -> T) throws -> T {
        if let id = try? container.decodeIfPresent(Int64.self, forKey: InternalCodingKeys._id) {
            return try self.instanceForId(id, factory: factory)
        } else if let id = try? container.decodeIfPresent(String.self, forKey: InternalCodingKeys._id) {
            return try self.instanceForId(id, factory: factory)
        }
        return try factory()
    }
}

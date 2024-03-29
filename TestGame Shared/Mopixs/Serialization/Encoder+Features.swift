//
//  Encoder+Features.swift
//  TestGame
//
//  Created by Isaac Paul on 8/8/22.
//

import Foundation

private enum InternalCodingKeys: String, CodingKey {
    case _type
    case _id
}

extension Encoder {
    
    func encode<T>(_ value: T) throws where T : Encodable {
        try encodeMetaData(value)
        try value.encode(to: self)
    }
    
    func encode<T>(_ value: T) throws {
        try encodeMetaData(value)
        if let encodable = value as? any Encodable {
            try encodable.encode(to: self)
        } else {
            throw GenericError("This type \(type(of: value)) is not encodable.")
        }
    }
    
    func encodeMetaData<T>(_ value: T) throws {
        var container = self.container(keyedBy: InternalCodingKeys.self)
        let thisType = type(of: value)
        let mirror = Mirror(reflecting: value)
        //print("Encoding: \(thisType) with T: \(T.self) - reality: \(mirror)")
        if ((T.self is Encodable == false) || mirror.subjectType != thisType) {
            let className = String(describing: mirror.subjectType)
            try container.encode(className, forKey: ._type)
        }
        if
            mirror.displayStyle == .class,
            let cache = self.getInstanceCache() {
            
            let obj = value as AnyObject
            let id = ObjectIdentifier(obj)//TODO: We need an interface to support for custom ids
            if let index = cache.indexForId(id) {
                try container.encode(index, forKey: ._id)
                return
            }
            let index = cache.saveInstance(obj)
            try container.encode(index, forKey: ._id)
            return
        }
    }
    
    func getInstanceCache() -> InstanceCache? {
        let userInfo = self.userInfo
        let cache = userInfo[CodingUserInfoKey(rawValue: "instanceCache")!] as? InstanceCache
        return cache
    }
}


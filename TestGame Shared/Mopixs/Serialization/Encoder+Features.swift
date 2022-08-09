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
    
    func encode<T>(_ value: T) throws where T : Encodable, T : AnyObject {
        
        var container = self.container(keyedBy: InternalCodingKeys.self)
        let thisType = type(of: value)
        if (thisType != T.self) {
            let className = String(describing: thisType)
            try container.encode(className, forKey: ._type)
        }
        if let cache = self.getInstanceCache() {
            let id = ObjectIdentifier(value)//TODO: We need an interface to support for custom ids
            if let index = cache.indexForId(id) {
                try container.encode(index, forKey: ._id)
                return
            }
            let index = cache.saveInstance(value)
            try container.encode(index, forKey: ._id)
        }
        try value.encode(to: self)
    }

    func getInstanceCache() -> InstanceCache? {
        let userInfo = self.userInfo
        let cache = userInfo[CodingUserInfoKey(rawValue: "instanceCache")!] as? InstanceCache
        return cache
    }
}


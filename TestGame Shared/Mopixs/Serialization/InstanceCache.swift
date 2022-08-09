//
//  InstanceCache.swift
//  TestGame
//
//  Created by Isaac Paul on 8/1/22.
//

import Foundation

//TODO: Possible collisions based on type
/*
 Originally we were going to force all objects to use direct objects.
 However, it would not be possible... hmm maybe we just should
 color: "Blue"
 myOtherObj: { "id": "Blue" }
 
 with strings we can type encode but not ints
 
 */

public class InstanceCache {
    
    var _cache:[AnyObject] = []
    var _strIndex:[String:Int] = [:]
    var _intIndex:[Int64:Int] = [:] //Int64???
    var _objIdIndex:[ObjectIdentifier:Int] = [:]
    
    func instanceForId<T>(_ id:String) throws -> Optional<T> where T: AnyObject {
        guard let index = _strIndex[id] else {
            //throw GenericError("Instance cache has no instance for str id: \(id).")
            return nil
        }
        return try instanceForIndex(index)
    }
    
    func indexForId(_ objId:ObjectIdentifier) -> Int? {
        if let existingIndex = _objIdIndex[objId] {
            return existingIndex// _cache[existingIndex] as? T
        }
        return nil
    }
    
    func instanceForId<T>(_ id:String, factory:() throws -> T) throws -> T where T: AnyObject {
        guard let index = _strIndex[id] else {
            let new = try factory()
            let index = saveInstance(new)
            _strIndex[id] = index
            return new
        }
        return try instanceForIndex(index)
    }
    
    func instanceForId<T>(_ id:Int64, factory:() throws -> T) throws -> T where T: AnyObject {
        guard let index = _intIndex[id] else {
            let new = try factory()
            let index = saveInstance(new)
            _intIndex[id] = index
            return new
        }
        return try instanceForIndex(index)
    }
    
    func instanceForId<T>(_ id:Int64) throws -> Optional<T> where T: AnyObject {
        guard let index = _intIndex[id] else {
            //throw GenericError("Instance cache has no instance for int id: \(id).")
            return nil
        }
        return try instanceForIndex(index)
    }
    
    func instanceForIndex<T>(_ index:Int) throws -> T where T: AnyObject {
        let instance = _cache[index]
        if let conv = instance as? T {
            return conv
        }
        throw GenericError("Existing instance with type \(type(of: instance)) does not conform to expected type: \(T.self)")
    }
    
    func saveInstance(_ instance:AnyObject) -> Int {
        let objId = ObjectIdentifier(instance)
        if let existingIndex = _objIdIndex[objId] {
            return existingIndex
        }
        
        _cache.append(instance)
        let index = _cache.count - 1
        _objIdIndex[objId] = index
        return index
    }
    
    func saveInstance(_ instance:AnyObject, id:String) throws -> Int {
        if let index = _strIndex[id] {
            let existing = _cache[index]
            if (existing !== instance) {
                throw GenericError("A different instance already exists for id: \(id)")
            }
            return index
        }
        
        let index = saveInstance(instance)
        _strIndex[id] = index
        return index
    }
    
    func saveInstance(_ instance:AnyObject, id:Int64) throws -> Int {
        if let index = _intIndex[id] {
            let existing = _cache[index]
            if (existing !== instance) {
                throw GenericError("A different instance already exists for id: \(id)")
            }
            return index
        }
        
        let index = saveInstance(instance)
        _intIndex[id] = index
        return index
    }
}

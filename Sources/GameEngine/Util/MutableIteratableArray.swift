//
//  MutableIteratableArray.swift
//  
//
//  Created by Isaac Paul on 4/27/23.
//

import Foundation

//TODO: Refactor
class MutableIteratableArray<T, M> {
    var data:Array<T> = Array()
    var metaData:Array<M> = Array()
    
    var toAdd:Array<T> = Array()
    var toRemove:Array<T> = Array()
    var toAddMetaData:Array<M> = Array()
    
    func append(_ item:T, _ meta:M) {
        toAdd.append(item)
        toAddMetaData.append(meta)
    }
    
    func remove(_ item:T) {
        toRemove.append(item)
    }
}
/*
extension MutableIteratableArray where T : Equatable & AnyObject {
    func applyChanges() {
        data.append(contentsOf: toAdd)
        metaData.append(contentsOf: toAddMetaData)
        toAdd.removeAll(keepingCapacity: true)
        toAddMetaData.removeAll(keepingCapacity: true)
        for eachItem in toRemove {
            guard let i = data.firstIndex(where: {$0 === eachItem}) else { continue }
            data.remove(at: i)
            metaData.remove(at: i)
        }
        toRemove.removeAll(keepingCapacity: true)
    }
}*/


extension MutableIteratableArray  {
    func applyChanges() {
        data.append(contentsOf: toAdd)
        metaData.append(contentsOf: toAddMetaData)
        toAdd.removeAll(keepingCapacity: true)
        toAddMetaData.removeAll(keepingCapacity: true)
        for eachItem in toRemove {
            let asAny:Any = eachItem
            if (type(of: asAny) is AnyClass) {
               let classCheck = eachItem as AnyObject
                guard let i = data.firstIndex(where: {
                    let innerAsAny:AnyObject = $0 as AnyObject
                    return innerAsAny === classCheck
                }) else { continue }
                data.remove(at: i)
                metaData.remove(at: i)
            } else {
                assert(true, "T must be an obj")
            }
        }
        toRemove.removeAll(keepingCapacity: true)
    }
}
/*
extension MutableIteratableArray where T : Equatable  {
    func applyChanges() {
        data.append(contentsOf: toAdd)
        metaData.append(contentsOf: toAddMetaData)
        toAdd.removeAll(keepingCapacity: true)
        toAddMetaData.removeAll(keepingCapacity: true)
        for eachItem in toRemove {
            guard let i = data.firstIndex(where: {$0 == eachItem}) else { continue }
            data.remove(at: i)
            metaData.remove(at: i)
        }
        toRemove.removeAll(keepingCapacity: true)
    }
}*/

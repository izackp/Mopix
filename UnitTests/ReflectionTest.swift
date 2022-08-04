//
//  ReflectionTest.swift
//  TestGame
//
//  Created by Isaac Paul on 7/15/22.
//

import Foundation
import Runtime
import XCTest

//The goal is to support cross platform and android/windows is not abi stable.
//Hence, reflection is not a great option.

class ReflectionTest: XCTestCase {

    func testSerialization() {
        //let sample1:ContiguousArray<LEPosX> = [LEPosX(value: 1)]
        //let sample2 = sample1 as ContiguousArray<Any>
        var test = TextView(text: "Hello World")
        let idk:[LayoutElement] = [LEPosX(value: 0), LEPosY(value: 1)]
        //let hmm = Arr<LayoutElement>.init(idk)
        test.listLayouts = idk
        let dic = try! serialize(test)
        let jsonData = try! JSONSerialization.data(withJSONObject: dic, options: [.prettyPrinted])
        let str = String.init(data: jsonData, encoding: .utf8)!
        print(str)
        let another = try? deserialize(dic)
    }

}



public func serialize(_ item:Any) throws -> [String: Any?] {
    var dict:[String:Any?] = [:]
    print("Serializing: \(String(describing: item))")
    let info = try typeInfo(of: type(of: item))
    for eachProperty in info.properties {
        print("Serializing Prop: \(eachProperty.name)")
        if (eachProperty.name == "_value") {
            print("hi")
        }
        let value = try eachProperty.get(from: item)
        dict[eachProperty.name] = try serializeItem(value)
    }
    dict["_type"] = info.mangledName
    return dict
}

public func serializeItem(_ source:Any?) throws -> Any? {
    if (source == nil) {
        return nil
    }
    guard let nnSource = source else {
        return nil
    }
    
    if let test = source as? ContiguousArray<Any?> {
        print("\(test.count)")
    }
    if let test = source as? ContiguousArray<Any> {
        print("\(test.count)")
    }
    if let test = source as? Array<Any> {
        print("\(test.count)")
    }
    if let test = source as? Array<Any?> {
        print("\(test.count)")
    }

    switch nnSource {
    case let anyItem as Array<Any>:
        return try anyItem.map({ try serializeItem($0) })
    case let anyItem as ContiguousArray<Any>:
        return try anyItem.map({ try serializeItem($0) })
    case let anyItem as String:
            return anyItem
    case let anyItem as Array<AnyObject>:
        return try anyItem.map({ try serializeItem($0) })
    case let anyItem as Int8:
        return anyItem
    case let anyItem as Int16:
        return anyItem
    case let anyItem as Int32:
        return anyItem
    case let anyItem as Int64:
        return anyItem
    case let anyItem as UInt8:
        return anyItem
    case let anyItem as UInt16:
        return anyItem
    case let anyItem as UInt32:
        return anyItem
    case let anyItem as UInt64:
        return anyItem
    case let anyItem as Int:
        return anyItem
    case let anyItem as UInt:
        return anyItem
    case let anyItem as Bool:
        return anyItem
    case let anyItem as Float:
        return anyItem
    case let anyItem as Double:
        return anyItem
    case let anyItem as Date:
        return formatter.string(from: anyItem)
    default:
        return try serialize(nnSource)
    }
}

public func deserialize(_ dict:[String:Any?]) throws -> Any {
    let mangledName = dict["_type"]
    
    var item = try createInstance(of: TextView.self)
    let info = try typeInfo(of: type(of: item))
    
    for eachProperty in info.properties {
        guard let dictValue = dict[eachProperty.name] else { continue }
        let type = eachProperty.type
        if let finalValue = try deserializeItem(dictValue, type) {
            try eachProperty.set(value: finalValue, on: &item)
        }
    }
    return item
}

public func deserializeItem(_ anyItem:Any?, _ target:Any.Type) throws -> Any? {
    
    guard let anyItem = anyItem else {
        return nil
    }
    
    switch anyItem {
    case let anyItem as Array<Any>:
        return try anyItem.map({ try deserializeItem($0, target) })
    case let anyItem as String:
        if (target == Date.self) {
            return formatter.date(from: anyItem)!
        }
            return anyItem
    case let anyItem as NSNumber:
        return toTargetNumber(anyItem, target)
    case let anyItem as Int8:
        return anyItem
    case let anyItem as Int16:
        return anyItem
    case let anyItem as Int32:
        return anyItem
    case let anyItem as Int64:
        return anyItem
    case let anyItem as UInt8:
        return anyItem
    case let anyItem as UInt16:
        return anyItem
    case let anyItem as UInt32:
        return anyItem
    case let anyItem as UInt64:
        return anyItem
    case let anyItem as Int:
        return anyItem
    case let anyItem as UInt:
        return anyItem
    case let anyItem as Bool:
        return anyItem
    case let anyItem as Float:
        return anyItem
    case let anyItem as Double:
        return anyItem
    case let anyItem as [String:Any?]:
        return try deserialize(anyItem)
    default:
        fatalError()
    }
}

func toTargetNumber(_ container:NSNumber, _ target: Any.Type) -> Any {
    if (target == Int8.self) {
        return container.int8Value
    }
    if (target == Int16.self) {
        return container.int16Value
    }
    if (target == Int32.self) {
        return container.int32Value
    }
    if (target == Int64.self) {
        return container.int64Value
    }
    if (target == UInt8.self) {
        return container.uint8Value
    }
    if (target == UInt16.self) {
        return container.uint16Value
    }
    if (target == UInt32.self) {
        return container.uint32Value
    }
    if (target == UInt64.self) {
        return container.uint64Value
    }
    if (target == Float.self) {
        return container.floatValue
    }
    if (target == Double.self) {
        return container.doubleValue
    }
    fatalError()
}

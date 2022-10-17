//
//  TypeMap.swift
//  TestGame
//
//  Created by Isaac Paul on 8/10/22.
//

import Foundation


protocol Initializable {
    init()
}

class TypeMap {
    static let shared = TypeMap()
    static func customDecodeSwitch(_ type:String) throws -> Decodable.Type {
        switch (type) {
        case "LEInset":
            return LEInset.self
        case "LEInsetFixed":
            return LEInsetFixed.self
        case "LEWidth":
            return LEWidth.self
        case "LEHeight":
            return LEHeight.self
        case "LEPosX":
            return LEPosX.self
        case "LEPosY":
            return LEPosY.self
        case "LEMatch":
            return LEMatch.self
        case "LEMatchFixed":
            return LEMatchFixed.self
        case "LEAnchor":
            return LEAnchor.self
        case "LEAnchorFixed":
            return LEAnchorFixed.self
        case "LEWrapWidth":
            return LEWrapWidth.self
        case "LEWrapHeight":
            return LEWrapHeight.self
        case "LEMirrorMargin":
            return LEMirrorMargin.self
        case "LEMirrorMarginHorizontalMax":
            return LEMirrorMarginHorizontalMax.self
        case "View":
            return View.self
        case "TextView":
            return TextView.self
        case "TextField":
            return TextField.self
        case "ImageView":
            return ImageView.self
        case "SmartColor":
            return SmartColor.self
        default:
            throw GenericError("Unknown Type: \(type)")
        }
    }
    /*
    var typeList:[Initializable.Type] = []
    
    func register(_ type:Initializable.Type) {
        
        let idk = type.init()
        print(String(describing: idk))
        let mirror = Mirror(reflecting: idk)
        for case let (label?, value) in mirror.children {
            print (label, value)
        }
        if let _ = typeList.firstIndex(where: {$0 == type}) {
            return
        } else {
            typeList.append(type)
        }
    }*/
}

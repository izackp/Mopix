//
//  TypeMap.swift
//  TestGame
//
//  Created by Isaac Paul on 8/10/22.
//

import Foundation


public protocol Initializable {
    init()
}

public class TypeMap {
    static let shared = TypeMap()
    public static func customDecodeSwitch(_ type:String) throws -> Decodable.Type {
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
            case "LCInset":
                return LCInset.self
            case "LCInsetFixed":
                return LCInsetFixed.self
            case "LCWidth":
                return LCWidth.self
            case "LCHeight":
                return LCHeight.self
            case "LCPosX":
                return LCPosX.self
            case "LCPosY":
                return LCPosY.self
            case "LCMatch":
                return LCMatch.self
            case "LCMatchFixed":
                return LCMatchFixed.self
            case "LCAnchor":
                return LCAnchor.self
            case "LCAnchorFixed":
                return LCAnchorFixed.self
            case "LCWrapWidth":
                return LCWrapWidth.self
            case "LCWrapHeight":
                return LCWrapHeight.self
            case "LCMirrorMargin":
                return LCMirrorMargin.self
            case "LCMirrorMarginHorizontalMax":
                return LCMirrorMarginHorizontalMax.self
        case "View":
            return View.self
        case "TextView":
                if #available(macOS 12, *) {
                    return TextView.self
                } else {
                    throw GenericError("TextView not available in current OS or OS Version")
                }
        case "TextField":
                if #available(macOS 12, *) {
                    return TextField.self
                } else {
                    throw GenericError("TextField not available in current OS or OS Version")
                }
        case "ImageView":
            return ImageView.self
        case "LabeledColor":
            return LabeledColor.self
        //case "UIBuilderView":
        //    return UIBuilderView.self
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

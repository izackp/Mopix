//
//  LabeledColorMap.swift
//  TestGame
//
//  Created by Isaac Paul on 11/23/22.
//

import Foundation

/*
enum StandardColors : String {
    case white
    case green
}

extension StandardColors {
    func rgba() -> UInt32 {
        switch self {
            case .white:
                return 0xFFFFFFFF
            case .green:
                return 0xFF00FF00
        }
    }
    func pair() -> (String, UInt32) {
        return (self.rawValue, self.rgba())
    }
    func labeledColor() -> LabeledColor {
        return LabeledColor(rgba(), name: self.rawValue)
    }
}*/

/*
 Two ways I can do this..
 1 - All labeled colors use a single source of truth which we update.
 2 - We update all colors when the label value changes.  <- we'll do this and see how it works out
 
 TODO: Should be able to add reference to color map in json file
 */
public class LabeledColorMap {
    
    init(_ mapping: [String : UInt32]) {
        self.mapping = mapping
    }
    
    static let standard = LabeledColorMap(
        ["white":0xFFFFFFFF,
         "green":0xFF00FF00,
         "red":0xFFFF0000,
         "blue":0xFF0000FF,
         "idk":0xFF9999FF,
         "pink":0xFFFF3B69,
         "black":0xFF000000,
         "clear":0x00000000]
    )
    
    var mapping:[String:UInt32]
    
    func expectRawColor(_ label:String) throws -> UInt32 {
        guard let result = mapping[label] else {
            throw GenericError("No color mapping for label: \(label)")
        }
        return result
    }
    /*
    var white: LabeledColor {
        get {
            LabeledColor(self.mapping["white"]!, name: "white")
        }
    }*/
    
    /*
    func expect(_ label:String) throws -> SDLColor {
        guard let result = mapping[label] else {
            throw GenericError("No color mapping for label: \(label)")
        }
        return result
    }*/
}
/*
extension LabeledColorMap {
    static let extensionExample = LabeledColorMap(
        ["example":0xFFFFFFFF]
    )
    
    var example: LabeledColor {
        get {
            LabeledColor(self.mapping["example"]!, name: "example")
        }
    }
}*/

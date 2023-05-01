//
//  YogaLayout.swift
//  TestGame
//
//  Created by Isaac Paul on 1/11/23.
//

import Foundation

class YogaLayout {
    //Flex
    //Defines the direction of which text and items are laid out
    public enum Direction : Hashable, Codable {
        case inherit
        case leftToRight
        case rightToLeft
    }

    //Defines the direction of the main-axis
    public enum FlexDirection : Hashable, Codable {
        case column
        case columnReverse
        case row
        case rowReverse
    }

    //Wrapping behaviour when child nodes don't fit into a single line
    public enum FlexWrap : Hashable, Codable {
        case noWrap
        case wrap
        case wrapReverse
    }

    //Alignment
    //Aligns child nodes along the main-axis
    public enum JustifyContent : Hashable, Codable {
        case flexStart
        case center
        case flexEnd
        case spaceBetween
        case spaceAround
        case spaceEvenly
    }

    //Aligns child nodes along the cross-axis
    public enum AlignItems : Hashable, Codable {
        case auto
        case flexStart
        case center
        case flexEnd
        case stretch
        case baseline
        case spaceBetween
        case spaceAround
    }

    //Override align items of parent
    public enum AlignSelf : Hashable, Codable {
        case auto
        case flexStart
        case center
        case flexEnd
        case stretch
        case baseline
        case spaceBetween
        case spaceAround
    }

    //Alignment of lines along the cross-axis when wrapping
    public enum AlignContent : Hashable, Codable {
        case auto
        case flexStart
        case center
        case flexEnd
        case stretch
        case baseline
        case spaceBetween
        case spaceAround
    }

    //Relative position offsets the node from it's calculated position.
    //Absolute position removes the node from the flexbox flow and positions it at the given position.
    public enum PositionType : Hashable, Codable {
        case relative
        case absolute
    }
    
    var direction:Direction = .inherit
    var flexDirection:FlexDirection = .row
    var basis:Int? = nil //?
    var grow:Int = 0
    var shrink:Int = 1
    var flexWrap:FlexWrap = .noWrap
    
    var justifyContent:JustifyContent = .flexStart
    var alignItems:AlignItems = .auto
    var alignSelf:AlignSelf = .auto
    var alignContent:AlignContent = .auto
    
    var size:Size<Int> = Size.zero
    var maxSize:Size<Int>? = nil
    var minSize:Size<Int>? = nil //Not sure if should default to 0
    var aspectRatio:Float? = nil
    
    var padding:Inset<Int> = Inset.zero
    var border:Inset<Int> = Inset.zero
    var margin:Inset<Int> = Inset.zero
    var positionType:PositionType = .relative
    var position:Inset<Int>? = nil //Not sure if should default to 0
    
}

//
//  IDraw.swift
//  
//
//  Created by Isaac Paul on 9/21/23.
//

public protocol IDraw {
    func draw(_ image:DrawCmdImage)
    func createImage(_ block:(_ context:IDraw) throws -> (), size:Size<DValue>) throws -> UInt64
    //func drawText( _ text:Substring, _ font:Font, _ pos:Point<Int16>, _ color:SDLColor, _ alpha:Float = 1, spacing:Int = 0)
    //not used ^
    
    //func drawTextLine( _ text:ArraySlice<RenderableCharacter>, _ pos:Point<Int16>, _ alpha:Float = 1)
    //func drawSquare(_ dest:Rect<Int16>, _ color:SDLColor, _ alpha:Float = 1)
    //func drawSquareEx(_ dest:Rect<Int16>, _ color:SDLColor, _ alpha:Float = 1)
    //func drawAtlas(_ x:Int, _ y:Int, index:Int = 0)
    
    //func fetchFont(_ fontDesc:FontDesc) -> Font
}

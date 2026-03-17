//
//  IDraw.swift
//
//
//  Created by Isaac Paul on 9/21/23.
//

public protocol IDraw {
    func drawCmd(_ cmd: DrawCmd)
    func createImage(_ block: (_ context: IDraw) throws -> (), size: Size<DValue>) throws -> UInt64
}

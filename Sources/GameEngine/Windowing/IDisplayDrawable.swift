//
//  IDisplayDrawable.swift
//

public protocol IDisplayDrawable {
    func draw(_ delta: UInt64, _ renderer: GameEngine.DisplayRenderClient) throws
}

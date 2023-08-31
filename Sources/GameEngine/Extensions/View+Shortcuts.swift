//
//  View+Shortcuts.swift
//  
//
//  Created by Isaac Paul on 4/23/23.
//

public extension View {
    func findWindow() -> LiteWindow? {
        var view:View? = self
        while let viewToCheck = view {
            if let parentWindow = self.window {
                return parentWindow
            }
            view = viewToCheck.superView
        }
        return nil
    }
}

//
//  TestViewController.swift
//  TestGame
//
//  Created by Isaac Paul on 7/3/22.
//

import Foundation

public class TestViewController : ViewController {
    
    public override func loadView() -> View {
        //super.loadView()
        let myView = View()
        myView.listLayouts = [LEAnchor(edge: .Right, percent: 1), LEAnchor(edge: .Bottom, percent: 1)]
        let lblHelloWorld = TextView(text: "Hello World")
        lblHelloWorld.listLayouts = [LEAnchor(edge: .Right, percent: 1), LEAnchor(edge: .Bottom, percent: 1), LEInset(edge: .Right, value: 16), LEInset(edge: .Left, value: 16)]
        myView.children.append(lblHelloWorld)
        return myView
    }
}

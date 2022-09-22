//
//  TestViewController.swift
//  TestGame
//
//  Created by Isaac Paul on 7/3/22.
//

import Foundation

public class TestViewController : ViewController {
    
    static public func build(app:Application) throws -> TestViewController {
        let idk = app.vd //TODO: So do we make application shared?
        guard let vcUrl = idk.urlForFileName("TestViewController.json5") else { throw GenericError("No file") }
        guard let data = try idk.readFile(vcUrl) else { throw GenericError("No Data") }
        let decoder = JSONDecoder()
        decoder.allowsJSON5 = true
        decoder.userInfo[CodingUserInfoKey(rawValue: "instanceCache")!] = InstanceCache()
        let content = try decoder.decode(ResolverInterface<Any>.self, from: data)
        guard let myView = content.result.first as? View else { throw GenericError("Unexpected type")}
        return TestViewController(myView)
    }
    
    override init(_ view: View) {
        super.init(view)
    }
}

public class UIBuilderVC : ViewController {
    
    static public func build() -> UIBuilderVC {
        let myView = View()
        myView.listLayouts = [LEAnchor(edge: .Right, percent: 1), LEAnchor(edge: .Bottom, percent: 1)]
        myView.backgroundColor = SmartColor.white
        let lblHelloWorld = TextView(text: "Hello World2")
        lblHelloWorld.listLayouts = [LEAnchor(edge: .Right, percent: 1), LEAnchor(edge: .Bottom, percent: 1), LEInset(edge: .Right, value: 16), LEInset(edge: .Left, value: 16)]
        myView.children.append(lblHelloWorld)
        return UIBuilderVC(myView)
    }
    
    override init(_ view: View) {
        super.init(view)
        //ViewDidLoad Here instead
    }
    
}

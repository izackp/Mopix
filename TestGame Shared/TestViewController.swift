//
//  TestViewController.swift
//  TestGame
//
//  Created by Isaac Paul on 7/3/22.
//

import Foundation

extension View {
    func findWindow() -> Window? {
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

public class TestViewController : ViewController, PackageChangeListener {
    
    let _source:VDUrl

    static public func build(_ imageManager:SimpleImageManager) throws -> TestViewController {
        let vd = Application.shared().vd //TODO: So do we make application shared?
        guard let vcUrl = vd.searchByName("TestViewController.json5")?.url else { throw GenericError("No file") }
        guard let data = try vd.readFile(vcUrl) else { throw GenericError("No Data") }
        let decoder = JSONDecoder()
        decoder.allowsJSON5 = true
        decoder.userInfo[CodingUserInfoKey(rawValue: "instanceCache")!] = InstanceCache()
        decoder.userInfo[CodingUserInfoKey(rawValue: "imageManager")!] = imageManager
        decoder.userInfo[CodingUserInfoKey(rawValue: "labeledColors")!] = LabeledColorMap.standard
        //context[CodingUserInfoKey(rawValue: "labeledColors")!] as? LabeledColorMa
        let content = try decoder.decode(ResolverInterface<Any>.self, from: data)
        guard let myView = content.result.first as? View else { throw GenericError("Unexpected type")}
        let mountedDir = vd.packages.contains(vcUrl)
        let result = TestViewController(myView, vcUrl)
        try mountedDir?.startWatching(result)
        return result
    }
    
    init(_ view: View, _ source:VDUrl) {
        _source = source
        super.init(view)
    }
    
    deinit {
        let vd = Application.shared().vd
        vd.removeWatcher(self)
    }
    
    public func fileChanges(_ files: [VDItem]) {
        do {
            if let _ = files.first(where: {$0.url == _source}),
               let window = view.findWindow() as? CustomWindow {
                
                let newVC = try TestViewController.build(window.imageManager)
                window.setRootViewController(newVC)
            }
        } catch {
            
        }
    }
}

public class UIBuilderVC : ViewController {
    
    static public func build() -> UIBuilderVC {
        let myView = View()
        myView.listLayouts = [LEAnchor(edge: .Right, percent: 1), LEAnchor(edge: .Bottom, percent: 1)]
        myView.backgroundColor = LabeledColor.white
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

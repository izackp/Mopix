//
//  TestController.swift
//  
//
//  Created by Isaac Paul on 8/2/23.
//

import Foundation
import GameEngine

@available(macOS 12.0, *)
public class TestController : ViewController {
    
    let _source:VDUrl

    static public func build(_ imageManager:SimpleImageManager) throws -> TestController {
        let vd = Application.shared().vd //TODO: So do we make application shared?
        guard let vcUrl = vd.searchByName("ViewBuilder.json5")?.url else { throw GenericError("No file") }
        guard let data = try vd.readFile(vcUrl) else { throw GenericError("No Data") }
        let decoder = JSONDecoder()
        decoder.allowsJSON5 = true
        decoder.userInfo[CodingUserInfoKey(rawValue: "instanceCache")!] = InstanceCache()
        decoder.userInfo[CodingUserInfoKey(rawValue: "imageManager")!] = imageManager
        decoder.userInfo[CodingUserInfoKey(rawValue: "labeledColors")!] = LabeledColorMap.standard
        let content = try decoder.decode(ResolverInterface<Any>.self, from: data)
        guard let myView = content.result.first(where: { (item:Any) in
            guard let view = item as? View else { return false }
            if (view._id == "viewRoot") { return true }
            return false
        }) as? View else { throw GenericError("Unexpected type")}
        let mountedDir = vd.packages.first(where: {$0.path == vcUrl})
        let result = try TestController(myView, vcUrl)
        return result
    }
    
    public var viewLeftHeirachy:View
    public var viewContent:View
    public var viewRightInfo:View
    public var lblFPS:TextView
    public var lblFPS2:TextView
    public var lblStats:TextView
    public var scrollView:ScrollView
    
    init(_ view: View, _ source:VDUrl) throws {
        _source = source
        viewLeftHeirachy = view.viewForId("viewLeftHeirachy")!
        viewContent = view.viewForId("viewContent")!
        viewRightInfo = view.viewForId("viewRightInfo")!
        lblFPS = view.viewForId("lblFPS")! as! TextView
        lblFPS2 = view.viewForId("lblFPS2")! as! TextView
        lblStats = view.viewForId("lblStats")! as! TextView
        let scrollView = ScrollView()//{ _type: "LEAnchor", edge: "Bottom", percent: 1.0 }
        self.scrollView = scrollView
        scrollView.listLayouts = [
            LEAnchor(edge: .Bottom, percent: 1.0),
            LEAnchor(edge: .Right, percent: 1.0)
        ]
        scrollView.backgroundColor = LabeledColor.green
        let textSample = TextView(text: "Hello World")
        textSample.frame = Rect(x: 20, y: 20, width: 100, height: 20)
        scrollView.addSubview(textSample)
        viewLeftHeirachy.addSubview(scrollView)
        super.init(view)
    }
    
    var lastFrames = 0
    override public func drawStart() {
        let app = TestGameApp.shared!
        let newFrames = app.skippedFrames
        if (lastFrames == newFrames) { return }
        lastFrames = newFrames
        lblFPS.text = "\(newFrames) skipped frames"
        lblFPS2.text = "\(app.skippedTime) ms"
        lblStats.text = app.lastStats
    }
    
    override public func viewDidLayout() {
        super.viewDidLayout()
        scrollView.contentSize = scrollView.frame.size
    }
}

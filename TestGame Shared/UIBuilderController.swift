//
//  UIBuilder.swift
//  TestGame
//
//  Created by Isaac Paul on 1/5/23.
//

import Foundation
/*
public class UIBuilderView: View {
    internal init(viewLeftHeirachy: View, viewContent: View, viewRightInfo: View) {
        self.viewLeftHeirachy = viewLeftHeirachy
        self.viewContent = viewContent
        self.viewRightInfo = viewRightInfo
        super.init()
    }
    
 //Screwed by order of operations. Swift must guarantee all variables of the child are initialized before the parent.
 //One solution is to allow out of order deserializing
    public override init(from decoder: Decoder, clipBoundsDefault:Bool) throws {
        try super.init(from: decoder, clipBoundsDefault: clipBoundsDefault)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.viewLeftHeirachy = try container.decodeDynamicItem(View.self, forKey: .viewLeftHeirachy)
        self.viewContent = try container.decodeDynamicItem(View.self, forKey: .viewContent)
        self.viewRightInfo = try container.decodeDynamicItem(View.self, forKey: .viewRightInfo)
        //super.init()
        try someInit2(from: decoder, clipBoundsDefault: clipBoundsDefault)
    }
    
    public required init(from decoder: Decoder) throws {
        try someInit2(from: decoder, clipBoundsDefault: false)
    }
    
    public var viewLeftHeirachy:View
    public var viewContent:View
    public var viewRightInfo:View
    
    private enum CodingKeys: String, CodingKey {
        case viewLeftHeirachy
        case viewContent
        case viewRightInfo
    }
    
    func someInit2(from decoder: Decoder, clipBoundsDefault:Bool) throws {
        //
    }
    
    public override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeDynamicItem(viewLeftHeirachy, forKey: .viewLeftHeirachy)
        try container.encodeDynamicItem(viewContent, forKey: .viewContent)
        try container.encodeDynamicItem(viewRightInfo, forKey: .viewRightInfo)
    }
}*/

public class UIBuilderController : ViewController, PackageChangeListener {
    
    let _source:VDUrl

    static public func build(_ imageManager:SimpleImageManager) throws -> UIBuilderController {
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
        let mountedDir = vd.packages.contains(vcUrl)
        let result = try UIBuilderController(myView, vcUrl)
        try mountedDir?.startWatching(result)
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
        textSample.frame = Frame(x: 20, y: 20, width: 100, height: 20)
        scrollView.addSubview(textSample)
        viewLeftHeirachy.addSubview(scrollView)
        super.init(view)
    }
    
    deinit {
        let vd = Application.shared().vd
        vd.removeWatcher(self)
    }
    
    var lastFrames = 0
    override public func drawStart() {
        let app = TestGameApp.shared()
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
    
    public func fileChanges(_ files: [VDItem]) {
        do {
            if let _ = files.first(where: {$0.url == _source}),
               let window = view.findWindow() as? CustomWindow {
                
                let newVC = try UIBuilderController.build(window.imageManager)
                window.setRootViewController(newVC)
            }
        } catch {
            
        }
    }
}

//
//  ViewController.swift
//  TestGame
//
//  Created by Isaac Paul on 7/2/22.
//

import Foundation

protocol ViewFactory {
    func loadView() throws -> View
}

class VirtualDriveView : ViewFactory {
    let _drive:VirtualDrive
    let _path:String
    init(drive:VirtualDrive, path:String) {
        _path = path
        _drive = drive
    }
    
    func loadView() -> View {
        let data = _drive.readFile(_path)
        return data!.toView()
    }
}

extension Data {
    func toView() -> View {
        return View()
    }
}

extension URL: ViewFactory {
    func loadView() throws -> View {
        let data = try Data(contentsOf: self)
        return data.toView()
    }
}

//I feel like this can be done better.
//On almost any system we can expect to be able to just never unload view. In which case, it is fine how it is.
// Though I don't feel like I want to get rid of that expectation.
//Maybe I should just stop bikeshedding.
//In case I do want to add that support: I believe we can structure this so we don't ever have to assume or ask if
//view is null. A controller in a controller can be loaded with guaranteed view reference.
//OR... we can just not have view did load.. and pass the view in directly

//Ok here is the reasoning.. if ViewController exists then view needs to exist.
//If we need more memory then we would not only want to remove the view but also the view controller.
//If we can't remove the view (visible).. we can't remove the controller.
//Hence, we tie them together.
open class ViewController {
    
    /*
    private var _viewFactory:ViewFactory?
    init(drive:VirtualDrive, path:String) { //TODO: drive should really be a singleton
        _viewFactory = VirtualDriveView(drive: drive, path: path)
    }
    init() {
        _viewFactory = nil
    }
    init(url:URL) {
        _viewFactory = url
    }
    
    public var _view:View? = nil
    public var view:View { //TODO: Side effects.. I wonder if I should avoid this
        get {
            if let view = _view {
                return view
            }
            let newView = loadView()
            _view = newView
            return newView
        }
    }*/
    
    public var view:View
    init(_ view:View) {
        self.view = view
    }
    
    open func viewWillLayout() { }
    open func viewDidLayout() { }
    open func viewWillAppear(_ animated:Bool) { }
    open func viewDidAppear(_ animated:Bool) { }
    open func viewWillDisappear(_ animated:Bool) { }
    open func viewDidDisappear(_ animated:Bool) { }
    open func didReceiveMemoryWarning() { }
    open func drawStart() { }
}





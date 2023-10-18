//
//  FullWindow.swift
//  
//
//  Created by Isaac Paul on 4/23/23.
//

import SDL2
import SDL2Swift

public final class FullWindow: LiteWindow {
    let renderServer:RendererServer
    public let renderClient:RendererClient
    
    public var rootViewController:ViewController? = nil
    public var rootView:View? = nil
    public let atlas:ImageAtlas
    public let imageManager:SimpleImageManager
    public var drawable:IDrawable? = nil
    
    //TODO: Replace options with features; Allow driver to change
    override public init(parent: Application,
                  title: String,
                  frame: Rect<Int> = Rect(x: 0, y: 0, width: 800, height: 600),
                  windowOptions: BitMaskOptionSet<SDLWindow.Option> = [.resizable, .shown],
                  driver: Renderer.Driver = .default,
                  options: BitMaskOptionSet<Renderer.Option> = []) throws {
        
#if os(iOS)
        let sdlWindow = try SDLWindow(title: title,
                                  frame: (SDLWindow.Position.point(0), SDLWindow.Position.point(0), 0, 0),
                                   options: [.fullscreen])
#else
        let sdlWindow = try SDLWindow(title: title,
                                  frame: frame.toSDLTuple(),
                                   options: windowOptions)
#endif
        
        let renderer = try Renderer(window: sdlWindow, driver: driver, options: options)
        atlas = ImageAtlas(renderer)
        imageManager = SimpleImageManager(atlas: atlas, drive: parent.vd)
        imageManager.loadSystemFonts()
        let results = parent.vd.allItemsWithExt("ttf")
        for eachItem in results {
            imageManager.loadVDFont(eachItem.url)
        }
        renderServer = RendererServer(renderer: renderer, imageManager: imageManager)
        renderClient = RendererClient([], renderServer)
        
        try super.init(parent: parent, sdlWindow: sdlWindow, renderer: renderer)
        if let size = sdlWindow.rendererSize {
            renderClient._windowSize = Size(Int16(size.width), Int16(size.height))
        } else {
            renderClient._windowSize = Size<Int16>(Int16(frame.size.width), Int16(frame.size.height))
        }
        //let vc = try UIBuilderController.build(imageManager)
        //setRootViewController(vc)
        /*
        Task { [weak self] in
            print("Loading Textures..")
            let sprite = imageManager.image(named:"oryx_16bit_scifi_vehicles_105.bmp")
            print("idk: \(String(describing: sprite?.subTextureIndex.sourceRect))")
            self?.randomImage = sprite
        }*/
        
    }
    
    var drawCount = 0
    public override func drawStart() throws {
        drawCount = 0
        try super.drawStart()
        rootViewController?.drawStart()
    }
    
    public func setRootViewController(_ vc:ViewController) {
        self.rootViewController = vc
        let view = vc.view
        self.rootView = view
        view.window = self
        view.layout()
        vc.viewWillAppear(false)
        vc.viewDidAppear(false)
    }
    
    public override func handleEvents(_ events:[SDL_Event]) {
        super.handleEvents(events)
        for eachEvent in events {
            if (eachEvent.type == SDL_MOUSEMOTION.rawValue) {
                let mouseEvent = eachEvent.motion
                let touchingView = viewForPoint(mouseEvent.pos())
                let previousView = viewForPoint(mouseEvent.previousPos())
                if (touchingView !== previousView) {
                    touchingView?.onMouseEnter()
                    previousView?.onMouseLeave()
                }
                touchingView?.onMouseMotion(event: mouseEvent)
                continue
            }
            
            if (eachEvent.type == SDL_MOUSEBUTTONUP.rawValue) {
                let mouseEvent = eachEvent.button
                let point = Point<DValue>(DValue(mouseEvent.x), DValue(mouseEvent.y))
                let touchingView = viewForPoint(point)
                touchingView?.onMouseRelease(MouseButtonEvent(x: mouseEvent.x, y: mouseEvent.y, button: mouseEvent.button))
                continue
            }
            
            if (eachEvent.type == SDL_MOUSEBUTTONDOWN.rawValue) {
                let mouseEvent = eachEvent.button
                let point = Point<DValue>(DValue(mouseEvent.x), DValue(mouseEvent.y))
                let touchingView = viewForPoint(point)
                touchingView?.onMousePress(MouseButtonEvent(x: mouseEvent.x, y: mouseEvent.y, button: mouseEvent.button))
                continue
            }
            
            if (eachEvent.type == SDL_MOUSEWHEEL.rawValue) {
                continue
            }
        }
        //delegate?.handleEvents(events)
        //Swap All controllers
        /*
        for key in _devices.keys {
            _devices[key]?.pushState()
        }*/
        
    }
    
    public func viewForPoint(_ point:Point<DValue>) -> View? {
        let result = rootView?.viewForPoint(point)
        return result
    }
    
    public override func onWindowEvent(_ events: [WindowEvent]) {
        super.onWindowEvent(events)
        for eachEvent in events {
            switch (eachEvent) {
            case .none:
                break
            case .shown:
                break
            case .hidden:
                break
            case .exposed:
                break
            case .moved(x: let x, y: let y):
                frame.x = Int16(x)
                frame.y = Int16(y)
                break
            case .resized(width: let width, height: let height):
                frame.size = Size(Int16(width), Int16(height))
                renderClient._windowSize = frame.size
                self.rootView?.layout()
                break
            case .sizeChanged(width: let width, height: let height):
                frame.size = Size(Int16(width), Int16(height))
                renderClient._windowSize = frame.size
                self.rootView?.layout()
                break
            case .minimized:
                break
            case .maximized:
                break
            case .restored:
                break
            case .mouseEnter:
                break
            case .mouseLeave:
                break
            case .gainedKeyboardFocus:
                break
            case .lostKeyboardFocus:
                break
            case .closeRequest:
                break
            case .takeFocus:
                break
            case .hitTest:
                break
            case .iccprofChanged:
                break
            case .displayChanged(displayId: let displayId):
                break
            }
        }
    }

    public override func drawFinish() {
        super.drawFinish()
    }

    var totalDrawTime:UInt64 = 0
    public override func draw(time: UInt64) throws {
        totalDrawTime += time
        renderClient.clearCommands()
        drawable?.draw(time, renderClient)
        renderClient.sendCommands()
        
        let context = UIRenderContext(renderer: renderer, imageManger: imageManager)
        context.currentWindowFrame[context.currentWindowFrame.count - 1] = frame.bounds()
        let drawingInterp = renderServer.drawingInterpolator
        drawCount = drawingInterp._futureCmdList.count
        drawingInterp.draw(totalDrawTime - 100)
        
        //TODO: Move; we want the server to draw everything?
        if let view = rootView {
            try view.draw(context, view.frame)
        }
    }
}

/*
 I notice a problem with remote rendering.
 if we want a truely disconnected rendering experience
 we need to be able to create windows.. right?
 seems like an os problem.. 
 
 */

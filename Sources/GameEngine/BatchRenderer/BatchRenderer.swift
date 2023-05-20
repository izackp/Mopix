//
//  BatchRenderer.swift
//  
//
//  Created by Isaac Paul on 5/9/23.
//

import SDL2
import SDL2Swift

/*
 I have some interesting ideas when it comes to this rendering server:
 Problems to solve:
 * Jitter due to ticks per second not matching fps
 * Rollback. Pointers and references are difficult to recreate when reserialing the game state.
 So using references to 'images' might prove difficult over using handles.
 * Alternative rendering engines. Lets say I want to use Godot or unity for rendering. All I have to do is reimplement
 the api in that engine... as well as the resource retrieval mechanisms
 
 the last two might not be real concerns...
 
 Ideas:
 Context -
   Step 0 occurend a while ago (-20ms)
   Step 1 is the current frame  (0ms)
   Step 2 is the next frame  (+20ms)
 
 -=-==-=-=-=--==-=-=-
 Method A:
 Every step we build a draw command list. It lists what to draw, where, and how. The current list depicts what the
 game will look like in 20ms. We interpolate all this information with the last step.
 
 Problems:
 - Ever so slight delay to expected state. Each frame is interpolated with the last. So we are always a fraction of a frame 'off'
 - Too wide steps will depict incorrect animations: Lets say we draw a object moving in a sine wave. With large steps
 the object can easily interpolate 'over' waves
 
 - We press a to jump. We draw the prep frame immediatly. This is okay
 We collide with another object. We draw the collided frame immediatly.. this is not okay?
 - Exaggerated Ex: in Step 1 we move from x: 0 to x: 100. At x:99 is a spike that harms the moving obj. This is calculated in 10ms.
 The renderer begins drawing at the 10ms mark. The renderer draws the moving object interpolated at x: 50 with the
 ouch animation started. Next frame is at the 16ms mark. With the ouch frame, we are still moving torward the spike.
 
 Solutions:
 * Do nothing.
 * Add key frames to draw data
 
 Drawbacks:
 - Key frames will significantly increase drawing complexity.. however.. it is opt-in..
 
 -==-=-=-=-=-=-=-
 Method B:
 Simulate the game twice. One at frame speed, and one at tps speed. We don't have to draw the past and interpolate.
 
 Problems:
 - Slow. Would require copying the game state once per tps. As well as running simulations (ai, etc) more than necessary.
 - ~~Predictive~~ nevermind if we don't provide the copy input then it should be the mostly same.
 
 =--=-=-==-=-=-=-=
 Method No:
 Immediate mode. Render at tps.
 
 Problems:
 - Jitter. Animations have inconsistent frame duration.
 
 Solutions:
 - Always simulate the game faster than the screen?
 
 Drawbacks:
 - RTS games dont necessary need fast input or a high tps.
 
 -==-=-=-=-=-=-=-=-=-
 
 To consider: We need to run unique code anyways during each frame. For example, Lets say if our mouse hovers over a unit. We would want to immediately highlight the unit and maybe update the mouse icon.
 
 Maybe this is not a problem? Controller input wasn't expected to have that kind of responsiveness.. but maybe it should.
 What if we have a virtual mouse controlled by a gamepad? what if this frame makes all the difference in feel?
 
 */
/*
I have an idea to fix responsiveness. However we are supporting direct responsive input we could create a pseudo character
this character will transmit commands to the server to direct the actual character.
I'm trying to figure out the best way to get rid of jitter from running simulation at a slower speed than fps.
* Interpolate with the last frame.
  - Always behind.
  - Some frames will display an incorrect state (showing ouch frame before touching lava). Can be fixed with calculated keyframes.
* Copy the game world and run separate simulation for each step
  - Predictive
  - Costly
  - More responsive
  - How to keep sync? Keep recreating the world every tick? Would this reintroduce jitter? We have to interpolate anyways?
  

 */
public struct DrawCmdImage {
    let animationId:UInt64
    let resourceId:UInt64
    let dest:Frame<Int>
    let color:SDLColor = SDLColor.white
    let z:Int
    let rotation:Float
    let rotationPoint:Point<Int> //point where to rotate
    let alpha:Float
}

public class BatchRenderer {
    
    public init(renderer: Renderer, imageManager:SimpleImageManager) {
        self.renderer = renderer
        self.imageManager = imageManager
    }
    
    let imageManager:SimpleImageManager
    let renderer:Renderer
    var cache:[ObjectIdentifier:SurfaceBackedTexture] = [:]
    
    var _idImageCache:[UInt64:Image] = [:]
    var _urlImageCache:[String:UInt64] = [:] //TODO: FIX: Also cached in image manager
    var _lastCmdList:[DrawCmdImage] = []
    var _futureCmdList:[DrawCmdImage] = []
    var _futureTime:UInt64 = 0
    
    //MARK: -
    //TODO: Add reference counting
    public func loadResource(_ url:VDUrl) -> UInt64 {
        let path = url.absoluteString //TODO: probably doesn't include host
        if let image = _urlImageCache[path] {
            return image
        }
        let image = imageManager.image(url)
        var uuid:UInt64 = 0
        while true {
            uuid = Xoroshiro.shared.randomBytes()
            if (_idImageCache[uuid] == nil && uuid != 0) {
                break
            }
        }
        _idImageCache[uuid] = image
        return uuid
    }
    
    public func unloadResource(_ id:UInt64) {
        _idImageCache[id] = nil
    }
    
    //This looks a little dumb but the idea is that we will want to move this off thread in the future
    //Which does bring up more questions about how to manage that..
    public func loadResources(_ urlList:[VDUrl]) -> [UInt64] {
        let result = urlList.map { (url:VDUrl) in
            loadResource(url)
        }
        return result
    }
    
    public func unloadResources(_ idList:[UInt64]) {
        for eachId in idList {
            unloadResource(eachId)
        }
    }
    
    //MARK: -
    public func draw(_ imageUrl:VDUrl, rect:Frame<Int>, _ color:SDLColor = SDLColor.white, alpha:Float = 1) {
        let image = imageManager.image(imageUrl)
        image?.draw(renderer, rect.sdlRect(), color)
    }
    
    public func draw(_ id:UInt64, rect:Frame<Int>, _ color:SDLColor = SDLColor.white, z:Int = 1, rotation:Float = 0, rotationPoint:Point<Int> = .zero, alpha:Float = 1) {
        //let image = _idImageCache[id]
        //image?.draw(renderer, rect.sdlRect(), color)
        _futureCmdList.append(DrawCmdImage(animationId: 0, resourceId: id, dest: rect, z: z, rotation:rotation, rotationPoint:rotationPoint, alpha:alpha))
    }
    
    func drawAllCommands() {
        
    }
    
    //TODO: Use texture atlas
    func textureFor(_ id:ObjectIdentifier, _ backingImage:EditableImage) throws -> Texture {
        if let existing = cache[id] {
            let texture = existing.texture
            if (existing.editIteration == backingImage.editIteration) {
                return texture
            }
            let backingSurface = backingImage.surface
            let attr = try texture.attributes()
            if (attr.width == backingSurface.width && attr.height == backingSurface.height) {
                try backingImage.surface.withPixelData { pixelData in
                    try texture.update(pixels: pixelData.ptr, pitch: pixelData.pitch)
                }
                
                cache[id]?.editIteration = backingImage.editIteration
                return texture
            }
        }
        let newTexture = try Texture(renderer: renderer, surface: backingImage.surface)
        cache[id] = SurfaceBackedTexture(texture: newTexture, editIteration: backingImage.editIteration)
        return newTexture
    }
    
    public func draw(_ image:EditableImage, rect:Frame<Int>) {
        let objId = ObjectIdentifier(image)
        
        do {
            let texture = try textureFor(objId, image)
            try renderer.copy(texture, destination: rect.sdlRect())
        } catch {
            
        }
    }
}

public class RendererClient {
    public init(cmdList: [DrawCmdImage] = []) {
        self.cmdList = cmdList
    }
    
    
    var cmdList:[DrawCmdImage] = []
    
    //MARK: -
    
    public func draw(_ id:UInt64, rect:Frame<Int>, _ color:SDLColor = SDLColor.white, z:Int = 1, rotation:Float = 0, rotationPoint:Point<Int> = .zero, alpha:Float = 1) {
        //let image = _idImageCache[id]
        //image?.draw(renderer, rect.sdlRect(), color)
        cmdList.append(DrawCmdImage(animationId: 0, resourceId: id, dest: rect, z: z, rotation:rotation, rotationPoint:rotationPoint, alpha:alpha))
    }
}

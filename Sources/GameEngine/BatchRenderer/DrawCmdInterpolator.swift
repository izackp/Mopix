//
//  DrawCmdInterpolator.swift
//  
//
//  Created by Isaac Paul on 10/4/23.
//

import SDL2Swift

public class DrawCmdInterpolator {
    public init(renderer: Renderer, resourceStore: ResourceStore, _lastCmdList: [DrawCmdImage] = [], _futureCmdList: [DrawCmdImage] = []) {
        self.renderer = renderer
        self.resourceStore = resourceStore
        self._lastCmdList = IndexedOrderedList(list: _lastCmdList, getId: DrawCmdImage.getId)
        self._futureCmdList = IndexedOrderedList(list: _futureCmdList, getId: DrawCmdImage.getId)
    }
    
    let renderer:Renderer
    let resourceStore:ResourceStore
    
    var _lastCmdList:IndexedOrderedList<DrawCmdImage> = IndexedOrderedList()
    var _futureCmdList:IndexedOrderedList<DrawCmdImage> = IndexedOrderedList()
    
    //MARK: -
    func drawCmd(_ command:DrawCmdImage) {
        guard let image = resourceStore._idImageCache[command.resourceId] else { return }
        let source = image.getTextureSlice()
        if (command.rotation != 0 || command.flip.hasValue()) {
            renderer.draw(source, command.dest.sdlRect(), command.color, command.alpha, Double(command.rotation), command.rotationPoint.sdlPoint(), command.flip)
        } else {
            renderer.draw(source, command.dest.sdlRect(), command.color, command.alpha)
        }
        
    }

    //TODO: What if this is sent multiple times?
    //TODO: Try flattening z values to reduce texture switching;
    //Sort by z then sort by collision
    //Not sure if as fast as previous method but it is easier to read
    public func receiveCmds(_ list:[DrawCmdImage]) {
        var oldList = _lastCmdList
        _lastCmdList = _futureCmdList
        //In Swift 5 sort() uses stable implementation
        let sorted = list.sorted { (cmd:DrawCmdImage, other:DrawCmdImage) in
            return cmd.compare(other) == .orderedAscending
        }
        oldList.updateList(sorted, getId: DrawCmdImage.getId)
        _futureCmdList = oldList
    }
    
    /*
     public func receiveCmds(_ list:[DrawCmdImage]) {
         var oldList = _lastCmdList
         var oldIndex = _lastCmdListIndex
         _lastCmdList = _futureCmdList
         _lastCmdListIndex = _futureCmdListIndex
         oldList.removeAll(keepingCapacity: true)
         //In Swift 5 sort() uses stable implementation
         let sorted = list.sorted { (cmd:DrawCmdImage, other:DrawCmdImage) in
             return cmd.compare(other) == .orderedAscending
         }
         oldList.append(contentsOf: sorted)
         oldIndex.removeAll(keepingCapacity: true)
         sorted.forEachUnchecked { eachItem, i in
             let index = Int(Int64(bitPattern: eachItem.animationId))
             oldIndex[index] = eachItem
         }
         _futureCmdList = oldList
         _futureCmdListIndex = oldIndex
     }
     */

    public func draw(_ time:UInt64) {
        let interpolated = _futureCmdList.list.map() {
            let id = Int(Int64(bitPattern: $0.animationId))
            if (id == 0) {
                return $0
            }
            let matching = _lastCmdList[id]
            if let matching = matching {
                return $0.lerp(matching, time)
            } else {
                return $0
            }
        }

        
        let previousRect = renderer.getClipRect()
        do {
            try renderer.setClipRect(nil)
            let currentClip = Rect<Int>.zero
            let currentSDLClip = currentClip.sdlRect()
            for eachItem in interpolated {
                //TODO: We can also do the same with color mod and alpha; check if effects perfomance
                let clippingRect = eachItem.clippingRect
                if (clippingRect != currentClip) {
                    try renderer.setClipRect(currentSDLClip) ///Note: 0 width or height is same as setting nil
                }
                
                drawCmd(eachItem)
            }
            try renderer.setClipRect(previousRect)
        } catch let error {
            print("Unable to set clipping rect: \(error)")
        }
    }
}

//
//  DrawCmdInterpolator.swift
//
//
//  Created by Isaac Paul on 10/4/23.
//

import SDL2Swift
import SDL2

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

    // Full sorted command list for the next frame (all types)
    var _futureAllCmds:[DrawCmd] = []
    var _lastAllCmds:[DrawCmd] = []

    //MARK: -
    func drawImageCmd(_ command:DrawCmdImage, dest: Rect<Int>) throws {
        let image = try resourceStore.fetchResource(command.resourceId)
        let source = image.getTextureSlice()
        if (command.rotation != 0 || command.flip.hasValue()) {
            try renderer.draw(source, dest.sdlRect(), command.color, command.alpha, Double(command.rotation), command.rotationPoint.sdlPoint(), command.flip)
        } else {
            try renderer.draw(source, dest.sdlRect(), command.color, command.alpha)
        }
    }

    //TODO: What if this is sent multiple times?
    //TODO: Try flattening z values to reduce texture switching;
    //Sort by z then sort by collision
    //Not sure if as fast as previous method but it is easier to read
    public func receiveCmds(_ list:[DrawCmd]) {
        // Extract image commands for interpolation tracking
        var imageCmds:[DrawCmdImage] = []
        for cmd in list {
            if case .image(let imgCmd) = cmd {
                imageCmds.append(imgCmd)
            }
        }

        let oldList = _lastCmdList
        _lastCmdList = _futureCmdList
        // In Swift 5 sort() uses stable implementation
        let sorted = imageCmds.sorted { (cmd:DrawCmdImage, other:DrawCmdImage) in
            return cmd.compare(other) == .orderedAscending
        }
        oldList.updateList(sorted, getId: DrawCmdImage.getId)
        _futureCmdList = oldList

        // Sort all commands by z for rendering
        let sortedAll = list.sorted { $0.z < $1.z }
        _lastAllCmds = _futureAllCmds
        _futureAllCmds = sortedAll

        for eachReasource in resourceStore._idImageCache.values {
            eachReasource.ticksSinceLastUse += 1
        }
    }

    public func draw(_ time:UInt64) {
        let previousRect = renderer.getClipRect()
        do {
            try renderer.setClipRect(nil)
            var currentClip = Rect<Int>.zero

            // Resolve parent-relative positions to absolute screen coords
            // keyed by animationId
            var resolvedPositions:[UInt64:Rect<Int>] = [:]

            for eachCmd in _futureAllCmds {
                // Apply clipping if needed
                let cmdClipRect:Rect<Int>
                switch eachCmd {
                case .image(let c): cmdClipRect = c.clippingRect
                case .fill(let c):  cmdClipRect = c.clippingRect
                case .view(let c):  cmdClipRect = c.clippingRect
                case .rtt(let c):   cmdClipRect = c.clippingRect
                }

                if cmdClipRect != currentClip {
                    currentClip = cmdClipRect
                    if currentClip == .zero {
                        try renderer.setClipRect(nil) // 0 width/height == nil clip
                    } else {
                        try renderer.setClipRect(currentClip.sdlRect())
                    }
                }

                switch eachCmd {
                case .image(let imgCmd):
                    // Interpolate with last frame
                    let id = Int(Int64(bitPattern: imgCmd.animationId))
                    let interpolated: DrawCmdImage
                    if id != 0, let matching = _lastCmdList[id] {
                        interpolated = imgCmd.lerp(matching, time)
                    } else {
                        interpolated = imgCmd
                    }
                    // Resolve absolute position
                    let resolved = resolvedDest(interpolated.dest, parentId: interpolated.parentAnimationId, positions: &resolvedPositions)
                    if interpolated.animationId != 0 {
                        resolvedPositions[interpolated.animationId] = resolved
                    }
                    do {
                        try drawImageCmd(interpolated, dest: resolved)
                    } catch {
                        print("Unable to draw drawCmd: \(imgCmd.animationId) : \(error.localizedDescription)")
                    }

                case .fill(let fillCmd):
                    let resolved = resolvedDest(fillCmd.dest, parentId: fillCmd.parentAnimationId, positions: &resolvedPositions)
                    if fillCmd.animationId != 0 {
                        resolvedPositions[fillCmd.animationId] = resolved
                    }
                    do {
                        try drawFillCmd(fillCmd, dest: resolved)
                    } catch {
                        print("Unable to draw fill cmd: \(error.localizedDescription)")
                    }

                case .view(let viewCmd):
                    let resolved = resolvedDest(viewCmd.dest, parentId: viewCmd.parentAnimationId, positions: &resolvedPositions)
                    if viewCmd.animationId != 0 {
                        resolvedPositions[viewCmd.animationId] = resolved
                    }
                    do {
                        try drawViewCmd(viewCmd, dest: resolved)
                    } catch {
                        print("Unable to draw view cmd: \(error.localizedDescription)")
                    }

                case .rtt(let rttCmd):
                    // Stub: RTT recursive render-to-texture not yet fully implemented
                    let resolved = resolvedDest(rttCmd.targetRect, parentId: rttCmd.parentAnimationId, positions: &resolvedPositions)
                    if rttCmd.animationId != 0 {
                        resolvedPositions[rttCmd.animationId] = resolved
                    }
                    print("DrawCmdRTT stub — not yet rendered")
                }
            }
            try renderer.setClipRect(previousRect)
        } catch let error {
            print("Unable to draw: \(error)")
        }
    }

    // MARK: - Helpers

    /// Resolve the absolute position of a command given its parent's resolved position.
    private func resolvedDest(_ dest: Rect<Int>, parentId: UInt64, positions: inout [UInt64:Rect<Int>]) -> Rect<Int> {
        guard parentId != 0, let parentRect = positions[parentId] else {
            return dest
        }
        return Rect(
            x: parentRect.x + dest.x,
            y: parentRect.y + dest.y,
            width: dest.width,
            height: dest.height
        )
    }

    private func sdlColorComponents(_ color: SDLColor, alpha: Float) -> (r: UInt8, g: UInt8, b: UInt8, a: UInt8) {
        let raw = color.rawValue
        // SDLColor rawValue is ARGB: 0xAARRGGBB
        let a = UInt8((raw >> 24) & 0xFF)
        let r = UInt8((raw >> 16) & 0xFF)
        let g = UInt8((raw >> 8) & 0xFF)
        let b = UInt8(raw & 0xFF)
        let modifiedAlpha = UInt8(Float(a) * alpha)
        return (r, g, b, modifiedAlpha)
    }

    private func drawFillCmd(_ cmd: DrawCmdFill, dest: Rect<Int>) throws {
        let (r, g, b, a) = sdlColorComponents(cmd.color, alpha: cmd.alpha)
        try renderer.setDrawColor(red: r, green: g, blue: b, alpha: a)
        try renderer.fill(rect: dest.sdlRect())
    }

    private func drawViewCmd(_ cmd: DrawCmdView, dest: Rect<Int>) throws {
        // Draw background
        let (bgR, bgG, bgB, bgA) = sdlColorComponents(cmd.backgroundColor, alpha: cmd.backgroundAlpha)
        if bgA > 0 {
            try renderer.setDrawColor(red: bgR, green: bgG, blue: bgB, alpha: bgA)
            try renderer.fill(rect: dest.sdlRect())
        }
        // Draw borders
        if cmd.borderWidth > 0 {
            let bw = cmd.borderWidth
            let (bdR, bdG, bdB, bdA) = sdlColorComponents(cmd.borderColor, alpha: 1.0)
            try renderer.setDrawColor(red: bdR, green: bdG, blue: bdB, alpha: bdA)
            // Top
            try renderer.fill(rect: Rect<Int>(x: dest.x, y: dest.y, width: dest.width, height: bw).sdlRect())
            // Bottom
            try renderer.fill(rect: Rect<Int>(x: dest.x, y: dest.bottom - bw, width: dest.width, height: bw).sdlRect())
            // Left
            try renderer.fill(rect: Rect<Int>(x: dest.x, y: dest.y + bw, width: bw, height: dest.height - bw * 2).sdlRect())
            // Right
            try renderer.fill(rect: Rect<Int>(x: dest.right - bw, y: dest.y + bw, width: bw, height: dest.height - bw * 2).sdlRect())
        }
    }
}

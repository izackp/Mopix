//
//  DrawCmdInterpolator.swift
//
//
//  Created by Isaac Paul on 10/4/23.
//

import SDL2Swift
import SDL2

public class DrawCmdInterpolator {
    public init(renderer: Renderer, resourceStore: ResourceStore, _lastCmdList: [DrawCmd] = [], _futureCmdList: [DrawCmd] = []) {
        self.renderer = renderer
        self.resourceStore = resourceStore
        self._lastCmdList = IndexedOrderedList(list: _lastCmdList, getId: DrawCmd.getId)
        self._futureCmdList = IndexedOrderedList(list: _futureCmdList, getId: DrawCmd.getId)
    }

    let renderer: Renderer
    let resourceStore: ResourceStore

    var _lastCmdList: IndexedOrderedList<DrawCmd> = IndexedOrderedList()
    var _futureCmdList: IndexedOrderedList<DrawCmd> = IndexedOrderedList()

    var _futureAllCmds: [DrawCmd] = []
    var _lastAllCmds: [DrawCmd] = []

    // MARK: -

    func drawImageCmd(_ command: DrawCmd, resourceId: UInt64, dest: Rect<Int>) throws {
        let image = try resourceStore.fetchResource(resourceId)
        let source = image.getTextureSlice()
        if command.rotation != 0 || command.flip.hasValue() {
            try renderer.draw(source, dest.sdlRect(), command.color, command.alpha, Double(command.rotation), command.rotationPoint.sdlPoint(), command.flip)
        } else {
            try renderer.draw(source, dest.sdlRect(), command.color, command.alpha)
        }
    }

    //TODO: What if this is sent multiple times?
    //TODO: Try flattening z values to reduce texture switching;
    //Sort by z then sort by collision
    public func receiveCmds(_ list: [DrawCmd]) {
        // Extract image commands for interpolation tracking
        let imageCmds = list.filter {
            if case .image = $0.type { return true }
            return false
        }

        let oldList = _lastCmdList
        _lastCmdList = _futureCmdList
        // In Swift 5 sort() uses stable implementation
        let sorted = imageCmds.sorted { (cmd:DrawCmdImage, other:DrawCmdImage) in
            return cmd.compare(other) == .orderedAscending
        }
        oldList.updateList(sorted, getId: DrawCmd.getId)
        _futureCmdList = oldList

        // Sort all commands by z for rendering
        let sortedAll = list.sorted { $0.z < $1.z }
        _lastAllCmds = _futureAllCmds
        _futureAllCmds = sortedAll

        for eachResource in resourceStore._idImageCache.values {
            eachResource.ticksSinceLastUse += 1
        }
    }

    public func draw(_ time: UInt64) {
        let previousRect = renderer.getClipRect()
        do {
            try renderer.setClipRect(nil)
            var currentClip = Rect<Int>.zero

            // Resolve parent-relative positions to absolute screen coords
            // keyed by animationId
            var resolvedPositions: [UInt64:Rect<Int>] = [:]

            for eachCmd in _futureAllCmds {
                if eachCmd.clippingRect != currentClip {
                    currentClip = eachCmd.clippingRect
                    if currentClip == .zero {
                        try renderer.setClipRect(nil)
                    } else {
                        try renderer.setClipRect(currentClip.sdlRect())
                    }
                }

                switch eachCmd.type {
                case .image(let resourceId):
                    let id = Int(Int64(bitPattern: eachCmd.animationId))
                    let interpolated: DrawCmd
                    if id != 0, let matching = _lastCmdList[id] {
                        interpolated = eachCmd.lerp(matching, time)
                    } else {
                        interpolated = eachCmd
                    }
                    // Resolve absolute position
                    let resolved = resolvedDest(interpolated.dest, parentId: interpolated.parentAnimationId, positions: &resolvedPositions)
                    if interpolated.animationId != 0 {
                        resolvedPositions[interpolated.animationId] = resolved
                    }
                    do {
                        try drawImageCmd(interpolated, resourceId: resourceId, dest: resolved)
                    } catch {
                        print("Unable to draw drawCmd: \(eachCmd.animationId) : \(error.localizedDescription)")
                    }

                case .fill:
                    let resolved = resolvedDest(eachCmd.dest, parentId: eachCmd.parentAnimationId, positions: &resolvedPositions)
                    if eachCmd.animationId != 0 {
                        resolvedPositions[eachCmd.animationId] = resolved
                    }
                    do {
                        try drawFillCmd(eachCmd, dest: resolved)
                    } catch {
                        print("Unable to draw fill cmd: \(error.localizedDescription)")
                    }

                case .view(let borderColor, let borderWidth):
                    let resolved = resolvedDest(eachCmd.dest, parentId: eachCmd.parentAnimationId, positions: &resolvedPositions)
                    if eachCmd.animationId != 0 {
                        resolvedPositions[eachCmd.animationId] = resolved
                    }
                    do {
                        try drawViewCmd(eachCmd, borderColor: borderColor, borderWidth: borderWidth, dest: resolved)
                    } catch {
                        print("Unable to draw view cmd: \(error.localizedDescription)")
                    }

                case .rtt:
                    let resolved = resolvedDest(eachCmd.dest, parentId: eachCmd.parentAnimationId, positions: &resolvedPositions)
                    if eachCmd.animationId != 0 {
                        resolvedPositions[eachCmd.animationId] = resolved
                    }
                    print("DrawCmd.rtt stub — not yet rendered")
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

    private func drawFillCmd(_ cmd: DrawCmd, dest: Rect<Int>) throws {
        let (r, g, b, a) = sdlColorComponents(cmd.color, alpha: cmd.alpha)
        try renderer.setDrawColor(red: r, green: g, blue: b, alpha: a)
        try renderer.fill(rect: dest.sdlRect())
    }

    private func drawViewCmd(_ cmd: DrawCmd, borderColor: SDLColor, borderWidth: Int, dest: Rect<Int>) throws {
        let (bgR, bgG, bgB, bgA) = sdlColorComponents(cmd.color, alpha: cmd.alpha)
        if bgA > 0 {
            try renderer.setDrawColor(red: bgR, green: bgG, blue: bgB, alpha: bgA)
            try renderer.fill(rect: dest.sdlRect())
        }
        // Draw borders
        if borderWidth > 0 {
            let bw = borderWidth
            let (bdR, bdG, bdB, bdA) = sdlColorComponents(borderColor, alpha: 1.0)
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

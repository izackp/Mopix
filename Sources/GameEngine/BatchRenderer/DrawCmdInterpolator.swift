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
        let sorted = imageCmds.sorted { (cmd:DrawCmd, other:DrawCmd) in
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

                case .text(let fontHandle, let content, let size, let align):
                    let resolved = resolvedDest(eachCmd.dest, parentId: eachCmd.parentAnimationId, positions: &resolvedPositions)
                    if eachCmd.animationId != 0 {
                        resolvedPositions[eachCmd.animationId] = resolved
                    }
                    do {
                        try drawTextCmd(eachCmd, fontHandle: fontHandle, content: content, size: size, align: align, dest: resolved)
                    } catch {
                        print("Unable to draw text cmd: \(error.localizedDescription)")
                    }

                case .line(let to, let thickness):
                    let resolved = resolvedDest(eachCmd.dest, parentId: eachCmd.parentAnimationId, positions: &resolvedPositions)
                    if eachCmd.animationId != 0 {
                        resolvedPositions[eachCmd.animationId] = resolved
                    }
                    do {
                        try drawLineCmd(eachCmd, to: to, thickness: thickness, origin: resolved)
                    } catch {
                        print("Unable to draw line cmd: \(error.localizedDescription)")
                    }

                case .circle(let radius, let filled):
                    let resolved = resolvedDest(eachCmd.dest, parentId: eachCmd.parentAnimationId, positions: &resolvedPositions)
                    if eachCmd.animationId != 0 {
                        resolvedPositions[eachCmd.animationId] = resolved
                    }
                    do {
                        try drawCircleCmd(eachCmd, radius: radius, filled: filled, center: Point(resolved.x, resolved.y))
                    } catch {
                        print("Unable to draw circle cmd: \(error.localizedDescription)")
                    }

                case .rect(let filled):
                    let resolved = resolvedDest(eachCmd.dest, parentId: eachCmd.parentAnimationId, positions: &resolvedPositions)
                    if eachCmd.animationId != 0 {
                        resolvedPositions[eachCmd.animationId] = resolved
                    }
                    do {
                        try drawRectCmd(eachCmd, filled: filled, dest: resolved)
                    } catch {
                        print("Unable to draw rect cmd: \(error.localizedDescription)")
                    }
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

    private func drawRectCmd(_ cmd: DrawCmd, filled: Bool, dest: Rect<Int>) throws {
        guard dest.width > 0, dest.height > 0 else { return }
        let (r, g, b, a) = sdlColorComponents(cmd.color, alpha: cmd.alpha)
        try renderer.setDrawColor(red: r, green: g, blue: b, alpha: a)

        if filled {
            try renderer.fill(rect: dest.sdlRect())
            return
        }

        try renderer.fill(rect: Rect(x: dest.x, y: dest.y, width: dest.width, height: 1).sdlRect())
        if dest.height > 1 {
            try renderer.fill(rect: Rect(x: dest.x, y: dest.bottom - 1, width: dest.width, height: 1).sdlRect())
        }
        if dest.height > 2 {
            try renderer.fill(rect: Rect(x: dest.x, y: dest.y + 1, width: 1, height: dest.height - 2).sdlRect())
            if dest.width > 1 {
                try renderer.fill(rect: Rect(x: dest.right - 1, y: dest.y + 1, width: 1, height: dest.height - 2).sdlRect())
            }
        }
    }

    private func drawTextCmd(
        _ cmd: DrawCmd,
        fontHandle: UInt64,
        content: String,
        size: Float,
        align: TextAlignment,
        dest: Rect<Int>
    ) throws {
        let font: Font
        do {
            font = try resourceStore.fetchFont(handle: fontHandle, size: size)
        } catch {
            throw GenericError(
                "Text font lookup/load failed (handle: \(fontHandle), size: \(size), content: '\(content)'): \(String(reflecting: error))"
            )
        }
        var measuredWidth = 0
        for character in content {
            do {
                measuredWidth += try font._font.glyphMetrics(c: character).advance
            } catch {
                throw GenericError(
                    "Text measurement/glyph metrics failed (character: '\(character)', content: '\(content)'): \(String(reflecting: error))"
                )
            }
        }

        let startX: Int
        switch align {
        case .center:
            startX = dest.x + (dest.width - measuredWidth) / 2
        case .right, .end:
            startX = dest.right - measuredWidth
        case .left, .start:
            startX = dest.x
        }

        var x = startX
        for character in content {
            let metrics: SDLFont.GlyphMetrics
            do {
                metrics = try font._font.glyphMetrics(c: character)
            } catch {
                throw GenericError(
                    "Text measurement/glyph metrics failed (character: '\(character)', content: '\(content)'): \(String(reflecting: error))"
                )
            }

            let image: AtlasImage
            do {
                image = try font.glyph(character)
            } catch {
                throw GenericError(
                    "Text glyph rasterization/atlas insertion failed (character: '\(character)', content: '\(content)'): \(String(reflecting: error))"
                )
            }
            let glyphDest = Rect(
                x: x,
                y: dest.y,
                width: Int(image.size.width),
                height: Int(image.size.height)
            )
            do {
                try renderer.draw(image.getTextureSlice(), glyphDest.sdlRect(), cmd.color, cmd.alpha)
            } catch {
                throw GenericError(
                    "Text renderer texture draw failed (character: '\(character)', content: '\(content)'): \(String(reflecting: error))"
                )
            }
            x += metrics.advance
        }
    }

    private func drawCircleCmd(_ cmd: DrawCmd, radius: Int, filled: Bool, center: Point<Int>) throws {
        guard radius > 0 else { return }
        let (r, g, b, a) = sdlColorComponents(cmd.color, alpha: cmd.alpha)
        try renderer.setDrawColor(red: r, green: g, blue: b, alpha: a)

        let outerRadiusSquared = radius * radius
        let innerRadius = max(0, radius - 1)
        let innerRadiusSquared = innerRadius * innerRadius
        for y in -radius...radius {
            for x in -radius...radius {
                let distanceSquared = x * x + y * y
                let shouldDraw = filled
                    ? distanceSquared <= outerRadiusSquared
                    : distanceSquared <= outerRadiusSquared && distanceSquared >= innerRadiusSquared
                if shouldDraw {
                    try renderer.drawPoint(x: Int32(center.x + x), y: Int32(center.y + y))
                }
            }
        }
    }

    private func drawLineCmd(_ cmd: DrawCmd, to: Point<Int>, thickness: Int, origin: Rect<Int>) throws {
        let lineThickness = max(1, thickness)
        let (r, g, b, a) = sdlColorComponents(cmd.color, alpha: cmd.alpha)
        try renderer.setDrawColor(red: r, green: g, blue: b, alpha: a)

        var x = origin.x
        var y = origin.y
        let endX = origin.x + to.x
        let endY = origin.y + to.y
        let deltaX = abs(endX - x)
        let stepX = x < endX ? 1 : -1
        let deltaY = -abs(endY - y)
        let stepY = y < endY ? 1 : -1
        var error = deltaX + deltaY

        while true {
            try drawLinePoint(x: x, y: y, thickness: lineThickness)
            if x == endX, y == endY { break }
            let doubledError = error * 2
            if doubledError >= deltaY {
                error += deltaY
                x += stepX
            }
            if doubledError <= deltaX {
                error += deltaX
                y += stepY
            }
        }
    }

    private func drawLinePoint(x: Int, y: Int, thickness: Int) throws {
        let radius = thickness / 2
        for offsetY in -radius...radius {
            for offsetX in -radius...radius {
                try renderer.drawPoint(x: Int32(x + offsetX), y: Int32(y + offsetY))
            }
        }
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

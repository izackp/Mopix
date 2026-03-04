//
//  UIRenderContext.swift
//  TestGame
//
//  Created by Isaac Paul on 6/22/22.
//

import Foundation
import SDL2
import SDL2Swift

public class UIRenderContext {
    public init(client: IDraw, imageManager: ImageManager) {
        self.client = client
        self.imageManager = imageManager
    }

    let client: IDraw
    public let imageManager: ImageManager

    var currentClipRect: Rect<DValue>? = nil
    // Tracks the animationId of the view currently being drawn into.
    // Child commands use this as their parentAnimationId.
    var currentParentAnimationId: UInt64 = 0
    // Monotonically increasing z counter; each emitted command increments this.
    var currentZ: Int = 0

    // Sub-command buffer stack for RTT support
    private var _rttStack: [[DrawCmd]] = []

    func fetchFont(_ fontDesc:FontDesc) throws -> Font {
        guard let font = try imageManager.fetchFont(desc: fontDesc) else {
            throw GenericError("No font for desc: \(fontDesc.family)")
        }
        return font
    }

    // MARK: - Command emission helpers

    /// Append a command to the current active buffer (RTT sub-commands or the main client).
    func emit(_ cmd: DrawCmd) {
        if _rttStack.isEmpty {
            client.drawCmd(cmd)
        } else {
            _rttStack[_rttStack.count - 1].append(cmd)
        }
    }

    private func nextZ() -> Int {
        let z = currentZ
        currentZ += 1
        return z
    }

    // MARK: - Clip rect

    func setClipRect(_ frame:Rect<DValue>?) throws {
        currentClipRect = frame
    }

    // MARK: - Draw methods

    func drawSquare(_ dest:Rect<Int16>, _ color:SDLColor, _ alpha:Float = 1) throws {
        let clipRect = clipRectAsInt()
        let fillCmd = DrawCmdFill(
            animationId: 0,
            parentAnimationId: currentParentAnimationId,
            dest: dest.to(Int.self),
            color: color,
            alpha: alpha,
            z: nextZ(),
            clippingRect: clipRect
        )
        emit(.fill(fillCmd))
    }

    func drawImage(_ image:AtlasImage, _ dest:Rect<Int16>, _ color:SDLColor = SDLColor.white, _ alpha:Float = 1) throws {
        guard let resourceId = resourceId(for: image) else {
            print("UIRenderContext.drawImage: no resource ID for AtlasImage — image will not be drawn")
            return
        }
        let clipRect = clipRectAsInt()
        let imgCmd = DrawCmdImage(
            animationId: 0,
            parentAnimationId: currentParentAnimationId,
            resourceId: resourceId,
            dest: dest.to(Int.self),
            z: nextZ(),
            alpha: alpha,
            rotation: 0,
            rotationPoint: .zero,
            clippingRect: clipRect,
            time: 0
        )
        emit(.image(imgCmd))
    }

    func drawText(_ text:Substring, _ font:Font, _ pos:Point<Int16>, _ color:SDLColor, _ alpha:Float = 1, spacing:Int = 0) throws {
        var dest = Rect<Int16>(x: pos.x, y: pos.y, width: 0, height: 0)
        for c in text {
            do {
                let metrics = try font._font.glyphMetrics(c: c)
                let image = try font.glyph(c)
                let imageSize = image.size.to(Int16.self)
                dest.width = imageSize.width
                dest.height = imageSize.height
                guard let resourceId = font.resourceId(for: c) else {
                    dest.x += Int16(metrics.advance) + Int16(spacing)
                    continue
                }
                let clipRect = clipRectAsInt()
                let imgCmd = DrawCmdImage(
                    animationId: 0,
                    parentAnimationId: currentParentAnimationId,
                    resourceId: resourceId,
                    dest: dest.to(Int.self),
                    z: nextZ(),
                    alpha: alpha,
                    rotation: 0,
                    rotationPoint: .zero,
                    clippingRect: clipRect,
                    time: 0
                )
                emit(.image(imgCmd))
                dest.x += Int16(metrics.advance) + Int16(spacing)
            } catch {
                print("Error couldn't draw character '\(c)': \(error.localizedDescription)")
            }
        }
    }

    func drawTextLine(_ text:ArraySlice<RenderableCharacter>, _ pos:Point<Int16>, _ alpha:Float = 1) throws {
        var dest = Rect<Int16>(x: pos.x, y: pos.y, width: 0, height: 0)
        for c in text {
            dest.width = Int16(c.size.width)
            dest.height = Int16(c.size.height)

            // Background fill for this character
            if let bgColor = c.background {
                try drawSquare(dest, bgColor.sdlColor())
            }

            // Glyph image
            if let image = c.img {
                dest.height = Int16(image.size.height)
                guard let resourceId = resourceId(for: image) else {
                    dest.x += Int16(c.size.width)
                    continue
                }
                let clipRect = clipRectAsInt()
                let imgCmd = DrawCmdImage(
                    animationId: 0,
                    parentAnimationId: currentParentAnimationId,
                    resourceId: resourceId,
                    dest: dest.to(Int.self),
                    z: nextZ(),
                    alpha: alpha,
                    rotation: 0,
                    rotationPoint: .zero,
                    clippingRect: clipRect,
                    time: 0
                )
                emit(.image(imgCmd))
            }
            dest.x += Int16(c.size.width)
        }
    }

    /// Render-to-texture: collect sub-commands, then wrap in DrawCmdRTT.
    func createAndDrawToTexture(_ block:(_ context:UIRenderContext, _ frame:Rect<DValue>) throws -> (), size:Size<DValue>) throws -> AtlasImage {
        let atlas = imageManager.atlas
        let subTexture = try atlas.saveBlankImage(size)
        let targetImage = AtlasImage(texture: subTexture, atlas: atlas)

        // Register the blank target region as a resource
        let resourceId: UInt64
        if let store = imageManager.resourceStore {
            resourceId = store.registerAtlasImage(targetImage)
        } else {
            // Fallback: use 0 (won't draw correctly but won't crash)
            resourceId = 0
        }

        let targetFrame = targetImage.sourceRect.to(Int16.self)
        let clipRect = clipRectAsInt()
        let z = nextZ()
        let rttAnimId: UInt64 = 0

        // Push sub-command buffer
        _rttStack.append([])

        // Execute drawing block — all draw calls go into the sub-command buffer
        let savedParent = currentParentAnimationId
        currentParentAnimationId = 0 // RTT sub-commands use absolute positions
        try block(self, targetFrame)
        currentParentAnimationId = savedParent

        // Pop sub-command buffer
        let subCommands = _rttStack.removeLast()

        let rttCmd = DrawCmdRTT(
            animationId: rttAnimId,
            parentAnimationId: currentParentAnimationId,
            targetResourceId: resourceId,
            targetRect: targetFrame.to(Int.self),
            z: z,
            clippingRect: clipRect,
            subCommands: subCommands
        )
        emit(.rtt(rttCmd))

        return targetImage
    }

    func drawAtlas(_ x:Int, _ y:Int, index:Int = 0) throws {
        // Not routing through command pipeline — debug/diagnostic only.
        // Silently no-op in the new pipeline.
    }

    // MARK: - Private helpers

    private func clipRectAsInt() -> Rect<Int> {
        guard let clip = currentClipRect else { return .zero }
        return clip.to(Int.self)
    }

    /// Look up the stable resource ID for an AtlasImage in the ResourceStore.
    private func resourceId(for image: AtlasImage) -> UInt64? {
        guard let store = imageManager.resourceStore else { return nil }
        // Scan _idImageCache for this AtlasImage instance
        for (id, cached) in store._idImageCache {
            if cached === image {
                return id
            }
        }
        // Not yet registered — register it now (eager fallback)
        let id = store.registerAtlasImage(image)
        return id
    }
}

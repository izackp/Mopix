//
//  UICommandContext.swift
//  GameEngine
//
//  Routes UI rendering through the RendererClient command pipeline.
//  This class emits DrawCmd values through IDraw and does NOT hold ImageManager.
//

import Foundation
import SDL2
import SDL2Swift

// MARK: - Protocols

/// Provides font objects for text rendering. ImageManager conforms to this.
/// UICommandContext depends on this protocol rather than ImageManager directly,
/// keeping the client side free of server-side resource management.
public protocol IFontProvider {
    func fetchFont(desc: FontDesc) throws -> Font?
}

// MARK: - UICommandContext

/// Command-pipeline UI draw context. Emits DrawCmd values through IDraw.
/// Used by View and its subclasses when routing UI through RendererClient.
public class UICommandContext {

    public init(client: IDraw, fontProvider: IFontProvider) {
        self.client = client
        self.fontProvider = fontProvider
        self.rttAllocator = rttAllocator
    }

    let client: IDraw
    public let fontProvider: IFontProvider

    var currentClipRect: Rect<DValue>? = nil
    var currentParentAnimationId: UInt64 = 0
    var currentZ: Int = 0

    private var _rttStack: [[DrawCmd]] = []

    func fetchFont(_ fontDesc: FontDesc) throws -> Font {
        guard let font = try fontProvider.fetchFont(desc: fontDesc) else {
            throw GenericError("No font for desc: \(fontDesc.family)")
        }
        return font
    }

    // MARK: - Command emission

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

    func setClipRect(_ frame: Rect<DValue>?) throws {
        currentClipRect = frame
    }

    // MARK: - Draw methods

    func drawSquare(_ dest: Rect<Int16>, _ color: SDLColor, _ alpha: Float = 1) throws {
        let clipRect = clipRectAsInt()
        let cmd = DrawCmd(
            animationId: 0,
            parentAnimationId: currentParentAnimationId,
            dest: dest.to(Int.self),
            color: color,
            alpha: alpha,
            z: nextZ(),
            rotation: 0,
            rotationPoint: .zero,
            clippingRect: clipRect,
            flip: [],
            time: 0,
            type: .fill
        )
        emit(cmd)
    }


    func drawText(_ text: Substring, _ font: Font, _ pos: Point<Int16>, _ color: SDLColor, _ alpha: Float = 1, spacing: Int = 0) throws {
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
                let cmd = DrawCmd(
                    animationId: 0,
                    parentAnimationId: currentParentAnimationId,
                    dest: dest.to(Int.self),
                    color: color,
                    alpha: alpha,
                    z: nextZ(),
                    rotation: 0,
                    rotationPoint: .zero,
                    clippingRect: clipRect,
                    flip: [],
                    time: 0,
                    type: .image(resourceId: resourceId)
                )
                emit(cmd)
                dest.x += Int16(metrics.advance) + Int16(spacing)
            } catch {
                print("Error couldn't draw character '\(c)': \(error.localizedDescription)")
            }
        }
    }

    func drawTextLine(_ text: ArraySlice<RenderableCharacter>, _ pos: Point<Int16>, _ alpha: Float = 1) throws {
        var dest = Rect<Int16>(x: pos.x, y: pos.y, width: 0, height: 0)
        for c in text {
            dest.width = Int16(c.size.width)
            dest.height = Int16(c.size.height)

            if let bgColor = c.background {
                try drawSquare(dest, bgColor.sdlColor())
            }

            if let image = c.img {
                dest.height = Int16(image.size.height)
                guard let resourceId = image.resourceId else {
                    dest.x += Int16(c.size.width)
                    continue
                }
                let clipRect = clipRectAsInt()
                let cmd = DrawCmd(
                    animationId: 0,
                    parentAnimationId: currentParentAnimationId,
                    dest: dest.to(Int.self),
                    color: .white,
                    alpha: alpha,
                    z: nextZ(),
                    rotation: 0,
                    rotationPoint: .zero,
                    clippingRect: clipRect,
                    flip: [],
                    time: 0,
                    type: .image(resourceId: resourceId)
                )
                emit(cmd)
            }
            dest.x += Int16(c.size.width)
        }
    }

    func createAndDrawToTexture(_ block: (_ context: UICommandContext, _ frame: Rect<DValue>) throws -> (), size: Size<DValue>) throws -> AtlasImage {
        guard let allocator = rttAllocator else {
            throw GenericError("UICommandContext: no IRTTAllocator — cannot createAndDrawToTexture")
        }
        let targetImage = try allocator.allocate(size: size)
        let targetFrame = targetImage.sourceRect.to(Int16.self)
        let clipRect = clipRectAsInt()
        let z = nextZ()

        _rttStack.append([])

        let savedParent = currentParentAnimationId
        currentParentAnimationId = 0
        try block(self, targetFrame)
        currentParentAnimationId = savedParent

        _ = _rttStack.removeLast()

        guard let resourceId = targetImage.resourceId else {
            throw GenericError("UICommandContext: allocated AtlasImage has no resourceId")
        }

        let cmd = DrawCmd(
            animationId: 0,
            parentAnimationId: currentParentAnimationId,
            dest: targetFrame.to(Int.self),
            color: .white,
            alpha: 1,
            z: z,
            rotation: 0,
            rotationPoint: .zero,
            clippingRect: clipRect,
            flip: [],
            time: 0,
            type: .rtt
        )
        _ = resourceId  // registered; RTT rendering is a stub
        emit(cmd)
        return targetImage
    }

    func drawAtlas(_ x: Int, _ y: Int, index: Int = 0) throws {
        // Debug/diagnostic only — no-op in the command pipeline.
    }

    // MARK: - Private

    private func clipRectAsInt() -> Rect<Int> {
        guard let clip = currentClipRect else { return .zero }
        return clip.to(Int.self)
    }
}

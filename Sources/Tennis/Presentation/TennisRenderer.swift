import Foundation
import GameEngine
import SDL2Swift

struct TennisPalette {
    var canvas: SDLColor; var panel: SDLColor; var primary: SDLColor; var secondary: SDLColor
    var human: SDLColor; var cpu: SDLColor; var ball: SDLColor
    var hardCourt: SDLColor; var clayCourt: SDLColor; var grassCourt: SDLColor
    var attention: SDLColor; var impact: SDLColor

    static var approved: TennisPalette {
        return TennisPalette(canvas: SDLColor(rawValue: 0x10182AFF), panel: SDLColor(rawValue: 0x1B2943FF), primary: SDLColor(rawValue: 0xFFF1C7FF), secondary: SDLColor(rawValue: 0xB8C4D6FF), human: SDLColor(rawValue: 0xF5C451FF), cpu: SDLColor(rawValue: 0xEC6A61FF), ball: SDLColor(rawValue: 0xFFFBEAFF), hardCourt: SDLColor(rawValue: 0x3D93C7FF), clayCourt: SDLColor(rawValue: 0xB9684DFF), grassCourt: SDLColor(rawValue: 0x4D9B65FF), attention: SDLColor(rawValue: 0xE85D5DFF), impact: SDLColor(rawValue: 0xFFF1C7FF))
    }
    func courtColor(for surface: TennisSurface) -> SDLColor { surface == .hard ? hardCourt : (surface == .clay ? clayCourt : grassCourt) }
    func playerColor(for side: TennisSide) -> SDLColor { side == .human ? human : cpu }
}

/// Build-time-only camera parameters (GAME-19 v2). Not player-facing; no runtime camera control.
/// `.approved` reproduces the spec's fixed trapezoid corners: far (53,0)-(187,0), near (43,126)-(197,126).
struct TennisCameraPreset {
    var heightAboveCourt: Float
    var pitchDegrees: Float
    var horizontalOffset: Float

    static var approved: TennisCameraPreset {
        TennisCameraPreset(heightAboveCourt: 773.85, pitchDegrees: 50.26769712804423, horizontalOffset: 0)
    }
}

/// Sole world-to-screen projection (GAME-19 v2). Derives the fixed court trapezoid corners from
/// a `TennisCameraPreset` via a simple ground-plane pinhole model, then `worldToScreen(_:)` is the
/// one projection rule for court fill/border, net, serve box outlines, center lines, baseline
/// marks, players, and ball alike. World X `16...144` (center 80) maps symmetrically around
/// screen X 120; world Y `24...120` (depth) maps linearly to screen Y `0...126`.
struct TennisCourtProjection {
    let farLeft: Point<Int>
    let farRight: Point<Int>
    let nearLeft: Point<Int>
    let nearRight: Point<Int>

    private let farHalfWidth: Double
    private let nearHalfWidth: Double
    private let farCenterX: Double
    private let nearCenterX: Double

    init(camera: TennisCameraPreset) {
        let courtWorldHalfWidth = 64.0
        let courtWorldDepth = 96.0
        let screenCenterX = 120.0
        let tanPitch = tan(Double(camera.pitchDegrees) * .pi / 180)
        let nearHalfWidth = courtWorldHalfWidth * tanPitch
        let groundDistanceNear = Double(camera.heightAboveCourt) / tanPitch
        let groundDistanceFar = groundDistanceNear + courtWorldDepth
        let farHalfWidth = (Double(camera.heightAboveCourt) * courtWorldHalfWidth) / groundDistanceFar
        let nearCenterX = screenCenterX
        let farCenterX = screenCenterX + Double(camera.horizontalOffset)

        self.nearHalfWidth = nearHalfWidth
        self.farHalfWidth = farHalfWidth
        self.nearCenterX = nearCenterX
        self.farCenterX = farCenterX
        self.farLeft = Point(Int((farCenterX - farHalfWidth).rounded()), 0)
        self.farRight = Point(Int((farCenterX + farHalfWidth).rounded()), 0)
        self.nearLeft = Point(Int((nearCenterX - nearHalfWidth).rounded()), 126)
        self.nearRight = Point(Int((nearCenterX + nearHalfWidth).rounded()), 126)
    }

    func worldToScreen(_ point: TennisPoint) -> Point<Int> {
        let depthFraction = (Double(point.y) - 24.0) / 96.0
        let halfWidth = farHalfWidth + (nearHalfWidth - farHalfWidth) * depthFraction
        let centerX = farCenterX + (nearCenterX - farCenterX) * depthFraction
        let worldXFraction = (Double(point.x) - 80.0) / 64.0
        let screenX = centerX + worldXFraction * halfWidth
        let screenY = depthFraction * 126.0
        return Point(Int(screenX.rounded()), Int(screenY.rounded()))
    }
}

final class TennisRenderer {
    static let screenWidth: Int = 240
    static let screenHeight: Int = 160

    private var fontHandle: UInt64?
    private let fontURL: VDUrl
    private let palette: TennisPalette
    private let projection: TennisCourtProjection

    init(fontURL: VDUrl) { self.fontURL = fontURL; self.palette = .approved; self.projection = TennisCourtProjection(camera: .approved) }

    func loadResources(using client: DisplayClient) async throws {
        let body = try await client.loadResource(url: fontURL, kind: .font)
        guard case let .font(handle, _) = body else { throw GenericError("Tennis font resource response was not a font for \(fontURL.absoluteString)") }
        fontHandle = handle
    }

    func draw(flow: TennisFlowState, match: TennisMatchSnapshot?, presentation: TennisPresentationState, humanServeBox: TennisRect, cpuServeBox: TennisRect, using renderer: DisplayRenderClient) throws {
        renderer.drawCmd(DrawCmd(animationId: 1, parentAnimationId: 0, dest: Rect(x: 0, y: 0, width: Self.screenWidth, height: Self.screenHeight), color: palette.canvas, alpha: 1, z: -10, rotation: 0, rotationPoint: .zero, clippingRect: .zero, flip: [], time: 0, type: .rect(filled: true)))
        switch flow.screen {
        case .title: try drawTitle(using: renderer)
        case .surfaceSelect: try drawSurfaceSelect(flow: flow, using: renderer)
        case .match: if let match { try drawMatch(snapshot: match, presentation: presentation, humanServeBox: humanServeBox, cpuServeBox: cpuServeBox, using: renderer) }
        case .result:
            try drawResult(flow: flow, using: renderer)
            drawCues(presentation, using: renderer)
        }
        try drawKeyboardFocusCue(flow: flow, using: renderer)
    }

    private func drawTitle(using renderer: DisplayRenderClient) throws {
        try drawText("TENNIS", at: TennisPoint(x: 48, y: 40), color: palette.primary, using: renderer)
        drawIdentityMark(for: .human, at: TennisPoint(x: 42, y: 47), using: renderer)
        drawIdentityMark(for: .cpu, at: TennisPoint(x: 114, y: 47), using: renderer)
        try drawText("PRESS A", at: TennisPoint(x: 48, y: 88), color: palette.primary, using: renderer)
    }

    private func drawSurfaceSelect(flow: TennisFlowState, using renderer: DisplayRenderClient) throws {
        try drawText("SURFACE", at: TennisPoint(x: 48, y: 8), color: palette.primary, using: renderer)
        let surfaces = Array(TennisSurface.allCases)
        for (index, surface) in surfaces.enumerated() {
            try drawSurfaceOption(surface, selected: surface == flow.highlightedSurface, in: Rect(x: 8 + index * 50, y: 34, width: 44, height: 60), using: renderer)
        }
        try drawText("LEFT / RIGHT / A", at: TennisPoint(x: 32, y: 124), color: palette.secondary, using: renderer)
    }

    private func drawSurfaceOption(_ surface: TennisSurface, selected: Bool, in rect: Rect<Int>, using renderer: DisplayRenderClient) throws {
        renderer.drawCmd(DrawCmd(animationId: UInt64(rect.x * 1000 + rect.y), parentAnimationId: 0, dest: rect, color: palette.courtColor(for: surface), alpha: 1, z: 0, rotation: 0, rotationPoint: .zero, clippingRect: .zero, flip: [], time: 0, type: .rect(filled: true)))
        drawSurfacePattern(surface, in: rect, using: renderer)
        if selected {
            renderer.drawCmd(DrawCmd(animationId: UInt64(rect.x * 1000 + rect.y + 1), parentAnimationId: 0, dest: rect, color: palette.primary, alpha: 1, z: 4, rotation: 0, rotationPoint: .zero, clippingRect: .zero, flip: [], time: 0, type: .rect(filled: false)))
            for (offset, width) in [(0, 1), (1, 3), (2, 1)] { renderer.drawCmd(DrawCmd(animationId: UInt64(rect.x * 1000 + rect.y + offset + 2), parentAnimationId: 0, dest: Rect(x: rect.x + 5 - width / 2, y: rect.y + 4 + offset, width: width, height: 1), color: palette.primary, alpha: 1, z: 5, rotation: 0, rotationPoint: .zero, clippingRect: .zero, flip: [], time: 0, type: .rect(filled: true))) }
        }
        try drawText(String(describing: surface).uppercased(), at: TennisPoint(x: rect.x + 4, y: 100), color: palette.primary, using: renderer)
    }

    private func drawMatch(snapshot: TennisMatchSnapshot, presentation: TennisPresentationState, humanServeBox: TennisRect, cpuServeBox: TennisRect, using renderer: DisplayRenderClient) throws {
        try drawHUD(snapshot: snapshot, using: renderer)
        if snapshot.surface == .grass { drawGrassCourt(using: renderer) } else { drawCourt(surface: snapshot.surface, using: renderer) }
        drawServeBoxOutlines(humanServeBox: humanServeBox, cpuServeBox: cpuServeBox, using: renderer)
        drawCenterServiceLines(humanServeBox: humanServeBox, cpuServeBox: cpuServeBox, using: renderer)
        drawBaselineCenterMarks(using: renderer)
        // Near-side entities are drawn before the net, far-side after; actual occlusion is z-order
        // driven (bodyZ 2/3 near vs 5/6 far straddling the net's z:4), see drawPlayer/drawGrassPlayerSilhouette.
        drawPlayersAndBall(snapshot: snapshot, presentation: presentation, courtEnd: .near, using: renderer)
        drawNet(using: renderer)
        drawPlayersAndBall(snapshot: snapshot, presentation: presentation, courtEnd: .far, using: renderer)
        drawCues(presentation, using: renderer)
        if presentation.cues.contains(where: { $0.kind == .scoreOverlay }) { try drawScoreOverlay(snapshot: snapshot, presentation: presentation, using: renderer) }
    }

    /// Shown for the fixed 2s post-point window (owned by the `.scoreOverlay` cue's lifetime).
    /// Reads the score straight from the snapshot rather than the cue, and sits below the HUD/fault
    /// callout band (y 2-34) so it never occludes required HUD or fault text per VIBE-7.
    private func drawScoreOverlay(snapshot: TennisMatchSnapshot, presentation: TennisPresentationState, using renderer: DisplayRenderClient) throws {
        try drawText("H \(snapshot.score.human)   C \(snapshot.score.cpu)", at: TennisPoint(x: 56, y: 60), color: palette.primary, using: renderer)
    }

    private func drawResult(flow: TennisFlowState, using renderer: DisplayRenderClient) throws {
        if let winner = flow.result { drawIdentityMark(for: winner, at: TennisPoint(x: 40, y: 58), using: renderer) }
        try drawText(flow.result == .human ? "YOU WIN" : "CPU WINS", at: TennisPoint(x: 52, y: 52), color: palette.primary, using: renderer)
        try drawText("PRESS A", at: TennisPoint(x: 48, y: 84), color: palette.primary, using: renderer)
    }

    /// Placed per-screen so it never overlaps required text, HUD/score, or fault callouts:
    /// title/result use the gap below their "PRESS A" line, match uses the strip below the
    /// court, and surface-select uses the gap between the surface tiles and its footer text.
    private func drawKeyboardFocusCue(flow: TennisFlowState, using renderer: DisplayRenderClient) throws {
        guard !(flow.windowActive && flow.keyboardFocused) else { return }
        let y: Int
        switch flow.screen {
        case .title: y = 120
        case .surfaceSelect: y = 100
        case .match: y = 128
        case .result: y = 112
        }
        try drawText("CLICK GAME FOR KEYS", at: TennisPoint(x: 20, y: y), color: palette.primary, using: renderer)
    }

    /// Fills the projected court trapezoid one screen row at a time (left/right edges reprojected
    /// per row from the world sidelines, world X 16/144), then draws the 4 projected corner edges
    /// as the border. Shared shape logic duplicated between drawCourt/drawGrassCourt (no shared
    /// private method for it — keeps both bodies within this class's declared method surface).
    private func drawCourt(surface: TennisSurface, using renderer: DisplayRenderClient) {
        for screenY in 0...126 {
            let worldY = 24.0 + Double(screenY) / 126.0 * 96.0
            let left = projection.worldToScreen(TennisPoint(x: 16, y: Int(worldY.rounded()))).x
            let right = projection.worldToScreen(TennisPoint(x: 144, y: Int(worldY.rounded()))).x
            renderer.drawCmd(DrawCmd(animationId: UInt64(20_000 + screenY), parentAnimationId: 0, dest: Rect(x: left, y: screenY, width: max(1, right - left), height: 1), color: palette.courtColor(for: surface), alpha: 1, z: 0, rotation: 0, rotationPoint: .zero, clippingRect: .zero, flip: [], time: 0, type: .rect(filled: true)))
        }
        for (index, edge) in [(projection.farLeft, projection.farRight), (projection.nearLeft, projection.nearRight), (projection.farLeft, projection.nearLeft), (projection.farRight, projection.nearRight)].enumerated() {
            renderer.drawCmd(DrawCmd(animationId: UInt64(20_200 + index), parentAnimationId: 0, dest: Rect(x: edge.0.x, y: edge.0.y, width: 1, height: 1), color: palette.primary, alpha: 1, z: 4, rotation: 0, rotationPoint: .zero, clippingRect: .zero, flip: [], time: 0, type: .line(to: Point(edge.1.x - edge.0.x, edge.1.y - edge.0.y), thickness: 1)))
        }
        let boundingBox = Rect(x: min(projection.farLeft.x, projection.nearLeft.x), y: 0, width: max(projection.farRight.x, projection.nearRight.x) - min(projection.farLeft.x, projection.nearLeft.x), height: 126)
        drawSurfacePattern(surface, in: boundingBox, using: renderer)
    }

    /// The Grass proof court reuses the same trapezoid fill/border as Hard/Clay (GAME-19 v2: one
    /// projection rule for the court surface across all surfaces); depth bands are a cosmetic
    /// overlay sized to the trapezoid's bounding box, running far-to-near with decreasing lane-mark
    /// spacing/increasing length, and (per GAME-19 v2's no-depth-scaling rule) are not themselves projected.
    private func drawGrassCourt(using renderer: DisplayRenderClient) {
        for screenY in 0...126 {
            let worldY = 24.0 + Double(screenY) / 126.0 * 96.0
            let left = projection.worldToScreen(TennisPoint(x: 16, y: Int(worldY.rounded()))).x
            let right = projection.worldToScreen(TennisPoint(x: 144, y: Int(worldY.rounded()))).x
            renderer.drawCmd(DrawCmd(animationId: UInt64(60_000 + screenY), parentAnimationId: 0, dest: Rect(x: left, y: screenY, width: max(1, right - left), height: 1), color: palette.grassCourt, alpha: 1, z: 0, rotation: 0, rotationPoint: .zero, clippingRect: .zero, flip: [], time: 0, type: .rect(filled: true)))
        }
        for (index, edge) in [(projection.farLeft, projection.farRight), (projection.nearLeft, projection.nearRight), (projection.farLeft, projection.nearLeft), (projection.farRight, projection.nearRight)].enumerated() {
            renderer.drawCmd(DrawCmd(animationId: UInt64(60_200 + index), parentAnimationId: 0, dest: Rect(x: edge.0.x, y: edge.0.y, width: 1, height: 1), color: palette.primary, alpha: 1, z: 4, rotation: 0, rotationPoint: .zero, clippingRect: .zero, flip: [], time: 0, type: .line(to: Point(edge.1.x - edge.0.x, edge.1.y - edge.0.y), thickness: 1)))
        }
        let boundingBox = Rect(x: min(projection.farLeft.x, projection.nearLeft.x), y: 0, width: max(projection.farRight.x, projection.nearRight.x) - min(projection.farLeft.x, projection.nearLeft.x), height: 126)
        drawGrassDepthBand(Rect(x: boundingBox.x, y: boundingBox.y, width: boundingBox.width, height: boundingBox.height / 3), markLength: 2, spacing: 8, using: renderer)
        drawGrassDepthBand(Rect(x: boundingBox.x, y: boundingBox.y + boundingBox.height / 3, width: boundingBox.width, height: boundingBox.height / 3), markLength: 4, spacing: 6, using: renderer)
        drawGrassDepthBand(Rect(x: boundingBox.x, y: boundingBox.y + 2 * boundingBox.height / 3, width: boundingBox.width, height: boundingBox.height / 3), markLength: 6, spacing: 4, using: renderer)
    }

    private func drawGrassDepthBand(_ rect: Rect<Int>, markLength: Int, spacing: Int, using renderer: DisplayRenderClient) {
        for x in stride(from: rect.x + 2, through: rect.x + rect.width - markLength - 2, by: spacing) {
            for y in stride(from: rect.y + 2, through: rect.y + rect.height - 3, by: spacing) {
                renderer.drawCmd(DrawCmd(animationId: UInt64(abs(x * 1000 + y)), parentAnimationId: 0, dest: Rect(x: x, y: y, width: markLength, height: 1), color: palette.canvas, alpha: 1, z: 1, rotation: 0, rotationPoint: .zero, clippingRect: .zero, flip: [], time: 0, type: .line(to: Point(markLength, 0), thickness: 1)))
            }
        }
    }

    /// Fixed screen band, bottom edge at screen Y 58, per GAME-19 v2 — a hand-placed focal line
    /// that takes precedence over `worldToScreen`'s row interpolation at that one row (left/right
    /// edges are reprojected from the world sidelines at the equivalent depth, matching the
    /// trapezoid's width there, rather than derived from the world net plane y=72 directly).
    /// Shared by all three surfaces (Hard/Clay/Grass) — replaces the old Grass-only `drawGrassNet`.
    private func drawNet(using renderer: DisplayRenderClient) {
        let netBottomY = 58; let netHeight = 4; let netTop = netBottomY - netHeight
        let postWidth = 4; let postExtend = 8
        let rowWorldY = Int((24.0 + Double(netBottomY) / 126.0 * 96.0).rounded())
        let left = projection.worldToScreen(TennisPoint(x: 16, y: rowWorldY)).x
        let right = projection.worldToScreen(TennisPoint(x: 144, y: rowWorldY)).x
        renderer.drawCmd(DrawCmd(animationId: 62, parentAnimationId: 0, dest: Rect(x: left, y: netTop - postExtend, width: postWidth, height: netHeight + postExtend * 2), color: palette.canvas, alpha: 1, z: 4, rotation: 0, rotationPoint: .zero, clippingRect: .zero, flip: [], time: 0, type: .rect(filled: true)))
        renderer.drawCmd(DrawCmd(animationId: 63, parentAnimationId: 0, dest: Rect(x: right - postWidth, y: netTop - postExtend, width: postWidth, height: netHeight + postExtend * 2), color: palette.canvas, alpha: 1, z: 4, rotation: 0, rotationPoint: .zero, clippingRect: .zero, flip: [], time: 0, type: .rect(filled: true)))
        renderer.drawCmd(DrawCmd(animationId: 64, parentAnimationId: 0, dest: Rect(x: left, y: netTop, width: right - left, height: netHeight), color: palette.canvas, alpha: 1, z: 4, rotation: 0, rotationPoint: .zero, clippingRect: .zero, flip: [], time: 0, type: .rect(filled: true)))
        for (rowIndex, y) in stride(from: netTop, to: netTop + netHeight, by: 2).enumerated() {
            for x in stride(from: left + postWidth + (rowIndex % 2), to: right - postWidth, by: 2) {
                renderer.drawCmd(DrawCmd(animationId: UInt64(abs(x * 1000 + y + 65)), parentAnimationId: 0, dest: Rect(x: x, y: y, width: 1, height: 1), color: palette.primary, alpha: 1, z: 4, rotation: 0, rotationPoint: .zero, clippingRect: .zero, flip: [], time: 0, type: .rect(filled: true)))
            }
        }
    }

    /// Draws both GAME-3 serve target box outlines at their existing world rects, projected as
    /// 4-edge quads (not axis-aligned rects on screen, since each edge sits at a different depth).
    private func drawServeBoxOutlines(humanServeBox: TennisRect, cpuServeBox: TennisRect, using renderer: DisplayRenderClient) {
        for (index, box) in [humanServeBox, cpuServeBox].enumerated() {
            let topLeft = projection.worldToScreen(TennisPoint(x: box.minX, y: box.minY))
            let topRight = projection.worldToScreen(TennisPoint(x: box.maxX, y: box.minY))
            let bottomLeft = projection.worldToScreen(TennisPoint(x: box.minX, y: box.maxY))
            let bottomRight = projection.worldToScreen(TennisPoint(x: box.maxX, y: box.maxY))
            for (edgeIndex, edge) in [(topLeft, topRight), (topRight, bottomRight), (bottomRight, bottomLeft), (bottomLeft, topLeft)].enumerated() {
                renderer.drawCmd(DrawCmd(animationId: UInt64(70_000 + index * 10 + edgeIndex), parentAnimationId: 0, dest: Rect(x: edge.0.x, y: edge.0.y, width: 1, height: 1), color: palette.secondary, alpha: 1, z: 2, rotation: 0, rotationPoint: .zero, clippingRect: .zero, flip: [], time: 0, type: .line(to: Point(edge.1.x - edge.0.x, edge.1.y - edge.0.y), thickness: 1)))
            }
        }
    }

    /// Two segments only — net plane (world Y 72) to each serve box's outer (farthest-from-net)
    /// edge — not full court depth. World X 80 always projects to screen X 120 (GAME-19 v2), so
    /// both segments render as straight vertical lines.
    private func drawCenterServiceLines(humanServeBox: TennisRect, cpuServeBox: TennisRect, using renderer: DisplayRenderClient) {
        for (index, box) in [humanServeBox, cpuServeBox].enumerated() {
            let outerY = abs(box.minY - 72) > abs(box.maxY - 72) ? box.minY : box.maxY
            let netPoint = projection.worldToScreen(TennisPoint(x: 80, y: 72))
            let outerPoint = projection.worldToScreen(TennisPoint(x: 80, y: outerY))
            renderer.drawCmd(DrawCmd(animationId: UInt64(70_100 + index), parentAnimationId: 0, dest: Rect(x: netPoint.x, y: netPoint.y, width: 1, height: 1), color: palette.primary, alpha: 1, z: 2, rotation: 0, rotationPoint: .zero, clippingRect: .zero, flip: [], time: 0, type: .line(to: Point(outerPoint.x - netPoint.x, outerPoint.y - netPoint.y), thickness: 1)))
        }
    }

    /// Short mark at the midpoint of each baseline (world Y 24 and Y 120), world X 80.
    private func drawBaselineCenterMarks(using renderer: DisplayRenderClient) {
        for (index, baselineY) in [24, 120].enumerated() {
            let point = projection.worldToScreen(TennisPoint(x: 80, y: baselineY))
            let markInward = baselineY == 24 ? 4 : -4
            renderer.drawCmd(DrawCmd(animationId: UInt64(70_110 + index), parentAnimationId: 0, dest: Rect(x: point.x, y: point.y, width: 1, height: 1), color: palette.primary, alpha: 1, z: 2, rotation: 0, rotationPoint: .zero, clippingRect: .zero, flip: [], time: 0, type: .line(to: Point(0, markInward), thickness: 1)))
        }
    }

    private func drawSurfacePattern(_ surface: TennisSurface, in rect: Rect<Int>, using renderer: DisplayRenderClient) {
        let pattern = surface == .hard ? palette.primary : palette.canvas
        switch surface {
        case .hard:
            for x in stride(from: rect.x + 3, through: rect.x + rect.width - 4, by: 10) { for y in stride(from: rect.y + 3, through: rect.y + rect.height - 7, by: 9) { renderer.drawCmd(DrawCmd(animationId: UInt64(x * 1000 + y), parentAnimationId: 0, dest: Rect(x: x, y: y, width: 1, height: 5), color: pattern, alpha: 1, z: 1, rotation: 0, rotationPoint: .zero, clippingRect: .zero, flip: [], time: 0, type: .line(to: Point(0, 5), thickness: 1))) } }
        case .clay:
            for x in stride(from: rect.x + 2, through: rect.x + rect.width - 7, by: 10) { for y in stride(from: rect.y + 2, through: rect.y + rect.height - 7, by: 8) { renderer.drawCmd(DrawCmd(animationId: UInt64(abs(x * 1000 + y)), parentAnimationId: 0, dest: Rect(x: x, y: y, width: 5, height: 5), color: pattern, alpha: 1, z: 1, rotation: 0, rotationPoint: .zero, clippingRect: .zero, flip: [], time: 0, type: .line(to: Point(5, 5), thickness: 1))) } }
        case .grass:
            for x in stride(from: rect.x + 3, through: rect.x + rect.width - 8, by: 10) { for y in stride(from: rect.y + 3, through: rect.y + rect.height - 4, by: 9) { renderer.drawCmd(DrawCmd(animationId: UInt64(rect.x * 1000 + y + x), parentAnimationId: 0, dest: Rect(x: x, y: y, width: 6, height: 1), color: pattern, alpha: 1, z: 1, rotation: 0, rotationPoint: .zero, clippingRect: .zero, flip: [], time: 0, type: .line(to: Point(6, 0), thickness: 1))) } }
        }
    }

    private func drawHUD(snapshot: TennisMatchSnapshot, using renderer: DisplayRenderClient) throws {
        renderer.drawCmd(DrawCmd(animationId: 30, parentAnimationId: 0, dest: Rect(x: 40, y: 2, width: 80, height: 18), color: palette.panel, alpha: 1, z: 3, rotation: 0, rotationPoint: .zero, clippingRect: .zero, flip: [], time: 0, type: .rect(filled: true)))
        try drawText("H \(snapshot.score.human)   C \(snapshot.score.cpu)", at: TennisPoint(x: 48, y: 5), color: palette.primary, using: renderer)
    }

    /// `courtEnd` filters which side's player/ball are emitted, so the Grass composition can
    /// interleave near-side entities, the net, then far-side entities for correct depth ordering.
    /// `nil` draws everything (unchanged Hard/Clay behavior).
    private func drawPlayersAndBall(snapshot: TennisMatchSnapshot, presentation: TennisPresentationState, courtEnd: TennisCourtEnd?, using renderer: DisplayRenderClient) {
        for side in [TennisSide.human, .cpu] {
            guard let player = snapshot.players[side], let motion = presentation.players[side] else { continue }
            guard courtEnd == nil || player.courtEnd == courtEnd else { continue }
            drawPlayer(side: side, player: player, presentation: motion, surface: snapshot.surface, using: renderer)
        }
        if let ball = snapshot.ball {
            let ballCourtEnd: TennisCourtEnd = ball.position.y < 72 ? .far : .near
            if courtEnd == nil || ballCourtEnd == courtEnd { drawBall(flight: ball, presentation: presentation.ball, using: renderer) }
        }
    }

    private func drawPlayer(side: TennisSide, player: TennisPlayerState, presentation: TennisPlayerPresentation, surface: TennisSurface, using renderer: DisplayRenderClient) {
        if surface == .grass { drawGrassPlayerSilhouette(side: side, player: player, presentation: presentation, using: renderer); return }
        let phase = Int((presentation.elapsedMilliseconds / 400) % 2)
        let moving = presentation.direction.x != 0 || presentation.direction.y != 0
        let torsoXOffset = presentation.motion == .followThrough ? (presentation.direction.x >= 0 ? 1 : -1) : (presentation.motion == .serveWindup ? (presentation.direction.x >= 0 ? -1 : 1) : 0)
        let torsoYOffset = presentation.motion == .idle && phase == 1 ? 1 : 0
        let worldTorso = TennisPoint(x: player.position.x + torsoXOffset, y: player.position.y + torsoYOffset)
        // Anchor position only moves per projection; sprite sizes below stay fixed (GAME-19 v2 non-goal).
        let projected = projection.worldToScreen(worldTorso)
        let torso = TennisPoint(x: projected.x, y: projected.y)
        let bodyZ = player.courtEnd == .near ? 2 : 5
        let racketZ = player.courtEnd == .near ? 3 : 6
        // Matches the net's z:4 straddling used by drawGrassPlayerSilhouette (the occlusion
        // reference per GAME-19 v2) rather than the shared `drawPoint` helper's fixed z:5.
        renderer.drawCmd(DrawCmd(animationId: UInt64(abs(torso.x * 1000 + torso.y + 30)), parentAnimationId: 0, dest: Rect(x: torso.x - 4, y: torso.y - 4, width: 8, height: 8), color: palette.playerColor(for: side), alpha: 1, z: bodyZ, rotation: 0, rotationPoint: .zero, clippingRect: .zero, flip: [], time: 0, type: .rect(filled: true)))
        drawIdentityMark(for: side, at: torso, using: renderer)
        let strideOffset = presentation.motion == .locomotion && moving ? (phase == 0 ? 2 : -2) : 0
        renderer.drawCmd(DrawCmd(animationId: UInt64(abs(torso.x * 1000 + torso.y + 31)), parentAnimationId: 0, dest: Rect(x: torso.x - 4 + strideOffset, y: torso.y + 4, width: 4, height: 1), color: palette.canvas, alpha: 1, z: bodyZ, rotation: 0, rotationPoint: .zero, clippingRect: .zero, flip: [], time: 0, type: .line(to: Point(4, 0), thickness: 1)))
        renderer.drawCmd(DrawCmd(animationId: UInt64(abs(torso.x * 1000 + torso.y + 33)), parentAnimationId: 0, dest: Rect(x: torso.x + 1 - strideOffset, y: torso.y + 4, width: 4, height: 1), color: palette.canvas, alpha: 1, z: bodyZ, rotation: 0, rotationPoint: .zero, clippingRect: .zero, flip: [], time: 0, type: .line(to: Point(4, 0), thickness: 1)))
        let chargeProgress = presentation.isChargeCapped ? 600 : min(600, presentation.elapsedMilliseconds)
        let followThroughAngle: Float = presentation.shot == .slice ? 30 : -30
        let racketAngle: Float = presentation.motion == .idle ? (phase == 1 ? 10 : 0) : (presentation.motion == .serveWindup ? 45 : (presentation.motion == .shotCharge ? -45 * Float(chargeProgress) / 600 : (presentation.motion == .followThrough ? followThroughAngle + 30 * Float(min(200, presentation.elapsedMilliseconds)) / 200 : 0)))
        let racketColor = presentation.impactElapsedMilliseconds == nil ? palette.primary : palette.impact
        renderer.drawCmd(DrawCmd(animationId: UInt64(abs(torso.x * 1000 + torso.y + 32)), parentAnimationId: 0, dest: Rect(x: torso.x, y: torso.y - 7, width: 1, height: 7), color: racketColor, alpha: 1, z: racketZ, rotation: racketAngle, rotationPoint: .zero, clippingRect: .zero, flip: [], time: 0, type: .line(to: Point(-3, -4), thickness: 1)))
    }

    private func drawGrassPlayerSilhouette(side: TennisSide, player: TennisPlayerState, presentation: TennisPlayerPresentation, using renderer: DisplayRenderClient) {
        let phase = Int((presentation.elapsedMilliseconds / 400) % 2)
        let moving = presentation.direction.x != 0 || presentation.direction.y != 0
        let torsoXOffset = presentation.motion == .followThrough ? (presentation.direction.x >= 0 ? 1 : -1) : (presentation.motion == .serveWindup ? (presentation.direction.x >= 0 ? -1 : 1) : 0)
        let torsoYOffset = presentation.motion == .idle && phase == 1 ? 1 : 0
        let worldTorso = TennisPoint(x: player.position.x + torsoXOffset, y: player.position.y + torsoYOffset)
        let projected = projection.worldToScreen(worldTorso)
        let torso = TennisPoint(x: projected.x, y: projected.y)
        // Below-net (z2) when near, above-net (z5) when far — matches the caller's near/net/far draw order.
        let bodyZ = player.courtEnd == .near ? 2 : 5
        let racketZ = player.courtEnd == .near ? 3 : 6
        let color = palette.playerColor(for: side)

        renderer.drawCmd(DrawCmd(animationId: UInt64(abs(torso.x * 1000 + torso.y + 50)), parentAnimationId: 0, dest: Rect(x: torso.x - 2, y: torso.y - 8, width: 4, height: 4), color: color, alpha: 1, z: bodyZ, rotation: 0, rotationPoint: .zero, clippingRect: .zero, flip: [], time: 0, type: .rect(filled: true)))
        renderer.drawCmd(DrawCmd(animationId: UInt64(abs(torso.x * 1000 + torso.y + 51)), parentAnimationId: 0, dest: Rect(x: torso.x - 5, y: torso.y - 4, width: 10, height: 8), color: color, alpha: 1, z: bodyZ, rotation: 0, rotationPoint: .zero, clippingRect: .zero, flip: [], time: 0, type: .rect(filled: true)))
        drawIdentityMark(for: side, at: torso, using: renderer)
        let strideOffset = presentation.motion == .locomotion && moving ? (phase == 0 ? 2 : -2) : 0
        renderer.drawCmd(DrawCmd(animationId: UInt64(abs(torso.x * 1000 + torso.y + 52)), parentAnimationId: 0, dest: Rect(x: torso.x - 6 + strideOffset, y: torso.y + 4, width: 5, height: 6), color: palette.canvas, alpha: 1, z: bodyZ, rotation: 0, rotationPoint: .zero, clippingRect: .zero, flip: [], time: 0, type: .rect(filled: true)))
        renderer.drawCmd(DrawCmd(animationId: UInt64(abs(torso.x * 1000 + torso.y + 53)), parentAnimationId: 0, dest: Rect(x: torso.x + 1 - strideOffset, y: torso.y + 4, width: 5, height: 6), color: palette.canvas, alpha: 1, z: bodyZ, rotation: 0, rotationPoint: .zero, clippingRect: .zero, flip: [], time: 0, type: .rect(filled: true)))
        let chargeProgress = presentation.isChargeCapped ? 600 : min(600, presentation.elapsedMilliseconds)
        let followThroughAngle: Float = presentation.shot == .slice ? 30 : -30
        let racketAngle: Float = presentation.motion == .idle ? (phase == 1 ? 10 : 0) : (presentation.motion == .serveWindup ? 45 : (presentation.motion == .shotCharge ? -45 * Float(chargeProgress) / 600 : (presentation.motion == .followThrough ? followThroughAngle + 30 * Float(min(200, presentation.elapsedMilliseconds)) / 200 : 0)))
        let racketColor = presentation.impactElapsedMilliseconds == nil ? palette.primary : palette.impact
        renderer.drawCmd(DrawCmd(animationId: UInt64(abs(torso.x * 1000 + torso.y + 54)), parentAnimationId: 0, dest: Rect(x: torso.x, y: torso.y - 9, width: 1, height: 9), color: racketColor, alpha: 1, z: racketZ, rotation: racketAngle, rotationPoint: .zero, clippingRect: .zero, flip: [], time: 0, type: .line(to: Point(-4, -5), thickness: 1)))
    }

    private func drawBall(flight: TennisBallFlight, presentation: TennisBallPresentation?, using renderer: DisplayRenderClient) {
        let elapsed = flight.elapsedMilliseconds
        let duration = max(1, flight.contactToBounceMilliseconds)
        let progress = min(100, Int(elapsed * 100 / duration))
        // Height/Z stays a layered scalar on the flat world plane (unchanged), so the arc lift is
        // applied in screen space, after projecting the flat world X/Y position.
        let worldXY = flight.consecutiveGroundContacts > 0 ? flight.landing : TennisPoint(x: flight.origin.x + (flight.landing.x - flight.origin.x) * progress / 100, y: flight.origin.y + (flight.landing.y - flight.origin.y) * progress / 100)
        let arcOffset = flight.consecutiveGroundContacts > 0 ? 0 : flight.height * (progress <= 50 ? progress : 100 - progress) / 50
        let projectedXY = projection.worldToScreen(worldXY)
        let current = TennisPoint(x: projectedXY.x, y: projectedXY.y - arcOffset)
        let squash = presentation?.bounceElapsedMilliseconds != nil
        let contact = presentation?.contactElapsedMilliseconds != nil
        let impact = presentation?.contactElapsedMilliseconds != nil
        drawBallShadow(flight: flight, using: renderer)
        let horizontal = abs(flight.landing.x - flight.origin.x) >= abs(flight.landing.y - flight.origin.y)
        let width = squash ? 9 : ((contact || impact) && horizontal ? 9 : ((contact || impact) ? 5 : 5))
        let height = squash ? 5 : ((contact || impact) && horizontal ? 5 : ((contact || impact) ? 9 : 5))
        renderer.drawCmd(DrawCmd(animationId: UInt64(abs(current.x * 1000 + current.y + 34)), parentAnimationId: 0, dest: Rect(x: current.x - width / 2 - 1, y: current.y - height / 2 - 1, width: width + 2, height: height + 2), color: palette.canvas, alpha: 1, z: 5, rotation: 0, rotationPoint: .zero, clippingRect: .zero, flip: [], time: 0, type: .rect(filled: true)))
        renderer.drawCmd(DrawCmd(animationId: UInt64(abs(current.x * 1000 + current.y + 35)), parentAnimationId: 0, dest: Rect(x: current.x - width / 2, y: current.y - height / 2, width: width, height: height), color: palette.ball, alpha: 1, z: 6, rotation: 0, rotationPoint: .zero, clippingRect: .zero, flip: [], time: 0, type: .rect(filled: true)))
    }

    /// Stays pinned to the landing point while the ball itself arcs via its height offset in
    /// `drawBall`, so their on-screen separation grows through ascent and shrinks through descent.
    private func drawBallShadow(flight: TennisBallFlight, using renderer: DisplayRenderClient) {
        let projected = projection.worldToScreen(flight.landing)
        drawPoint(TennisPoint(x: projected.x, y: projected.y), size: 4, color: palette.canvas, using: renderer)
    }

    private func drawIdentityMark(for side: TennisSide, at point: TennisPoint, using renderer: DisplayRenderClient) {
        renderer.drawCmd(DrawCmd(animationId: UInt64(abs(point.x * 1000 + point.y + 7)), parentAnimationId: 0, dest: Rect(x: point.x, y: point.y, width: 1, height: 1), color: palette.canvas, alpha: 1, z: 7, rotation: 0, rotationPoint: .zero, clippingRect: .zero, flip: [], time: 0, type: .circle(radius: 4, filled: true)))
        if side == .human {
            for (offset, width) in [(0, 1), (1, 3), (2, 5), (3, 3), (4, 1)] { renderer.drawCmd(DrawCmd(animationId: UInt64(abs(point.x * 1000 + point.y + offset + 8)), parentAnimationId: 0, dest: Rect(x: point.x + 2 - width / 2, y: point.y - 2 + offset, width: width, height: 1), color: palette.primary, alpha: 1, z: 8, rotation: 0, rotationPoint: .zero, clippingRect: .zero, flip: [], time: 0, type: .rect(filled: true))) }
        } else {
            for (offset, width) in [(0, 1), (1, 3), (2, 5)] { renderer.drawCmd(DrawCmd(animationId: UInt64(abs(point.x * 1000 + point.y + offset + 10)), parentAnimationId: 0, dest: Rect(x: point.x + 2 - width / 2, y: point.y - 2 + offset, width: width, height: 1), color: palette.primary, alpha: 1, z: 8, rotation: 0, rotationPoint: .zero, clippingRect: .zero, flip: [], time: 0, type: .rect(filled: true))) }
        }
    }

    private func drawCues(_ state: TennisPresentationState, using renderer: DisplayRenderClient) {
        for cue in state.cues {
            let point = cue.position ?? TennisPoint(x: 80, y: 18)
            switch cue.kind {
            case .hardBounce:
                renderer.drawCmd(DrawCmd(animationId: UInt64(abs(point.x * 1000 + point.y + 40)), parentAnimationId: 0, dest: Rect(x: point.x, y: point.y, width: 1, height: 1), color: palette.impact, alpha: 1, z: 9, rotation: 0, rotationPoint: .zero, clippingRect: .zero, flip: [], time: 0, type: .circle(radius: 8, filled: false)))
            case .clayBounce:
                for offset in stride(from: -6, through: 6, by: 6) { renderer.drawCmd(DrawCmd(animationId: UInt64(abs(point.x * 1000 + point.y + offset + 41)), parentAnimationId: 0, dest: Rect(x: point.x + offset, y: point.y - 4, width: 5, height: 4), color: palette.clayCourt, alpha: 1, z: 9, rotation: 0, rotationPoint: .zero, clippingRect: .zero, flip: [], time: 0, type: .line(to: Point(5, 2), thickness: 1))) }
            case .grassBounce:
                renderer.drawCmd(DrawCmd(animationId: UInt64(abs(point.x * 1000 + point.y + 42)), parentAnimationId: 0, dest: Rect(x: point.x - 8, y: point.y + 3, width: 16, height: 1), color: palette.grassCourt, alpha: 1, z: 9, rotation: 0, rotationPoint: .zero, clippingRect: .zero, flip: [], time: 0, type: .line(to: Point(16, 0), thickness: 1)))
            case .smashFlash:
                renderer.drawCmd(DrawCmd(animationId: UInt64(abs(point.x * 1000 + point.y + 43)), parentAnimationId: 0, dest: Rect(x: point.x - 5, y: point.y - 5, width: 10, height: 10), color: palette.impact, alpha: 1, z: 9, rotation: 0, rotationPoint: .zero, clippingRect: .zero, flip: [], time: 0, type: .circle(radius: 5, filled: true)))
            case .smashStarburst:
                let expansion = 4 + min(4, Int(cue.elapsedMilliseconds * 4 / 100))
                for angle in [0, 45, 90, 135] { renderer.drawCmd(DrawCmd(animationId: UInt64(abs(point.x * 1000 + point.y + angle + 44)), parentAnimationId: 0, dest: Rect(x: point.x, y: point.y, width: 1, height: expansion), color: palette.impact, alpha: 1, z: 9, rotation: Float(angle), rotationPoint: .zero, clippingRect: .zero, flip: [], time: 0, type: .line(to: Point(0, expansion), thickness: 1))) }
            case .shotDirection:
                let direction: Point<Int>
                switch cue.shot {
                case .serve: direction = Point(0, -8)
                case .topspin: direction = Point(5, -5)
                case .slice: direction = Point(-5, -3)
                case .flat: direction = Point(8, 0)
                case .lob: direction = Point(3, -8)
                case .drop: direction = Point(-3, 3)
                case .smash: direction = Point(8, -6)
                case nil: direction = Point(4, 0)
                }
                renderer.drawCmd(DrawCmd(animationId: UInt64(abs(point.x * 1000 + point.y + 45)), parentAnimationId: 0, dest: Rect(x: point.x, y: point.y, width: 1, height: 1), color: palette.primary, alpha: 1, z: 9, rotation: 0, rotationPoint: .zero, clippingRect: .zero, flip: [], time: 0, type: .line(to: direction, thickness: 1)))
            case .landing:
                renderer.drawCmd(DrawCmd(animationId: UInt64(abs(point.x * 1000 + point.y + 44)), parentAnimationId: 0, dest: Rect(x: point.x, y: point.y, width: 1, height: 1), color: palette.primary, alpha: 1, z: 9, rotation: 0, rotationPoint: .zero, clippingRect: .zero, flip: [], time: 0, type: .circle(radius: cue.kind == .landing ? 6 : 3, filled: false)))
            case .chargeMeter, .chargeCap:
                renderer.drawCmd(DrawCmd(animationId: UInt64(abs(point.x * 1000 + point.y + 45)), parentAnimationId: 0, dest: Rect(x: point.x - 10, y: point.y - 10, width: cue.kind == .chargeCap ? 20 : 12, height: 2), color: palette.attention, alpha: 1, z: 9, rotation: 0, rotationPoint: .zero, clippingRect: .zero, flip: [], time: 0, type: .rect(filled: cue.kind == .chargeMeter)))
            case .faultCallout:
                if let fontHandle { renderer.drawCmd(DrawCmd(animationId: UInt64(abs(point.x * 1000 + point.y + 46)), parentAnimationId: 0, dest: Rect(x: 48, y: 18, width: 64, height: 16), color: palette.attention, alpha: 1, z: 10, rotation: 0, rotationPoint: .zero, clippingRect: .zero, flip: [], time: 0, type: .text(fontHandle: fontHandle, content: cue.callout.map { String(describing: $0).uppercased() } ?? "FAULT", size: 12, align: .left))) }
            case .serveAnticipation, .scoreOverlay: break
            }
        }
    }

    private func drawText(_ text: String, at point: TennisPoint, color: SDLColor, using renderer: DisplayRenderClient) throws {
        guard let fontHandle else { throw GenericError("Tennis text font is unavailable for content '\(text)'") }
        renderer.drawCmd(DrawCmd(animationId: UInt64(abs(point.x * 1000 + point.y + 10)), parentAnimationId: 0, dest: Rect(x: point.x, y: point.y, width: 100, height: 16), color: color, alpha: 1, z: 10, rotation: 0, rotationPoint: .zero, clippingRect: .zero, flip: [], time: 0, type: .text(fontHandle: fontHandle, content: text, size: 12, align: .left)))
    }

    private func drawPoint(_ point: TennisPoint, size: Int, color: SDLColor, using renderer: DisplayRenderClient) { renderer.drawCmd(DrawCmd(animationId: UInt64(abs(point.x * 1000 + point.y + size)), parentAnimationId: 0, dest: Rect(x: point.x - size / 2, y: point.y - size / 2, width: size, height: size), color: color, alpha: 1, z: 5, rotation: 0, rotationPoint: .zero, clippingRect: .zero, flip: [], time: 0, type: .rect(filled: true))) }
}

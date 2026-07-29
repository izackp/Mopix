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

final class TennisRenderer {
    private var fontHandle: UInt64?
    private let fontURL: VDUrl
    private let palette: TennisPalette

    init(fontURL: VDUrl) { self.fontURL = fontURL; self.palette = .approved }

    func loadResources(using client: DisplayClient) async throws {
        let body = try await client.loadResource(url: fontURL, kind: .font)
        guard case let .font(handle, _) = body else { throw GenericError("Tennis font resource response was not a font for \(fontURL.absoluteString)") }
        fontHandle = handle
    }

    func draw(flow: TennisFlowState, match: TennisMatchSnapshot?, presentation: TennisPresentationState, using renderer: DisplayRenderClient) throws {
        renderer.drawCmd(DrawCmd(animationId: 1, parentAnimationId: 0, dest: Rect(x: 0, y: 0, width: 160, height: 144), color: palette.canvas, alpha: 1, z: -10, rotation: 0, rotationPoint: .zero, clippingRect: .zero, flip: [], time: 0, type: .rect(filled: true)))
        switch flow.screen {
        case .title: try drawTitle(using: renderer)
        case .surfaceSelect: try drawSurfaceSelect(flow: flow, using: renderer)
        case .match: if let match { try drawMatch(snapshot: match, presentation: presentation, using: renderer) }
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

    private func drawMatch(snapshot: TennisMatchSnapshot, presentation: TennisPresentationState, using renderer: DisplayRenderClient) throws {
        try drawHUD(snapshot: snapshot, using: renderer)
        if snapshot.surface == .grass {
            // Near-side entities are drawn before the net (net renders in front of them), far-side
            // entities after (net renders behind them) — see the Net and depth-anchor outcome.
            drawGrassCourt(using: renderer)
            drawPlayersAndBall(snapshot: snapshot, presentation: presentation, courtEnd: .near, using: renderer)
            drawGrassNet(using: renderer)
            drawPlayersAndBall(snapshot: snapshot, presentation: presentation, courtEnd: .far, using: renderer)
        } else {
            drawCourt(surface: snapshot.surface, using: renderer)
            drawPlayersAndBall(snapshot: snapshot, presentation: presentation, courtEnd: nil, using: renderer)
        }
        drawCues(presentation, using: renderer)
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

    private func drawCourt(surface: TennisSurface, using renderer: DisplayRenderClient) {
        let court = Rect(x: 16, y: 24, width: 128, height: 96)
        renderer.drawCmd(DrawCmd(animationId: 20, parentAnimationId: 0, dest: court, color: palette.courtColor(for: surface), alpha: 1, z: 0, rotation: 0, rotationPoint: .zero, clippingRect: .zero, flip: [], time: 0, type: .rect(filled: true)))
        drawSurfacePattern(surface, in: court, using: renderer)
        renderer.drawCmd(DrawCmd(animationId: 21, parentAnimationId: 0, dest: court, color: palette.primary, alpha: 1, z: 4, rotation: 0, rotationPoint: .zero, clippingRect: .zero, flip: [], time: 0, type: .rect(filled: false)))
        renderer.drawCmd(DrawCmd(animationId: 22, parentAnimationId: 0, dest: Rect(x: 80, y: 24, width: 1, height: 96), color: palette.primary, alpha: 1, z: 1, rotation: 0, rotationPoint: .zero, clippingRect: .zero, flip: [], time: 0, type: .line(to: Point(0, 0), thickness: 1)))
    }

    /// The 136x108 Grass proof court is a composition-only overlay: it is sized and placed
    /// independently of the 128x96 gameplay court bounds (`TennisRules.courtBounds()`), which are
    /// unchanged. Depth bands run far-to-near with decreasing lane-mark spacing/increasing length.
    private func drawGrassCourt(using renderer: DisplayRenderClient) {
        let court = Rect(x: 12, y: 18, width: 136, height: 108)
        renderer.drawCmd(DrawCmd(animationId: 60, parentAnimationId: 0, dest: court, color: palette.grassCourt, alpha: 1, z: 0, rotation: 0, rotationPoint: .zero, clippingRect: .zero, flip: [], time: 0, type: .rect(filled: true)))
        drawGrassDepthBand(Rect(x: court.x, y: court.y, width: court.width, height: 36), markLength: 2, spacing: 8, using: renderer)
        drawGrassDepthBand(Rect(x: court.x, y: court.y + 36, width: court.width, height: 36), markLength: 4, spacing: 6, using: renderer)
        drawGrassDepthBand(Rect(x: court.x, y: court.y + 72, width: court.width, height: 36), markLength: 6, spacing: 4, using: renderer)
        renderer.drawCmd(DrawCmd(animationId: 61, parentAnimationId: 0, dest: court, color: palette.primary, alpha: 1, z: 1, rotation: 0, rotationPoint: .zero, clippingRect: .zero, flip: [], time: 0, type: .rect(filled: false)))
    }

    private func drawGrassDepthBand(_ rect: Rect<Int>, markLength: Int, spacing: Int, using renderer: DisplayRenderClient) {
        for x in stride(from: rect.x + 2, through: rect.x + rect.width - markLength - 2, by: spacing) {
            for y in stride(from: rect.y + 2, through: rect.y + rect.height - 3, by: spacing) {
                renderer.drawCmd(DrawCmd(animationId: UInt64(abs(x * 1000 + y)), parentAnimationId: 0, dest: Rect(x: x, y: y, width: markLength, height: 1), color: palette.canvas, alpha: 1, z: 1, rotation: 0, rotationPoint: .zero, clippingRect: .zero, flip: [], time: 0, type: .line(to: Point(markLength, 0), thickness: 1)))
            }
        }
    }

    /// Centered on the y=72 gameplay net plane so its front/behind split (via the caller's
    /// near-then-net-then-far draw order) lines up with `TennisRules.hasCrossedNetPlane`.
    private func drawGrassNet(using renderer: DisplayRenderClient) {
        let left = 12; let right = 148; let netTop = 70; let netHeight = 4
        let postWidth = 4; let postExtend = 8
        renderer.drawCmd(DrawCmd(animationId: 62, parentAnimationId: 0, dest: Rect(x: left, y: netTop - postExtend, width: postWidth, height: netHeight + postExtend * 2), color: palette.canvas, alpha: 1, z: 4, rotation: 0, rotationPoint: .zero, clippingRect: .zero, flip: [], time: 0, type: .rect(filled: true)))
        renderer.drawCmd(DrawCmd(animationId: 63, parentAnimationId: 0, dest: Rect(x: right - postWidth, y: netTop - postExtend, width: postWidth, height: netHeight + postExtend * 2), color: palette.canvas, alpha: 1, z: 4, rotation: 0, rotationPoint: .zero, clippingRect: .zero, flip: [], time: 0, type: .rect(filled: true)))
        renderer.drawCmd(DrawCmd(animationId: 64, parentAnimationId: 0, dest: Rect(x: left, y: netTop, width: right - left, height: netHeight), color: palette.canvas, alpha: 1, z: 4, rotation: 0, rotationPoint: .zero, clippingRect: .zero, flip: [], time: 0, type: .rect(filled: true)))
        for (rowIndex, y) in stride(from: netTop, to: netTop + netHeight, by: 2).enumerated() {
            for x in stride(from: left + postWidth + (rowIndex % 2), to: right - postWidth, by: 2) {
                renderer.drawCmd(DrawCmd(animationId: UInt64(abs(x * 1000 + y + 65)), parentAnimationId: 0, dest: Rect(x: x, y: y, width: 1, height: 1), color: palette.primary, alpha: 1, z: 4, rotation: 0, rotationPoint: .zero, clippingRect: .zero, flip: [], time: 0, type: .rect(filled: true)))
            }
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
        let torso = TennisPoint(x: player.position.x + torsoXOffset, y: player.position.y + torsoYOffset)
        drawPoint(torso, size: 8, color: palette.playerColor(for: side), using: renderer)
        drawIdentityMark(for: side, at: torso, using: renderer)
        let strideOffset = presentation.motion == .locomotion && moving ? (phase == 0 ? 2 : -2) : 0
        renderer.drawCmd(DrawCmd(animationId: UInt64(abs(torso.x * 1000 + torso.y + 31)), parentAnimationId: 0, dest: Rect(x: torso.x - 4 + strideOffset, y: torso.y + 4, width: 4, height: 1), color: palette.canvas, alpha: 1, z: 4, rotation: 0, rotationPoint: .zero, clippingRect: .zero, flip: [], time: 0, type: .line(to: Point(4, 0), thickness: 1)))
        renderer.drawCmd(DrawCmd(animationId: UInt64(abs(torso.x * 1000 + torso.y + 33)), parentAnimationId: 0, dest: Rect(x: torso.x + 1 - strideOffset, y: torso.y + 4, width: 4, height: 1), color: palette.canvas, alpha: 1, z: 4, rotation: 0, rotationPoint: .zero, clippingRect: .zero, flip: [], time: 0, type: .line(to: Point(4, 0), thickness: 1)))
        let chargeProgress = presentation.isChargeCapped ? 600 : min(600, presentation.elapsedMilliseconds)
        let followThroughAngle: Float = presentation.shot == .slice ? 30 : -30
        let racketAngle: Float = presentation.motion == .idle ? (phase == 1 ? 10 : 0) : (presentation.motion == .serveWindup ? 45 : (presentation.motion == .shotCharge ? -45 * Float(chargeProgress) / 600 : (presentation.motion == .followThrough ? followThroughAngle + 30 * Float(min(200, presentation.elapsedMilliseconds)) / 200 : 0)))
        let racketColor = presentation.impactElapsedMilliseconds == nil ? palette.primary : palette.impact
        renderer.drawCmd(DrawCmd(animationId: UInt64(abs(torso.x * 1000 + torso.y + 32)), parentAnimationId: 0, dest: Rect(x: torso.x, y: torso.y - 7, width: 1, height: 7), color: racketColor, alpha: 1, z: 6, rotation: racketAngle, rotationPoint: .zero, clippingRect: .zero, flip: [], time: 0, type: .line(to: Point(-3, -4), thickness: 1)))
    }

    private func drawGrassPlayerSilhouette(side: TennisSide, player: TennisPlayerState, presentation: TennisPlayerPresentation, using renderer: DisplayRenderClient) {
        let phase = Int((presentation.elapsedMilliseconds / 400) % 2)
        let moving = presentation.direction.x != 0 || presentation.direction.y != 0
        let torsoXOffset = presentation.motion == .followThrough ? (presentation.direction.x >= 0 ? 1 : -1) : (presentation.motion == .serveWindup ? (presentation.direction.x >= 0 ? -1 : 1) : 0)
        let torsoYOffset = presentation.motion == .idle && phase == 1 ? 1 : 0
        let torso = TennisPoint(x: player.position.x + torsoXOffset, y: player.position.y + torsoYOffset)
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
        let current = flight.consecutiveGroundContacts > 0 ? flight.landing : TennisPoint(x: flight.origin.x + (flight.landing.x - flight.origin.x) * progress / 100, y: flight.origin.y + (flight.landing.y - flight.origin.y) * progress / 100 - flight.height * (progress <= 50 ? progress : 100 - progress) / 50)
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
        drawPoint(flight.landing, size: 4, color: palette.canvas, using: renderer)
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
            case .serveAnticipation: break
            }
        }
    }

    private func drawText(_ text: String, at point: TennisPoint, color: SDLColor, using renderer: DisplayRenderClient) throws {
        guard let fontHandle else { throw GenericError("Tennis text font is unavailable for content '\(text)'") }
        renderer.drawCmd(DrawCmd(animationId: UInt64(abs(point.x * 1000 + point.y + 10)), parentAnimationId: 0, dest: Rect(x: point.x, y: point.y, width: 100, height: 16), color: color, alpha: 1, z: 10, rotation: 0, rotationPoint: .zero, clippingRect: .zero, flip: [], time: 0, type: .text(fontHandle: fontHandle, content: text, size: 12, align: .left)))
    }

    private func drawPoint(_ point: TennisPoint, size: Int, color: SDLColor, using renderer: DisplayRenderClient) { renderer.drawCmd(DrawCmd(animationId: UInt64(abs(point.x * 1000 + point.y + size)), parentAnimationId: 0, dest: Rect(x: point.x - size / 2, y: point.y - size / 2, width: size, height: size), color: color, alpha: 1, z: 5, rotation: 0, rotationPoint: .zero, clippingRect: .zero, flip: [], time: 0, type: .rect(filled: true))) }
}

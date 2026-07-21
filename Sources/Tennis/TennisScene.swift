import GameEngine
import SDL2Swift
import TennisCore

final class TennisScene: IDrawable {
    private enum Layer {
        static let background: UInt64 = 1
        static let court: UInt64 = 2
        static let courtBorder: UInt64 = 3
        static let topServiceLine: UInt64 = 4
        static let bottomServiceLine: UInt64 = 5
        static let centerServiceLine: UInt64 = 6
        static let netBand: UInt64 = 7
        static let netPosts: UInt64 = 8
        static let topCenterMark: UInt64 = 9
        static let bottomCenterMark: UInt64 = 10
        static let lowerPlayer: UInt64 = 11
        static let upperPlayer: UInt64 = 12
        static let ball: UInt64 = 13
    }

    private let viewport = Rect(x: 0, y: 0, width: 160, height: 144)
    private let court = Rect(x: 24, y: 10, width: 112, height: 124)
    private let lineColor = SDLColor(rawValue: 0xFFF2F1D5)
    private let backgroundColor = SDLColor(rawValue: 0xFF1E5334)
    private let courtColor = SDLColor(rawValue: 0xFF3D8AA8)
    private let netColor = SDLColor(rawValue: 0xFF292C33)
    private let lowerPlayerColor = SDLColor(rawValue: 0xFFF46D43)
    private let upperPlayerColor = SDLColor(rawValue: 0xFF46C28B)
    private let ballColor = SDLColor(rawValue: 0xFFF7EE59)
    private let coordinator: TennisMatchCoordinator
    private let hud: TennisHUD?
    private let presentation: TennisPresentationFlow?
    private let feedback = TennisMatchFeedbackReducer()

    init(coordinator: TennisMatchCoordinator) {
        self.coordinator = coordinator
        self.hud = nil
        self.presentation = nil
    }

    init(coordinator: TennisMatchCoordinator, hud: TennisHUD, presentation: TennisPresentationFlow? = nil) {
        self.coordinator = coordinator
        self.hud = hud
        self.presentation = presentation
    }

    func draw(_ delta: UInt64, _ renderer: DisplayRenderClient) {
        let netY = court.centerY
        let serviceInset = 28
        let serviceLineThickness = 2
        let baselineCenterMarkWidth = 2
        let baselineCenterMarkHeight = 5
        fill(renderer, id: Layer.background, rect: viewport, color: backgroundColor, z: 0)
        if let presentation, presentation.state.screen != .match {
            presentation.draw(renderer: renderer)
            return
        }
        view(renderer, id: Layer.courtBorder, rect: court, fill: courtColor, border: lineColor, borderWidth: 2, z: 1)

        fill(renderer, id: Layer.topServiceLine, rect: Rect(x: court.x + 2, y: court.y + serviceInset, width: court.width - 4, height: serviceLineThickness), color: lineColor, z: 2)
        fill(renderer, id: Layer.bottomServiceLine, rect: Rect(x: court.x + 2, y: court.bottom - serviceInset - serviceLineThickness, width: court.width - 4, height: serviceLineThickness), color: lineColor, z: 2)
        fill(renderer, id: Layer.centerServiceLine, rect: Rect(x: court.centerX - 1, y: court.y + serviceInset, width: 2, height: court.height - serviceInset * 2), color: lineColor, z: 2)

        fill(renderer, id: Layer.netBand, rect: Rect(x: court.x + 1, y: netY - 1, width: court.width - 2, height: 3), color: netColor, z: 3)
        fill(renderer, id: Layer.netPosts, rect: Rect(x: court.x - 1, y: netY - 4, width: court.width + 2, height: 1), color: lineColor, z: 3)

        fill(renderer, id: Layer.topCenterMark, rect: Rect(x: court.centerX - 1, y: court.y, width: baselineCenterMarkWidth, height: baselineCenterMarkHeight), color: lineColor, z: 2)
        fill(renderer, id: Layer.bottomCenterMark, rect: Rect(x: court.centerX - 1, y: court.bottom - baselineCenterMarkHeight, width: baselineCenterMarkWidth, height: baselineCenterMarkHeight), color: lineColor, z: 2)

        let snapshot = coordinator.snapshot()
        for event in coordinator.consumePresentationEvents() { feedback.consume(event, tick: snapshot.simulation.tick) }
        feedback.advance(to: snapshot.simulation.tick)
        render(snapshot, renderer: renderer)
        hud?.draw(snapshot, feedback: feedback.state, renderer: renderer)
    }

    private func render(_ snapshot: TennisMatchSnapshot, renderer: DisplayRenderClient) {
        let lowerPlayerRect = playerRect(for: snapshot.simulation.players[.human], in: court)
        let upperPlayerRect = playerRect(for: snapshot.simulation.players[.cpu], in: court)
        let ballRect = ballRect(for: snapshot.simulation.ball, in: court)

        // Keep the airborne landing/shadow cue under the ball and its target area.
        if snapshot.simulation.ball.isInFlight {
            fill(renderer, id: 14, rect: Rect(x: ballRect.x - 1, y: ballRect.y + 3, width: 5, height: 2), color: SDLColor(rawValue: 0x88404040), z: 4)
        }
        if let trail = feedback.state.shotTrail {
            fill(renderer, id: 15, rect: Rect(x: ballRect.x - 4, y: ballRect.y, width: 3, height: 2), color: trail.color, z: 4)
        }
        if let pointEnd = feedback.state.pointEnd {
            let color = pointEnd.kind == .netFault ? SDLColor(rawValue: 0xFFE34B4B) : SDLColor(rawValue: 0xFFFFD447)
            fill(renderer, id: 16, rect: Rect(x: court.x + 5, y: court.centerY - 2, width: court.width - 10, height: 4), color: color, z: 6)
        }
        if let bounce = feedback.state.surfaceBounce {
            let cue: (UInt64, SDLColor, Rect<Int>)
            switch bounce.surface {
            case .hard:
                cue = (17, SDLColor(rawValue: 0xFFEAF7FF), Rect(x: ballRect.x - 3, y: ballRect.bottom, width: 9, height: 1))
            case .clay:
                cue = (18, SDLColor(rawValue: 0xFFE07A45), Rect(x: ballRect.x - 2, y: ballRect.bottom, width: 7, height: 2))
            case .grass:
                cue = (19, SDLColor(rawValue: 0xFFB5F05A), Rect(x: ballRect.x - 4, y: ballRect.bottom, width: 11, height: 1))
            }
            fill(renderer, id: cue.0, rect: cue.2, color: cue.1, z: 6)
        }

        view(renderer, id: Layer.lowerPlayer, rect: lowerPlayerRect, fill: lowerPlayerColor, border: lineColor, borderWidth: 1, z: 4)
        view(renderer, id: Layer.upperPlayer, rect: upperPlayerRect, fill: upperPlayerColor, border: lineColor, borderWidth: 1, z: 4)
        view(renderer, id: Layer.ball, rect: ballRect, fill: ballColor, border: netColor, borderWidth: 1, z: 5)
    }

    private func playerRect(for player: TennisPlayerState?, in court: Rect<Int>) -> Rect<Int> {
        let position = player?.position ?? TennisPoint(x: 5000, y: 10000)
        let center = projectedPoint(position, in: court)
        let size = Size(8, 12)
        return Rect(x: center.x - size.width / 2, y: center.y - size.height / 2, width: size.width, height: size.height)
    }

    private func ballRect(for ball: TennisBallState, in court: Rect<Int>) -> Rect<Int> {
        let center = projectedPoint(ball.position, in: court)
        return Rect(x: center.x - 1, y: center.y - 1, width: 3, height: 3)
    }

    private func projectedPoint(_ point: TennisPoint, in court: Rect<Int>) -> Point<Int> {
        let x = max(0, min(10000, Int(point.x)))
        let y = max(0, min(20000, Int(point.y)))
        return Point(court.x + x * court.width / 10000, court.y + y * court.height / 20000)
    }

    private func fill(_ renderer: DisplayRenderClient, id: UInt64, rect: Rect<Int>, color: SDLColor, z: Int) {
        renderer.drawCmd(
            DrawCmd(
                animationId: id,
                parentAnimationId: 0,
                dest: rect,
                color: color,
                alpha: 1,
                z: z,
                rotation: 0,
                rotationPoint: .zero,
                clippingRect: .zero,
                flip: [],
                time: renderer.defaultTime,
                type: .fill
            )
        )
    }

    private func view(_ renderer: DisplayRenderClient, id: UInt64, rect: Rect<Int>, fill: SDLColor, border: SDLColor, borderWidth: Int, z: Int) {
        renderer.drawCmd(
            DrawCmd(
                animationId: id,
                parentAnimationId: 0,
                dest: rect,
                color: fill,
                alpha: 1,
                z: z,
                rotation: 0,
                rotationPoint: .zero,
                clippingRect: .zero,
                flip: [],
                time: renderer.defaultTime,
                type: .view(borderColor: border, borderWidth: borderWidth)
            )
        )
    }
}

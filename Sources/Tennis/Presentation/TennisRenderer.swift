import Foundation
import GameEngine
import SDL2
import SDL2Swift

final class TennisRenderer {
    private var fontHandle: UInt64?
    private let fontURL: VDUrl
    init(fontURL: VDUrl) { self.fontURL = fontURL; fontHandle = nil }

    func loadResources(using client: DisplayClient) async throws {
        let body = try await client.loadResource(url: fontURL, kind: .font)
        if case let .font(handle, _) = body { fontHandle = handle }
    }

    func draw(flow: TennisFlowState, match: TennisMatchSnapshot?, presentation: TennisPresentationState, using renderer: DisplayRenderClient) {
        switch flow.screen {
        case .title: drawTitle(using: renderer)
        case .surfaceSelect: drawSurfaceSelect(flow: flow, using: renderer)
        case .match: if let match { drawMatch(snapshot: match, presentation: presentation, using: renderer) }
        case .result: drawResult(flow: flow, using: renderer)
        }
    }

    private func drawTitle(using renderer: DisplayRenderClient) { drawText("TENNIS", at: TennisPoint(x: 48, y: 48), using: renderer); drawText("PRESS A", at: TennisPoint(x: 48, y: 72), using: renderer) }
    private func drawSurfaceSelect(flow: TennisFlowState, using renderer: DisplayRenderClient) { drawText("SURFACE", at: TennisPoint(x: 48, y: 40), using: renderer); drawText(String(describing: flow.highlightedSurface).uppercased(), at: TennisPoint(x: 48, y: 64), using: renderer); drawText("LEFT / RIGHT / A", at: TennisPoint(x: 32, y: 88), using: renderer) }
    private func drawMatch(snapshot: TennisMatchSnapshot, presentation: TennisPresentationState, using renderer: DisplayRenderClient) { drawCourt(surface: snapshot.surface, using: renderer); drawHUD(snapshot: snapshot, using: renderer); drawPlayersAndBall(snapshot: snapshot, using: renderer); drawCues(presentation, using: renderer) }
    private func drawResult(flow: TennisFlowState, using renderer: DisplayRenderClient) { drawText(flow.result == .human ? "YOU WIN" : "CPU WINS", at: TennisPoint(x: 48, y: 56), using: renderer); drawText("PRESS A", at: TennisPoint(x: 48, y: 80), using: renderer) }
    private func drawCourt(surface: TennisSurface, using renderer: DisplayRenderClient) {
        renderer.drawCmd(DrawCmd(animationId: 1, parentAnimationId: 0, dest: Rect(x: 16, y: 24, width: 128, height: 96), color: .white, alpha: 1, z: 0, rotation: 0, rotationPoint: .zero, clippingRect: .zero, flip: [], time: 0, type: .rect(filled: false)))
        let center = Rect(x: 80, y: 72, width: 1, height: 1)
        let type: DrawCmdType = surface == .hard ? .circle(radius: 12, filled: false) : (surface == .clay ? .circle(radius: 8, filled: true) : .line(to: Point(16, 0), thickness: 2))
        renderer.drawCmd(DrawCmd(animationId: 2, parentAnimationId: 0, dest: center, color: .white, alpha: 1, z: 1, rotation: 0, rotationPoint: .zero, clippingRect: .zero, flip: [], time: 0, type: type))
    }
    private func drawHUD(snapshot: TennisMatchSnapshot, using renderer: DisplayRenderClient) { drawText("\(snapshot.score.human) - \(snapshot.score.cpu)", at: TennisPoint(x: 56, y: 8), using: renderer) }
    private func drawPlayersAndBall(snapshot: TennisMatchSnapshot, using renderer: DisplayRenderClient) { for player in snapshot.players.values { drawPoint(player.position, size: 8, using: renderer) }; if let ball = snapshot.ball { drawPoint(ball.shadow, size: 4, using: renderer) } }
    private func drawCues(_ state: TennisPresentationState, using renderer: DisplayRenderClient) {
        for cue in state.cues {
            guard let position = cue.position else { continue }
            let size: Int
            switch cue.kind {
            case .landing: size = 6
            case .hardBounce: size = 12
            case .clayBounce: size = 8
            case .grassBounce: size = 3
            case .smashStarburst: size = 12
            case .smashFlash: size = 9
            case .chargeMeter, .chargeCap: size = 5
            default: size = 4
            }
            drawPoint(position, size: size, using: renderer)
        }
    }
    private func drawText(_ text: String, at point: TennisPoint, using renderer: DisplayRenderClient) { guard let fontHandle else { return }; renderer.drawCmd(DrawCmd(animationId: 0, parentAnimationId: 0, dest: Rect(x: point.x, y: point.y, width: 100, height: 16), color: .white, alpha: 1, z: 10, rotation: 0, rotationPoint: .zero, clippingRect: .zero, flip: [], time: 0, type: .text(fontHandle: fontHandle, content: text, size: 12, align: .left))) }
    private func drawPoint(_ point: TennisPoint, size: Int, using renderer: DisplayRenderClient) { renderer.drawCmd(DrawCmd(animationId: UInt64(point.x * 1000 + point.y), parentAnimationId: 0, dest: Rect(x: point.x - size / 2, y: point.y - size / 2, width: size, height: size), color: .white, alpha: 1, z: 5, rotation: 0, rotationPoint: .zero, clippingRect: .zero, flip: [], time: 0, type: .rect(filled: true))) }
}

import GameEngine
import SDL2
import SDL2Swift
import TennisCore

public enum TennisScreen: Equatable { case title, surfaceSelect, match, result }
public enum TennisMenuCommand: Equatable { case start, chooseSurface(CourtSurface), `continue` }

public struct TennisResultSnapshot: Equatable {
    public let winner: TennisSide
    public let score: TennisMatchScore
    public init(winner: TennisSide, score: TennisMatchScore) { self.winner = winner; self.score = score }
}

public struct TennisPresentationState: Equatable {
    public var screen: TennisScreen
    public var selectedSurface: CourtSurface?
    public var result: TennisResultSnapshot?
    public init(screen: TennisScreen = .title) { self.screen = screen; selectedSurface = nil; result = nil }
}

public enum TennisMatchPresentationEvent: Equatable {
    case shotHit(side: TennisSide, shot: ShotKind)
    case bounce(surface: CourtSurface)
    case netContact
    case outOfBounds
    case serveFault(landing: TennisPoint)
    case pointEnded(reason: PointEndReason, winner: TennisSide)
    case matchCompleted(winner: TennisSide)
}

public struct TennisShotTrail: Equatable { public let color: SDLColor; public let expiresAt: UInt64 }
public struct TennisLandingMarker: Equatable { public let point: TennisPoint; public let expiresAt: UInt64 }
public struct TennisSurfaceBounce: Equatable { public let surface: CourtSurface; public let expiresAt: UInt64 }
public enum TennisPointEndKind: Equatable { case netFault, outOfBounds, secondBounce }
public struct TennisPointEndCue: Equatable { public let kind: TennisPointEndKind; public let expiresAt: UInt64 }
public struct TennisFaultCallout: Equatable { public let text: String; public let landing: TennisPoint; public let expiresAt: UInt64 }

public struct TennisMatchFeedbackState: Equatable {
    public var shotTrail: TennisShotTrail?
    public var landingMarker: TennisLandingMarker?
    public var surfaceBounce: TennisSurfaceBounce?
    public var pointEnd: TennisPointEndCue?
    public var faultCallout: TennisFaultCallout?
    public init(shotTrail: TennisShotTrail? = nil, landingMarker: TennisLandingMarker? = nil,
                surfaceBounce: TennisSurfaceBounce? = nil, pointEnd: TennisPointEndCue? = nil,
                faultCallout: TennisFaultCallout? = nil) {
        self.shotTrail = shotTrail; self.landingMarker = landingMarker; self.surfaceBounce = surfaceBounce
        self.pointEnd = pointEnd; self.faultCallout = faultCallout
    }
}

public final class TennisMatchFeedbackReducer {
    public private(set) var state = TennisMatchFeedbackState()
    public var surfaceBounceAudioHook: ((CourtSurface) -> Void)?
    public init() {}
    public func consume(_ event: TennisMatchPresentationEvent, tick: UInt64) {
        switch event {
        case .shotHit(_, let shot):
            let color: SDLColor = shot == .topspin ? SDLColor(rawValue: 0xFFE34B4B) : shot == .slice ? SDLColor(rawValue: 0xFF4B86E3) : shot == .smash ? SDLColor(rawValue: 0xFFB04BE3) : SDLColor(rawValue: 0xFFF2F1D5)
            state.shotTrail = TennisShotTrail(color: color, expiresAt: tick + 12)
        case .bounce(let surface):
            state.surfaceBounce = TennisSurfaceBounce(surface: surface, expiresAt: tick + 8)
            surfaceBounceAudioHook?(surface)
        case .netContact: state.pointEnd = TennisPointEndCue(kind: .netFault, expiresAt: tick + 20)
        case .outOfBounds: state.pointEnd = TennisPointEndCue(kind: .outOfBounds, expiresAt: tick + 20)
        case .serveFault(let landing): state.faultCallout = TennisFaultCallout(text: "FAULT", landing: landing, expiresAt: tick + 30)
        case .pointEnded(let reason, _):
            let kind: TennisPointEndKind = { switch reason { case .netFault: return .netFault; case .outOfBounds: return .outOfBounds; default: return .secondBounce } }()
            state.pointEnd = TennisPointEndCue(kind: kind, expiresAt: tick + 20)
        case .matchCompleted: break
        }
    }
    public func advance(to tick: UInt64) {
        if state.shotTrail?.expiresAt ?? 0 <= tick { state.shotTrail = nil }
        if state.landingMarker?.expiresAt ?? 0 <= tick { state.landingMarker = nil }
        if state.surfaceBounce?.expiresAt ?? 0 <= tick { state.surfaceBounce = nil }
        if state.pointEnd?.expiresAt ?? 0 <= tick { state.pointEnd = nil }
        if state.faultCallout?.expiresAt ?? 0 <= tick { state.faultCallout = nil }
    }
    public func reset() { state = TennisMatchFeedbackState() }
}

public struct TennisChargeSnapshot: Equatable {
    public let activeSide: TennisSide
    public let value: Int
    public let capReached: Bool
    public init(activeSide: TennisSide, value: Int, capReached: Bool) { self.activeSide = activeSide; self.value = value; self.capReached = capReached }
}

public final class TennisHUD {
    private let scoreLayout = Rect(x: 3, y: 3, width: 48, height: 12)
    private let serverLayout = Rect(x: 112, y: 3, width: 45, height: 12)
    private let font: Font
    public init(font: Font) { self.font = font }
    public func draw(_ snapshot: TennisMatchSnapshot, feedback: TennisMatchFeedbackState, renderer: DisplayRenderClient) {
        drawText("P\(snapshot.score.humanPoints) C\(snapshot.score.cpuPoints)", at: Point(scoreLayout.x, scoreLayout.y), color: .white, renderer: renderer)
        drawText(snapshot.score.server == .human ? "SERVE P" : "SERVE C", at: Point(serverLayout.x, serverLayout.y), color: .white, renderer: renderer)
        let charge = snapshot.charge
        let player = snapshot.simulation.players[charge.activeSide]
        let position = player?.position ?? TennisPoint(x: 5000, y: 10000)
        let x = 24 + Int(position.x) * 112 / 10000 - 10
        let y = 10 + Int(position.y) * 124 / 20000 - 9
        let width = max(1, min(20, charge.value * 20 / 100))
        fill(renderer, rect: Rect(x: x, y: y, width: 20, height: 3), color: SDLColor(rawValue: 0xFF292C33), z: 20)
        fill(renderer, rect: Rect(x: x, y: y, width: width, height: 3), color: charge.capReached ? SDLColor(rawValue: 0xFFFFD447) : SDLColor(rawValue: 0xFFF46D43), z: 21)
        if charge.capReached { drawText("MAX", at: Point(x, y - 8), color: SDLColor(rawValue: 0xFFFFD447), renderer: renderer) }
        if let fault = feedback.faultCallout { drawText(fault.text, at: Point(67, 68), color: SDLColor(rawValue: 0xFFFFD447), renderer: renderer) }
    }
    private func drawText(_ text: String, at point: Point<Int>, color: SDLColor, renderer: DisplayRenderClient) {
        var x = point.x
        for character in text {
            guard let resource = font.resourceId(for: character) else { continue }
            renderer.draw(UInt64(x), resource, Rect(x: x, y: point.y, width: 5, height: 8), color, 30)
            x += 6
        }
    }
    private func fill(_ renderer: DisplayRenderClient, rect: Rect<Int>, color: SDLColor, z: Int) {
        renderer.drawCmd(DrawCmd(animationId: UInt64(z), parentAnimationId: 0, dest: rect, color: color, alpha: 1, z: z, rotation: 0, rotationPoint: .zero, clippingRect: .zero, flip: [], time: renderer.defaultTime, type: .fill))
    }
}

public protocol TennisTextRenderer {
    func draw(_ text: String, at point: Point<Int>, color: SDLColor, z: Int, renderer: DisplayRenderClient)
}

final class TennisFontTextRenderer: TennisTextRenderer {
    private let font: Font
    init(font: Font) { self.font = font }

    func draw(_ text: String, at point: Point<Int>, color: SDLColor, z: Int, renderer: DisplayRenderClient) {
        var x = point.x
        for (index, character) in text.enumerated() {
            guard let resource = font.resourceId(for: character) else { continue }
            let commandID = UInt64(4000 + z * 100 + index)
            renderer.draw(commandID, resource, Rect(x: x, y: point.y, width: 5, height: 8), color, z)
            x += 6
        }
    }
}

public final class TennisPresentationFlow: TennisMatchDelegate, IEventListener {
    public private(set) var state: TennisPresentationState
    private let matchFactory: (CourtSurface) -> TennisMatchCoordinator
    private let textRenderer: TennisTextRenderer
    private var coordinator: TennisMatchCoordinator?
    var onCoordinatorChange: ((TennisMatchCoordinator?) -> Void)?
    public init(matchFactory: @escaping (CourtSurface) -> TennisMatchCoordinator, textRenderer: TennisTextRenderer) {
        self.matchFactory = matchFactory
        self.textRenderer = textRenderer
        state = TennisPresentationState()
    }
    var integrationCoordinator: TennisMatchCoordinator? { coordinator }
    public func onCommand(_ command: TennisMenuCommand) {
        switch (state.screen, command) {
        case (.title, .start): state.screen = .surfaceSelect
        case (.surfaceSelect, .chooseSurface(let surface)): beginMatch(surface: surface)
        case (.result, .continue): beginSurfaceSelect()
        default: break
        }
    }
    public func onEvents(_ events: [SDL_Event]) {
        for event in events where event.type == UInt32(SDL_KEYDOWN.rawValue) {
            switch state.screen {
            case .title: onCommand(.start)
            case .surfaceSelect:
                switch event.key.keysym.sym { case 49: onCommand(.chooseSurface(.hard)); case 50: onCommand(.chooseSurface(.clay)); case 51: onCommand(.chooseSurface(.grass)); default: break }
            case .result: onCommand(.continue)
            case .match: break
            }
        }
    }
    public func draw(renderer: DisplayRenderClient) {
        switch state.screen { case .title: drawText("TENNIS", x: 57, y: 52, renderer: renderer); drawText("PRESS A", x: 57, y: 74, renderer: renderer)
        case .surfaceSelect: drawText("SURFACE", x: 53, y: 42, renderer: renderer); drawText("1 HARD  2 CLAY  3 GRASS", x: 22, y: 70, renderer: renderer)
        case .result: if let result = state.result { drawText(result.winner == .human ? "PLAYER WINS" : "CPU WINS", x: 39, y: 52, renderer: renderer); drawText("PRESS A", x: 57, y: 76, renderer: renderer) }
        case .match: break }
    }
    public func matchDidEndPoint(_ reason: PointEndReason, winner: TennisSide, score: TennisMatchScore) {}
    public func matchDidComplete(_ winner: TennisSide, score: TennisMatchScore) { state.result = TennisResultSnapshot(winner: winner, score: score); state.screen = .result }
    private func beginMatch(surface: CourtSurface) {
        state.selectedSurface = surface
        state.result = nil
        let selectedCoordinator = matchFactory(surface)
        selectedCoordinator.delegate = self
        coordinator = selectedCoordinator
        onCoordinatorChange?(selectedCoordinator)
        state.screen = .match
    }
    private func beginSurfaceSelect() {
        onCoordinatorChange?(nil)
        coordinator = nil
        state.result = nil
        state.screen = .surfaceSelect
    }
    private func drawText(_ text: String, x: Int, y: Int, renderer: DisplayRenderClient) {
        textRenderer.draw(text, at: Point(x, y), color: .white, z: 40, renderer: renderer)
    }
}

import Foundation
import GameEngine
import SDL2

struct TennisFlowState: Equatable {
    var screen: TennisScreen
    var highlightedSurface: TennisSurface
    var result: TennisSide?
}

final class TennisGameController: IUpdate, IDrawable, IEventListener {
    private(set) var flow: TennisFlowState
    private var simulation: TennisSimulation?
    private var presentation: TennisPresentationController
    private let input: TennisInputController
    private let renderer: TennisRenderer
    private let configuration: TennisGameConfiguration

    init(configuration: TennisGameConfiguration, fontURL: VDUrl) {
        self.configuration = configuration
        self.flow = TennisFlowState(screen: .title, highlightedSurface: .hard, result: nil)
        self.simulation = nil
        self.presentation = TennisPresentationController()
        self.input = TennisInputController()
        self.renderer = TennisRenderer(fontURL: fontURL)
    }

    func prepare(using client: DisplayClient) async throws {
        try await renderer.loadResources(using: client)
    }

    func onEvents(_ events: [SDL_Event]) {
        input.onEvents(events)
    }

    func step(_ delta: UInt64) {
        let frame = input.consumeTick()
        switch flow.screen {
        case .title, .surfaceSelect, .result:
            advanceMenu(input: frame)
        case .match:
            guard var simulation else { return }
            let tick = simulation.advance(input: frame)
            presentation.advance(
                events: tick.events,
                snapshot: tick.snapshot,
                elapsedMilliseconds: delta
            )
            if let winner = tick.snapshot.matchWinner {
                flow.screen = .result
                flow.result = winner
            }
            self.simulation = simulation
        }
    }

    func draw(_ delta: UInt64, _ renderer: DisplayRenderClient) {
        self.renderer.draw(
            flow: flow,
            match: simulation?.snapshot,
            presentation: presentation.state,
            using: renderer
        )
    }

    private func advanceMenu(input: TennisInputFrame) {
        switch flow.screen {
        case .title:
            if input.menuAcceptPressed || input.pressedShotButtons.contains(.a) {
                flow.screen = .surfaceSelect
            }
        case .surfaceSelect:
            let surfaces = Array(TennisSurface.allCases)
            guard let current = surfaces.firstIndex(of: flow.highlightedSurface) else { return }
            if input.menuLeftPressed {
                flow.highlightedSurface = surfaces[(current + surfaces.count - 1) % surfaces.count]
            } else if input.menuRightPressed {
                flow.highlightedSurface = surfaces[(current + 1) % surfaces.count]
            } else if input.menuAcceptPressed || input.pressedShotButtons.contains(.a) {
                startMatch(surface: flow.highlightedSurface)
            }
        case .result:
            if input.menuAcceptPressed || input.pressedShotButtons.contains(.a) {
                leaveResult()
            }
        case .match:
            break
        }
    }

    private func startMatch(surface: TennisSurface) {
        simulation = TennisSimulation(surface: surface, configuration: configuration)
        simulation?.beginPoint()
        presentation.resetForServeWindup()
        input.clearGameplayInput()
        flow.screen = .match
        flow.result = nil
    }

    private func leaveResult() {
        simulation = nil
        flow.screen = .surfaceSelect
        flow.result = nil
        input.clearGameplayInput()
    }
}

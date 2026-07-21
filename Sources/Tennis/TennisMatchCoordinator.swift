import GameEngine
import SDL2
import TennisCore
import TennisInput

public protocol TennisMatchDelegate: AnyObject {
    func matchDidEndPoint(_ reason: PointEndReason, winner: TennisSide, score: TennisMatchScore)
    func matchDidComplete(_ winner: TennisSide, score: TennisMatchScore)
}

public struct TennisMatchSnapshot: Equatable {
    public let score: TennisMatchScore
    public let simulation: TennisSimulationState
    public let charge: TennisChargeSnapshot

    public init(score: TennisMatchScore, simulation: TennisSimulationState, charge: TennisChargeSnapshot? = nil) {
        self.score = score
        self.simulation = simulation
        self.charge = charge ?? TennisChargeSnapshot(activeSide: score.server, value: 0, capReached: false)
    }
}

public final class TennisMatchCoordinator: IUpdate, IEventListener, TennisSimulationDelegate {
    public let simulation: TennisSimulation
    public let humanController: TennisHumanController
    public let cpuController: TennisCPUController
    public private(set) var score: TennisMatchScore
    public weak var delegate: TennisMatchDelegate?

    private let scorekeeper: TennisMatchScorekeeper
    private var pendingCommands: [InputCommand] = []
    private var tick: UInt64
    private var pendingPointEnd: PointEndReason?
    public private(set) var latestCharge = TennisChargeSnapshot(activeSide: .human, value: 0, capReached: false)
    public private(set) var presentationEvents: [TennisMatchPresentationEvent] = []

    public init(
        simulation: TennisSimulation,
        scorekeeper: TennisMatchScorekeeper,
        humanController: TennisHumanController,
        cpuController: TennisCPUController
    ) {
        self.simulation = simulation
        self.scorekeeper = scorekeeper
        self.humanController = humanController
        self.cpuController = cpuController
        self.score = scorekeeper.score
        self.tick = simulation.state.tick
        simulation.delegate = self
    }

    public func snapshot() -> TennisMatchSnapshot {
        TennisMatchSnapshot(score: score, simulation: simulation.snapshot(), charge: latestCharge)
    }

    public func step(_ delta: UInt64) {
        _ = delta
        guard score.matchWinner == nil else { return }
        tick &+= 1
        flushPendingCommands()
        let snapshot = simulation.snapshot()
        let humanIntent = humanController.intent(for: snapshot, tick: tick)
        let cpuIntent = cpuController.intent(for: snapshot, tick: tick)
        if case .swing(_, let value) = humanIntent {
            latestCharge = TennisChargeSnapshot(activeSide: .human, value: value, capReached: value >= 100)
        } else {
            latestCharge = TennisChargeSnapshot(activeSide: snapshot.server, value: 0, capReached: false)
        }
        simulation.step(tickInput: TennisTickInput(human: humanIntent, cpu: cpuIntent))
        completePointIfNeeded()
    }

    public func onEvents(_ events: [SDL_Event]) {
        guard score.matchWinner == nil else { return }
        for event in events {
            if let command = event.toCommand() { pendingCommands.append(command) }
        }
    }

    public func simulationDidEmit(_ event: TennisSimulationEvent) {
        if case .pointEnded(let reason) = event.kind { pendingPointEnd = reason }
        switch event.kind {
        case .serveHit(let side): presentationEvents.append(.shotHit(side: side, shot: .serve))
        case .serveFault(_, let landing): presentationEvents.append(.serveFault(landing: landing))
        case .shotHit(let side, let shot, _): presentationEvents.append(.shotHit(side: side, shot: shot))
        case .bounce(let surface): presentationEvents.append(.bounce(surface: surface))
        case .netContact: presentationEvents.append(.netContact)
        case .outOfBounds: presentationEvents.append(.outOfBounds)
        case .pointEnded(let reason): presentationEvents.append(.pointEnded(reason: reason, winner: simulation.ruleBook.pointWinner(for: reason)))
        }
    }

    public func consumePresentationEvents() -> [TennisMatchPresentationEvent] {
        let events = presentationEvents
        presentationEvents.removeAll(keepingCapacity: true)
        return events
    }

    public func resetMatch(server: TennisSide) {
        scorekeeper.reset(server: server)
        score = scorekeeper.score
        pendingCommands.removeAll(keepingCapacity: true)
        pendingPointEnd = nil
        latestCharge = TennisChargeSnapshot(activeSide: server, value: 0, capReached: false)
        simulation.resetPoint(server: server)
        humanController.resetPoint()
        cpuController.resetPoint()
    }

    private func flushPendingCommands() {
        guard !pendingCommands.isEmpty else { return }
        let commands = pendingCommands
        pendingCommands.removeAll(keepingCapacity: true)
        humanController.inputRouter.onCommandList(InputCommandList(clientId: 0, deviceId: 0, commands: commands))
    }

    private func completePointIfNeeded() {
        guard let reason = simulation.state.pointEnd ?? pendingPointEnd else { return }
        pendingPointEnd = nil
        let winner = simulation.ruleBook.pointWinner(for: reason)
        let resolution = scorekeeper.recordPoint(winner: winner)
        score = resolution.score
        delegate?.matchDidEndPoint(reason, winner: winner, score: resolution.score)
        guard let matchWinner = resolution.matchWinner else {
            simulation.resetPoint(server: resolution.score.server)
            humanController.resetPoint()
            cpuController.resetPoint()
            return
        }
        delegate?.matchDidComplete(matchWinner, score: resolution.score)
    }
}

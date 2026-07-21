import GameEngine
import SDL2
import TennisCore
import TennisInput

public protocol TennisMatchDelegate: AnyObject {
    func matchDidEndPoint(_ reason: PointEndReason, winner: TennisSide, score: TennisMatchScore)
    func matchDidComplete(_ winner: TennisSide, score: TennisMatchScore)
}

public final class TennisMatchCoordinator: IUpdate, IEventListener, TennisSimulationDelegate {
    public let simulation: TennisSimulation
    public let humanController: TennisHumanController
    public let cpuController: TennisCPUController
    public private(set) var score: TennisMatchScore
    public weak var delegate: TennisMatchDelegate?

    private let scorekeeper: TennisMatchScorekeeper
    private var pendingCommands: [InputCommand] = []
    private var tick: UInt64 = 0
    private var pendingPointEnd: PointEndReason?

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
        simulation.delegate = self
    }

    public func step(_ delta: UInt64) {
        _ = delta
        guard score.matchWinner == nil else { return }
        tick &+= 1
        flushPendingCommands()
        let snapshot = simulation.snapshot()
        let humanIntent = humanController.intent(for: snapshot, tick: tick)
        let cpuIntent = cpuController.intent(for: snapshot, tick: tick)
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
    }

    public func resetMatch(server: TennisSide) {
        scorekeeper.reset(server: server)
        score = scorekeeper.score
        pendingCommands.removeAll(keepingCapacity: true)
        pendingPointEnd = nil
        tick = 0
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

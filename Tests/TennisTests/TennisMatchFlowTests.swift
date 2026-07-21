import XCTest
import GameEngine
@testable import Tennis
@testable import TennisCore
@testable import TennisInput

final class TennisMatchFlowTests: XCTestCase {
    func testScorekeeperRotatesServerEveryTwoPoints() {
        let scorekeeper = TennisMatchScorekeeper(initialServer: .human)

        XCTAssertEqual(scorekeeper.recordPoint(winner: .human).score.server, .human)
        XCTAssertEqual(scorekeeper.score.pointsSinceServerRotation, 1)
        XCTAssertEqual(scorekeeper.recordPoint(winner: .cpu).score.server, .cpu)
        XCTAssertEqual(scorekeeper.score.pointsSinceServerRotation, 0)
        XCTAssertEqual(scorekeeper.recordPoint(winner: .human).score.server, .cpu)
        XCTAssertEqual(scorekeeper.recordPoint(winner: .cpu).score.server, .human)
        XCTAssertEqual(scorekeeper.score.pointsSinceServerRotation, 0)
    }

    func testScorekeeperRequiresWinByTwoAtEleven() {
        let scorekeeper = TennisMatchScorekeeper(initialServer: .human)
        for _ in 0..<10 { XCTAssertNil(scorekeeper.recordPoint(winner: .human).matchWinner) }
        for _ in 0..<10 { XCTAssertNil(scorekeeper.recordPoint(winner: .cpu).matchWinner) }

        XCTAssertNil(scorekeeper.recordPoint(winner: .human).matchWinner)
        let humanWin = scorekeeper.recordPoint(winner: .human)
        XCTAssertEqual(humanWin.score.humanPoints, 12)
        XCTAssertEqual(humanWin.score.cpuPoints, 10)
        XCTAssertEqual(humanWin.matchWinner, .human)

        let cpuScorekeeper = TennisMatchScorekeeper(initialServer: .cpu)
        for _ in 0..<11 { _ = cpuScorekeeper.recordPoint(winner: .cpu) }
        XCTAssertEqual(cpuScorekeeper.score.matchWinner, .cpu)
    }

    func testCoordinatorAdvancesOneTickScoresPointAndResetsPoint() {
        let simulation = makeSimulation(pointEnd: .serveFault(server: .human, landing: TennisPoint(x: 6000, y: 2500)))
        let coordinator = TennisMatchCoordinator(
            simulation: simulation,
            scorekeeper: TennisMatchScorekeeper(initialServer: .human),
            humanController: humanController(),
            cpuController: TennisCPUController(policy: TennisCPUDecisionPolicy(reactionDelayTicks: 0, rallyFloor: 6), random: SeededTennisRandomSource(seed: 7))
        )
        let delegate = MatchRecorder()
        coordinator.delegate = delegate

        coordinator.step(16)

        XCTAssertEqual(simulation.state.tick, 2)
        XCTAssertEqual(coordinator.score.humanPoints, 0)
        XCTAssertEqual(coordinator.score.cpuPoints, 1)
        XCTAssertEqual(coordinator.score.server, .human)
        XCTAssertNil(simulation.state.pointEnd)
        XCTAssertFalse(simulation.state.ball.isInFlight)
        XCTAssertEqual(delegate.pointWinners, [.cpu])
    }

    func testCoordinatorAwardsEveryPointEndReasonExactlyOnce() {
        let cases: [(PointEndReason, TennisSide)] = [
            (.secondBounce(side: .human), .cpu),
            (.netFault(hitter: .human), .cpu),
            (.outOfBounds(hitter: .cpu), .human),
            (.serveFault(server: .human, landing: TennisPoint(x: 6000, y: 2500)), .cpu)
        ]

        for (reason, expectedWinner) in cases {
            let simulation = makeSimulation(pointEnd: reason)
            let coordinator = TennisMatchCoordinator(
                simulation: simulation,
                scorekeeper: TennisMatchScorekeeper(initialServer: .human),
                humanController: humanController(),
                cpuController: TennisCPUController(policy: TennisCPUDecisionPolicy(reactionDelayTicks: 0, rallyFloor: 6), random: SeededTennisRandomSource(seed: 9))
            )
            let delegate = MatchRecorder()
            coordinator.delegate = delegate

            coordinator.step(16)

            XCTAssertEqual(delegate.pointWinners, [expectedWinner])
            XCTAssertNil(simulation.state.pointEnd)
        }
    }

    func testCoordinatorStopsAfterMatchCompletion() {
        let scorekeeper = TennisMatchScorekeeper(initialServer: .human)
        for _ in 0..<10 { _ = scorekeeper.recordPoint(winner: .human) }
        for _ in 0..<9 { _ = scorekeeper.recordPoint(winner: .cpu) }
        let simulation = makeSimulation(pointEnd: .outOfBounds(hitter: .cpu))
        let coordinator = TennisMatchCoordinator(
            simulation: simulation,
            scorekeeper: scorekeeper,
            humanController: humanController(),
            cpuController: TennisCPUController(policy: TennisCPUDecisionPolicy(reactionDelayTicks: 0, rallyFloor: 6), random: SeededTennisRandomSource(seed: 8))
        )
        let delegate = MatchRecorder()
        coordinator.delegate = delegate

        coordinator.step(16)
        XCTAssertEqual(coordinator.score.matchWinner, .human)
        XCTAssertEqual(delegate.completedWinners, [.human])
        let tickAfterCompletion = simulation.state.tick
        coordinator.step(16)
        XCTAssertEqual(simulation.state.tick, tickAfterCompletion)
    }

    private func humanController() -> TennisHumanController {
        TennisHumanController(inputRouter: TennisInputRouter(
            humanInput: EmptyInputSource(),
            sequenceResolver: DefaultTennisShotSequenceResolver(),
            initialFrame: TennisInputFrame(direction: TennisDirection(x: 0, y: 0), pressedButtons: [], heldButtons: [])
        ))
    }

    private func makeSimulation(pointEnd: PointEndReason) -> TennisSimulation {
        let boundary = TennisRect(minX: 0, minY: 0, maxX: 10000, maxY: 20000)
        let box = TennisRect(minX: 0, minY: 0, maxX: 5000, maxY: 5000)
        let bottomBox = TennisRect(minX: 0, minY: 15000, maxX: 5000, maxY: 20000)
        let court = CourtRules(surface: .hard, singlesBoundary: boundary, serviceBoxes: TennisServiceBoxes(topLeft: box, topRight: box, bottomLeft: bottomBox, bottomRight: bottomBox), netY: 10000)
        let stats = PlayerStats(power: 100, speed: 100, control: 100, spin: 100)
        let players = [
            TennisSide.human: TennisPlayerState(side: .human, position: TennisPoint(x: 5000, y: 20000), stats: stats, preset: .balanced),
            TennisSide.cpu: TennisPlayerState(side: .cpu, position: TennisPoint(x: 5000, y: 0), stats: stats, preset: .power)
        ]
        let ball = TennisBallState(position: TennisPoint(x: 5000, y: 20000), height: 0, velocity: TennisVelocity(x: 0, y: 0, z: 0), shotKind: .serve, lastHitter: nil, isInFlight: false)
        let state = TennisSimulationState(tick: 0, server: .human, players: players, ball: ball, pointEnd: pointEnd)
        return TennisSimulation(rules: court, ruleBook: DefaultTennisRuleBook(), random: SeededTennisRandomSource(seed: 4), state: state)
    }
}

private final class EmptyInputSource: TennisHumanInputSource {
    func frame(for controller: VirtualController) -> TennisInputFrame {
        TennisInputFrame(direction: TennisDirection(x: 0, y: 0), pressedButtons: [], heldButtons: [])
    }
}

private final class MatchRecorder: TennisMatchDelegate {
    var pointWinners: [TennisSide] = []
    var completedWinners: [TennisSide] = []

    func matchDidEndPoint(_ reason: PointEndReason, winner: TennisSide, score: TennisMatchScore) {
        pointWinners.append(winner)
    }

    func matchDidComplete(_ winner: TennisSide, score: TennisMatchScore) {
        completedWinners.append(winner)
    }
}

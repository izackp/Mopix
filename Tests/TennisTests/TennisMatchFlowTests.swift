import XCTest
import GameEngine
import SDL2
@testable import Tennis
@testable import TennisCore
@testable import TennisInput

final class TennisMatchFlowTests: XCTestCase {
    @MainActor
    func testTennisAppRegistersOneDeterministicCoordinatorGraph() throws {
        let first = TennisApp.makeSimulation().snapshot()
        let second = TennisApp.makeSimulation().snapshot()
        XCTAssertEqual(first, second)

        let app = try TennisApp()
        let graph = app.integrationGraph
        XCTAssertEqual(graph.fixedCount, 1)
        XCTAssertEqual(graph.eventCount, 1)
        XCTAssertTrue(graph.coordinator === app.integrationGraph.coordinator)
        app.isRunning = false
    }

    @MainActor
    func testSelectedSurfaceReplacesSceneAndApplicationCoordinatorIdentity() throws {
        let app = try TennisApp()
        let initial = app.integrationGraph.coordinator
        let flow = app.integrationPresentation
        let surfaces: [CourtSurface] = [.hard, .clay, .grass]

        for (index, surface) in surfaces.enumerated() {
            if index == 0 { flow.onCommand(.start) }
            flow.onCommand(.chooseSurface(surface))
            guard let selected = flow.integrationCoordinator else {
                return XCTFail("surface selection did not create a coordinator for \(surface)")
            }
            XCTAssertFalse(selected === initial)
            XCTAssertEqual(selected.simulation.rules.surface, surface)
            XCTAssertTrue(app.integrationSceneCoordinator === selected)
            XCTAssertTrue(app.integrationRegisteredCoordinator === selected)
            XCTAssertEqual(app.integrationGraph.fixedCount, 1)
            XCTAssertEqual(app.integrationGraph.eventCount, 1)

            flow.matchDidComplete(.human, score: TennisMatchScore(humanPoints: 11, cpuPoints: 0, server: .human, matchWinner: .human))
            flow.onCommand(.continue)
            XCTAssertNil(app.integrationRegisteredCoordinator)
            XCTAssertEqual(app.integrationGraph.fixedCount, 0)
            XCTAssertEqual(app.integrationGraph.eventCount, 0)
            XCTAssertTrue(app.integrationSceneCoordinator === selected)
        }
        app.isRunning = false
    }

    func testPresentationFlowHoldsResultUntilContinue() {
        let flow = TennisPresentationFlow(matchFactory: { _ in
            TennisMatchCoordinator(simulation: self.makeSimulation(), scorekeeper: TennisMatchScorekeeper(initialServer: .human), humanController: self.humanController(), cpuController: TennisCPUController(policy: TennisCPUDecisionPolicy(reactionDelayTicks: 0, rallyFloor: 6), random: SeededTennisRandomSource(seed: 3)))
        }, textRenderer: CommandTextRenderer())
        XCTAssertEqual(flow.state.screen, .title)
        flow.onCommand(.start)
        XCTAssertEqual(flow.state.screen, .surfaceSelect)
        flow.onCommand(.chooseSurface(.grass))
        XCTAssertEqual(flow.state.screen, .match)
        flow.matchDidComplete(.human, score: TennisMatchScore(humanPoints: 11, cpuPoints: 0, server: .human, matchWinner: .human))
        XCTAssertEqual(flow.state.screen, .result)
        XCTAssertEqual(flow.state.result?.winner, .human)
        flow.onCommand(.continue)
        XCTAssertEqual(flow.state.screen, .surfaceSelect)
        XCTAssertNil(flow.state.result)
    }

    func testFeedbackReducerDistinguishesFaultsAndSurfaceCues() {
        let reducer = TennisMatchFeedbackReducer()
        reducer.consume(.shotHit(side: .human, shot: .topspin), tick: 1)
        XCTAssertEqual(reducer.state.shotTrail?.color, SDLColor(rawValue: 0xFFE34B4B))
        reducer.consume(.bounce(surface: .clay), tick: 1)
        XCTAssertEqual(reducer.state.surfaceBounce?.surface, .clay)
        reducer.consume(.netContact, tick: 2)
        XCTAssertEqual(reducer.state.pointEnd?.kind, .netFault)
        reducer.consume(.outOfBounds, tick: 3)
        XCTAssertEqual(reducer.state.pointEnd?.kind, .outOfBounds)
        reducer.consume(.serveFault(landing: TennisPoint(x: 1, y: 2)), tick: 4)
        XCTAssertEqual(reducer.state.faultCallout?.text, "FAULT")
    }

    func testPresentationUsesTextCommandsForMenuAndResultLabels() {
        let text = CommandTextRenderer()
        let flow = TennisPresentationFlow(matchFactory: { _ in
            TennisMatchCoordinator(simulation: self.makeSimulation(), scorekeeper: TennisMatchScorekeeper(initialServer: .human), humanController: self.humanController(), cpuController: TennisCPUController(policy: TennisCPUDecisionPolicy(reactionDelayTicks: 0, rallyFloor: 6), random: SeededTennisRandomSource(seed: 3)))
        }, textRenderer: text)
        let renderer = makeRenderer()

        flow.draw(renderer: renderer)
        XCTAssertEqual(text.labels, ["TENNIS", "PRESS A"])
        flow.onCommand(.start)
        flow.draw(renderer: renderer)
        XCTAssertEqual(Array(text.labels.suffix(2)), ["SURFACE", "1 HARD  2 CLAY  3 GRASS"])
        flow.onCommand(.chooseSurface(.grass))
        flow.matchDidComplete(.human, score: TennisMatchScore(humanPoints: 11, cpuPoints: 0, server: .human, matchWinner: .human))
        flow.draw(renderer: renderer)
        XCTAssertEqual(Array(text.labels.suffix(2)), ["PLAYER WINS", "PRESS A"])
    }

    @MainActor
    func testHeadlessEvidenceCoversSelectedMatchFeedbackResultHoldAndContinue() {
        let text = CommandTextRenderer()
        var createdCoordinator: TennisMatchCoordinator?
        let flow = TennisPresentationFlow(matchFactory: { surface in
            let coordinator = TennisApp.makeCoordinator(surface: surface)
            createdCoordinator = coordinator
            return coordinator
        }, textRenderer: text)
        let sink = TennisHeadlessEvidenceSink()

        func drawFlowFrame() {
            text.labels.removeAll()
            let renderer = makeRenderer()
            flow.draw(renderer: renderer)
            sink.observe(flow.makeObservation(glyphTexts: text.labels, drawCommandIDs: commandIDs(in: renderer)))
        }

        drawFlowFrame()
        flow.onCommand(.start)
        drawFlowFrame()
        flow.onCommand(.chooseSurface(.grass))
        guard let coordinator = createdCoordinator else {
            return XCTFail("surface selection did not create a coordinator")
        }

        let scene = TennisScene(coordinator: coordinator)
        coordinator.simulationDidEmit(TennisSimulationEvent(tick: 0, kind: .shotHit(side: .human, shot: .topspin, quality: .good)))
        coordinator.simulationDidEmit(TennisSimulationEvent(tick: 0, kind: .bounce(surface: .grass)))
        let matchRenderer = makeRenderer()
        scene.draw(0, matchRenderer)
        XCTAssertEqual(scene.integrationFeedback.surfaceBounce?.surface, .grass)
        XCTAssertNotNil(scene.integrationFeedback.shotTrail)
        let matchIDs = commandIDs(in: matchRenderer)
        XCTAssertTrue(matchIDs.contains(19))
        sink.observe(flow.makeObservation(feedback: scene.integrationFeedback,
                                          glyphTexts: ["HUD SCORE", "ACTIVE CHARGE"], drawCommandIDs: matchIDs))

        flow.matchDidComplete(.human, score: TennisMatchScore(humanPoints: 11, cpuPoints: 0, server: .human, matchWinner: .human))
        drawFlowFrame()
        let heldResult = sink.finish().last!
        drawFlowFrame()
        let observationsDuringHold = sink.finish().filter { $0.screen == .result }
        XCTAssertEqual(observationsDuringHold.count, 2)
        XCTAssertEqual(observationsDuringHold[0].score, observationsDuringHold[1].score)
        XCTAssertEqual(observationsDuringHold[0].result?.winner, .human)
        XCTAssertEqual(observationsDuringHold[0].result?.score.humanPoints, 11)
        XCTAssertEqual(observationsDuringHold[0].glyphTexts, ["PLAYER WINS", "PRESS A"])

        flow.onCommand(.continue)
        drawFlowFrame()
        let trace = sink.finish()
        XCTAssertEqual(trace.map(\.screen), [.title, .surfaceSelect, .match, .result, .result, .surfaceSelect])
        XCTAssertEqual(heldResult.screen, .result)
        XCTAssertNil(trace.last?.score)
        XCTAssertEqual(trace.last?.glyphTexts, ["SURFACE", "1 HARD  2 CLAY  3 GRASS"])
        XCTAssertNil(trace.last?.result)
        XCTAssertNil(trace.last?.feedback.surfaceBounce)
        XCTAssertTrue(trace[2].selectedSurface == .grass)
        XCTAssertTrue(trace[2].activeMatchSurface == .grass)
        XCTAssertNotNil(trace[2].coordinatorIdentity)
        XCTAssertTrue(trace[2].feedback.surfaceBounce?.surface == .grass)
        XCTAssertTrue(trace[2].drawCommandIDs.contains(19))
    }

    @MainActor
    func testSurfaceFactoryPropagatesSelectedCourtSurface() {
        XCTAssertEqual(TennisApp.makeCoordinator(surface: .hard).simulation.rules.surface, .hard)
        XCTAssertEqual(TennisApp.makeCoordinator(surface: .clay).simulation.rules.surface, .clay)
        XCTAssertEqual(TennisApp.makeCoordinator(surface: .grass).simulation.rules.surface, .grass)
    }

    func testCoordinatorPublishesHumanAndCPUActiveCharge() {
        let human = TennisMatchCoordinator(
            simulation: makeSimulation(), scorekeeper: TennisMatchScorekeeper(initialServer: .human),
            humanController: humanController(),
            cpuController: TennisCPUController(policy: TennisCPUDecisionPolicy(reactionDelayTicks: 0, rallyFloor: 6), random: SeededTennisRandomSource(seed: 3))
        )
        human.step(16)
        XCTAssertEqual(human.latestCharge.activeSide, .human)

        let cpu = TennisMatchCoordinator(
            simulation: makeSimulation(server: .cpu), scorekeeper: TennisMatchScorekeeper(initialServer: .cpu),
            humanController: humanController(),
            cpuController: TennisCPUController(policy: TennisCPUDecisionPolicy(reactionDelayTicks: 0, rallyFloor: 6), random: SeededTennisRandomSource(seed: 3))
        )
        cpu.step(16)
        XCTAssertEqual(cpu.latestCharge.activeSide, .cpu)
        XCTAssertGreaterThanOrEqual(cpu.latestCharge.value, 0)
        XCTAssertEqual(cpu.latestCharge.capReached, cpu.latestCharge.value >= 100)
    }

    func testEachSurfaceBounceProducesDistinctCueAndAudioHook() {
        for (surface, expectedID) in [(CourtSurface.hard, UInt64(17)), (.clay, 18), (.grass, 19)] {
            let reducer = TennisMatchFeedbackReducer()
            var heard: CourtSurface?
            reducer.surfaceBounceAudioHook = { heard = $0 }
            reducer.consume(.bounce(surface: surface), tick: 0)
            XCTAssertEqual(heard, surface)

            let coordinator = TennisMatchCoordinator(
                simulation: makeSimulation(), scorekeeper: TennisMatchScorekeeper(initialServer: .human),
                humanController: humanController(),
                cpuController: TennisCPUController(policy: TennisCPUDecisionPolicy(reactionDelayTicks: 0, rallyFloor: 6), random: SeededTennisRandomSource(seed: 3))
            )
            coordinator.simulationDidEmit(TennisSimulationEvent(tick: 0, kind: .bounce(surface: surface)))
            let scene = TennisScene(coordinator: coordinator)
            let renderer = makeRenderer()
            scene.draw(0, renderer)
            let commands = Mirror(reflecting: renderer).children.first { $0.label == "cmdList" }?.value as? [DrawCmd]
            XCTAssertNotNil(commands?.first(where: { $0.animationId == expectedID }))
        }
    }

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

        XCTAssertEqual(simulation.state.tick, 1)
        XCTAssertEqual(coordinator.score.humanPoints, 0)
        XCTAssertEqual(coordinator.score.cpuPoints, 1)
        XCTAssertEqual(coordinator.score.server, .human)
        XCTAssertNil(simulation.state.pointEnd)
        XCTAssertFalse(simulation.state.ball.isInFlight)
        XCTAssertEqual(delegate.pointWinners, [.cpu])

        coordinator.resetMatch(server: .cpu)
        XCTAssertEqual(simulation.state.tick, 1)
        coordinator.step(16)
        XCTAssertEqual(simulation.state.tick, 2)
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

    func testSDLInputReachesHumanControllerOnNextFixedTick() {
        let simulation = makeSimulation()
        let router = TennisInputRouter(
            humanInput: EngineInputSource(),
            sequenceResolver: DefaultTennisShotSequenceResolver(sequenceExpiryTicks: 1),
            initialFrame: TennisInputFrame(direction: TennisDirection(x: 0, y: 0), pressedButtons: [], heldButtons: [])
        )
        let coordinator = TennisMatchCoordinator(
            simulation: simulation,
            scorekeeper: TennisMatchScorekeeper(initialServer: .human),
            humanController: TennisHumanController(inputRouter: router),
            cpuController: TennisCPUController(policy: TennisCPUDecisionPolicy(reactionDelayTicks: 0, rallyFloor: 6), random: SeededTennisRandomSource(seed: 10))
        )
        var keyDown = SDL_Event()
        keyDown.type = UInt32(SDL_KEYDOWN.rawValue)
        keyDown.key.keysym.sym = 99
        var keyUp = SDL_Event()
        keyUp.type = UInt32(SDL_KEYUP.rawValue)
        keyUp.key.keysym.sym = 99

        coordinator.onEvents([keyDown])
        coordinator.step(16)
        XCTAssertFalse(simulation.state.ball.isInFlight)
        coordinator.onEvents([keyUp])
        coordinator.step(16)
        XCTAssertTrue(simulation.state.ball.isInFlight)
        XCTAssertEqual(simulation.state.ball.shotKind, .serve)
    }

    func testSceneProjectsSnapshotPositionsIntoCourtCommands() {
        let simulation = makeSimulation(
            humanPosition: TennisPoint(x: 0, y: 20000),
            cpuPosition: TennisPoint(x: 10000, y: 0),
            ballPosition: TennisPoint(x: 10000, y: 0)
        )
        let coordinator = TennisMatchCoordinator(
            simulation: simulation,
            scorekeeper: TennisMatchScorekeeper(initialServer: .human),
            humanController: humanController(),
            cpuController: TennisCPUController(policy: TennisCPUDecisionPolicy(reactionDelayTicks: 0, rallyFloor: 6), random: SeededTennisRandomSource(seed: 11))
        )
        let scene = TennisScene(coordinator: coordinator)
        let transport = InProcessTransport.makePair()
        let client = DisplayClient(transport: transport.client, logicalSize: Size(160, 144))
        let renderer = DisplayRenderClient(displayClient: client, windowSize: Size<Int16>(160, 144))

        scene.draw(0, renderer)

        let commands = Mirror(reflecting: renderer).children.first { $0.label == "cmdList" }?.value as? [DrawCmd]
        XCTAssertEqual(commands?.first(where: { $0.animationId == 11 })?.dest, Rect(x: 20, y: 128, width: 8, height: 12))
        XCTAssertEqual(commands?.first(where: { $0.animationId == 12 })?.dest, Rect(x: 132, y: 4, width: 8, height: 12))
        XCTAssertEqual(commands?.first(where: { $0.animationId == 13 })?.dest, Rect(x: 135, y: 9, width: 3, height: 3))
    }

    private func humanController() -> TennisHumanController {
        TennisHumanController(inputRouter: TennisInputRouter(
            humanInput: EmptyInputSource(),
            sequenceResolver: DefaultTennisShotSequenceResolver(),
            initialFrame: TennisInputFrame(direction: TennisDirection(x: 0, y: 0), pressedButtons: [], heldButtons: [])
        ))
    }

    private func makeSimulation(pointEnd: PointEndReason? = nil, server: TennisSide = .human, humanPosition: TennisPoint = TennisPoint(x: 5000, y: 20000), cpuPosition: TennisPoint = TennisPoint(x: 5000, y: 0), ballPosition: TennisPoint = TennisPoint(x: 5000, y: 20000)) -> TennisSimulation {
        let boundary = TennisRect(minX: 0, minY: 0, maxX: 10000, maxY: 20000)
        let box = TennisRect(minX: 0, minY: 0, maxX: 5000, maxY: 5000)
        let bottomBox = TennisRect(minX: 0, minY: 15000, maxX: 5000, maxY: 20000)
        let court = CourtRules(surface: .hard, singlesBoundary: boundary, serviceBoxes: TennisServiceBoxes(topLeft: box, topRight: box, bottomLeft: bottomBox, bottomRight: bottomBox), netY: 10000)
        let stats = PlayerStats(power: 100, speed: 100, control: 100, spin: 100)
        let players = [
            TennisSide.human: TennisPlayerState(side: .human, position: humanPosition, stats: stats, preset: .balanced),
            TennisSide.cpu: TennisPlayerState(side: .cpu, position: cpuPosition, stats: stats, preset: .power)
        ]
        let ball = TennisBallState(position: ballPosition, height: 0, velocity: TennisVelocity(x: 0, y: 0, z: 0), shotKind: .serve, lastHitter: nil, isInFlight: false)
        let state = TennisSimulationState(tick: 0, server: server, players: players, ball: ball, pointEnd: pointEnd)
        return TennisSimulation(rules: court, ruleBook: DefaultTennisRuleBook(), random: SeededTennisRandomSource(seed: 4), state: state)
    }

    private func makeRenderer() -> DisplayRenderClient {
        let transport = InProcessTransport.makePair()
        let client = DisplayClient(transport: transport.client, logicalSize: Size(160, 144))
        return DisplayRenderClient(displayClient: client, windowSize: Size<Int16>(160, 144))
    }

    private func commandIDs(in renderer: DisplayRenderClient) -> [UInt64] {
        let commands = Mirror(reflecting: renderer).children.first { $0.label == "cmdList" }?.value as? [DrawCmd]
        return commands?.map(\.animationId) ?? []
    }
}

private final class CommandTextRenderer: TennisTextRenderer {
    var labels: [String] = []
    func draw(_ text: String, at point: Point<Int>, color: SDLColor, z: Int, renderer: DisplayRenderClient) {
        labels.append(text)
        for (index, _) in text.enumerated() {
            renderer.draw(UInt64(7000 + index), UInt64(8000 + index), Rect(x: point.x + index * 6, y: point.y, width: 5, height: 8), color, z)
        }
    }
}

private final class EmptyInputSource: TennisHumanInputSource {
    func frame(for controller: VirtualController) -> TennisInputFrame {
        TennisInputFrame(direction: TennisDirection(x: 0, y: 0), pressedButtons: [], heldButtons: [])
    }
}

private final class EngineInputSource: TennisHumanInputSource {
    func frame(for controller: VirtualController) -> TennisInputFrame {
        let current = controller.state.buttons
        let previous = controller.statePrevious.buttons
        var held = Set<TennisActionButton>()
        var pressed = Set<TennisActionButton>()
        if current.contains(.action) { held.insert(.a) }
        if current.contains(.action2) { held.insert(.b) }
        if current.contains(.action) && !previous.contains(.action) { pressed.insert(.a) }
        if current.contains(.action2) && !previous.contains(.action2) { pressed.insert(.b) }
        return TennisInputFrame(direction: TennisDirection(x: 0, y: 0), pressedButtons: pressed, heldButtons: held)
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

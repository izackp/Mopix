import XCTest
import GameEngine
@testable import TennisGame

final class TennisPresentationEvidenceTests: XCTestCase {
    private func snapshot() -> TennisMatchSnapshot {
        let human = TennisPlayerState(side: .human, courtEnd: .near, position: TennisPoint(x: 40, y: 100), preset: .balanced)
        let cpu = TennisPlayerState(side: .cpu, courtEnd: .far, position: TennisPoint(x: 120, y: 40), preset: .power)
        return TennisMatchSnapshot(surface: .hard, players: [.human: human, .cpu: cpu], ball: nil, score: TennisScore(human: 0, cpu: 0), server: .human, phase: .rally, matchWinner: nil)
    }

    func testApprovedPaletteUsesExactOpaqueRGBAValues() {
        let palette = TennisPalette.approved
        XCTAssertEqual(palette.canvas.rawValue, 0x10182AFF)
        XCTAssertEqual(palette.primary.rawValue, 0xFFF1C7FF)
        XCTAssertEqual(palette.human.rawValue, 0xF5C451FF)
        XCTAssertEqual(palette.cpu.rawValue, 0xEC6A61FF)
        XCTAssertEqual(palette.ball.rawValue, 0xFFFBEAFF)
        XCTAssertEqual(palette.hardCourt.rawValue, 0x3D93C7FF)
        XCTAssertEqual(palette.clayCourt.rawValue, 0xB9684DFF)
        XCTAssertEqual(palette.grassCourt.rawValue, 0x4D9B65FF)
    }

    func testSmashProducesBothImpactCuesAndNormalShotProducesNeither() {
        var controller = TennisPresentationController()
        let state = snapshot()
        controller.advance(events: [.shotContact(.human, .smash, TennisPoint(x: 80, y: 72), false)], snapshot: state, elapsedMilliseconds: 0)
        XCTAssertTrue(controller.state.cues.contains { $0.kind == .smashFlash })
        XCTAssertTrue(controller.state.cues.contains { $0.kind == .smashStarburst })

        controller.resetForMatch(snapshot: state)
        controller.advance(events: [.shotContact(.human, .topspin, TennisPoint(x: 80, y: 72), true)], snapshot: state, elapsedMilliseconds: 0)
        XCTAssertFalse(controller.state.cues.contains { $0.kind == .smashFlash || $0.kind == .smashStarburst })
    }

    func testFaultCalloutSurvivesPointEndUntilNextServe() {
        var controller = TennisPresentationController()
        let state = snapshot()
        controller.advance(events: [.fault(.out), .pointEnded(.cpu, .outOfBounds)], snapshot: state, elapsedMilliseconds: 0)
        XCTAssertTrue(controller.state.cues.contains { $0.kind == .faultCallout })
        controller.advance(events: [.serveAnticipationStarted(.human)], snapshot: state, elapsedMilliseconds: 0)
        XCTAssertFalse(controller.state.cues.contains { $0.kind == .faultCallout })
    }

    func testFollowThroughAndImpactUseDeclaredLifetimes() {
        var controller = TennisPresentationController()
        let state = snapshot()
        controller.advance(events: [.shotContact(.human, .smash, TennisPoint(x: 80, y: 72), false)], snapshot: state, elapsedMilliseconds: 0)
        XCTAssertEqual(controller.state.players[.human]?.motion, .followThrough)
        XCTAssertNotNil(controller.state.players[.human]?.impactElapsedMilliseconds)
        controller.advance(events: [], snapshot: state, elapsedMilliseconds: 100)
        XCTAssertNil(controller.state.players[.human]?.impactElapsedMilliseconds)
        controller.advance(events: [], snapshot: state, elapsedMilliseconds: 100)
        XCTAssertEqual(controller.state.players[.human]?.motion, .idle)
    }

    func testRendererDrawCommandsCoverRiskPaths() async throws {
        let pair = InProcessTransport.makePair()
        pair.server.handler = { message in
            switch message {
            case let .connect(requestId, _, _, _, _):
                await pair.server.send(.response(Response(requestId: requestId, status: .ok)))
            case let .loadResource(requestId, _, kind, _, preferredHandle):
                if kind == .font {
                    await pair.server.send(.response(Response(requestId: requestId, status: .ok, body: .font(handle: preferredHandle ?? 77, family: "test"))))
                }
            default:
                break
            }
        }
        let client = DisplayClient(transport: pair.client, logicalSize: Size(160, 144))
        try await client.connect(name: "TennisGameTests", version: 1, logicalSize: Size(160, 144))
        let renderClient = DisplayRenderClient(displayClient: client, windowSize: Size<Int16>(160, 144))
        let renderer = TennisRenderer(fontURL: URL(string: "vd://test-font")!)
        try await renderer.loadResources(using: client)

        let match = snapshotWithBall()
        let presentation = presentationWithRiskCues()
        for surface in TennisSurface.allCases {
            renderClient.clearCommands()
            try renderer.draw(
                flow: TennisFlowState(screen: .surfaceSelect, highlightedSurface: surface, result: nil),
                match: nil,
                presentation: presentation,
                using: renderClient
            )
            let commands = commandList(in: renderClient)
            XCTAssertTrue(commands.contains { $0.color.rawValue == TennisPalette.approved.courtColor(for: surface).rawValue })
            switch surface {
            case .hard:
                XCTAssertTrue(commands.contains { if case .line(to: Point(0, 5), thickness: 1) = $0.type { return true }; return false })
            case .clay:
                XCTAssertTrue(commands.contains { if case .line(to: Point(5, 5), thickness: 1) = $0.type { return true }; return false })
            case .grass:
                XCTAssertTrue(commands.contains { if case .line(to: Point(6, 0), thickness: 1) = $0.type { return true }; return false })
            }
            XCTAssertTrue(commands.contains { if case .rect(filled: false) = $0.type { return true }; return false })
        }

        renderClient.clearCommands()
        try renderer.draw(
            flow: TennisFlowState(screen: .match, highlightedSurface: .hard, result: nil),
            match: match,
            presentation: presentation,
            using: renderClient
        )
        let matchCommands = commandList(in: renderClient)
        XCTAssertTrue(matchCommands.contains { if case .circle(radius: 4, filled: true) = $0.type { return true }; return false })
        XCTAssertTrue(matchCommands.filter { $0.color.rawValue == TennisPalette.approved.primary.rawValue }.count >= 8)
        XCTAssertTrue(matchCommands.contains { $0.dest == Rect(x: match.ball!.landing.x - 2, y: match.ball!.landing.y - 2, width: 4, height: 4) && $0.color.rawValue == TennisPalette.approved.canvas.rawValue })
        XCTAssertTrue(matchCommands.contains { $0.color.rawValue == TennisPalette.approved.ball.rawValue })
        XCTAssertTrue(matchCommands.contains { if case .circle(radius: 5, filled: true) = $0.type { return true }; return false })
        XCTAssertTrue(matchCommands.contains { if case .line(to: Point(8, -6), thickness: 1) = $0.type { return true }; return false })

        renderClient.clearCommands()
        try renderer.draw(
            flow: TennisFlowState(screen: .result, highlightedSurface: .hard, result: .human),
            match: nil,
            presentation: presentation,
            using: renderClient
        )
        let resultCommands = commandList(in: renderClient)
        XCTAssertTrue(resultCommands.contains { if case .text(_, let content, _, _) = $0.type { return content == "YOU WIN" }; return false })
        XCTAssertTrue(resultCommands.contains { if case .text(_, let content, _, _) = $0.type { return content == "OUT" }; return false })
        print("runtime draw trace: \(commandTrace(resultCommands))")
    }

    func testSimulationHitstopUsesFixedWindowAndFreezesContactTick() {
        var configuration = TennisGameConfiguration.approvedMVP
        configuration.openingServer = .cpu
        var simulation = TennisSimulation(surface: .hard, configuration: configuration)
        let empty = TennisInputFrame(movement: TennisPoint(x: 0, y: 0), pressedShotButtons: [], shotEvents: [], menuLeftPressed: false, menuRightPressed: false, menuAcceptPressed: false, servePressed: false)
        _ = simulation.advance(input: empty)
        let serve = TennisInputFrame(movement: TennisPoint(x: 0, y: 0), pressedShotButtons: [], shotEvents: [], menuLeftPressed: false, menuRightPressed: false, menuAcceptPressed: false, servePressed: true)
        _ = simulation.advance(input: serve)

        var hitstopTick: TennisTickResult?
        var phaseTrace: [String] = []
        let moveDiagonally = TennisInputFrame(movement: TennisPoint(x: 1, y: -1), pressedShotButtons: [], shotEvents: [], menuLeftPressed: false, menuRightPressed: false, menuAcceptPressed: false, servePressed: false)
        let moveRight = TennisInputFrame(movement: TennisPoint(x: 1, y: 0), pressedShotButtons: [], shotEvents: [], menuLeftPressed: false, menuRightPressed: false, menuAcceptPressed: false, servePressed: false)
        for _ in 0..<24 { _ = simulation.advance(input: moveDiagonally) }
        for _ in 0..<17 { _ = simulation.advance(input: moveRight) }
        for _ in 0..<240 {
            let tick = simulation.advance(input: empty)
            if !tick.events.isEmpty || tick.snapshot.phase != TennisPointPhase.rally { phaseTrace.append("\(tick.snapshot.phase):\(tick.snapshot.ball?.bounceCount ?? -1):\(tick.events)") }
            if tick.snapshot.phase == TennisPointPhase.hitstop { hitstopTick = tick; break }
            if tick.snapshot.ball?.bounceCount == 1 { break }
        }
        guard hitstopTick == nil, simulation.snapshot.ball?.bounceCount == 1 else { return XCTFail("expected a first bounce before human contact: \(phaseTrace)") }
        let smashStart = TennisInputFrame(movement: TennisPoint(x: 0, y: 0), pressedShotButtons: [.a, .b], shotEvents: [.init(button: .a, edge: .pressed), .init(button: .b, edge: .pressed)], menuLeftPressed: false, menuRightPressed: false, menuAcceptPressed: false, servePressed: false)
        let startTick = simulation.advance(input: smashStart)
        if startTick.snapshot.phase == TennisPointPhase.hitstop { hitstopTick = startTick }
        else {
            let smashHeld = TennisInputFrame(movement: TennisPoint(x: 0, y: 0), pressedShotButtons: [.a, .b], shotEvents: [], menuLeftPressed: false, menuRightPressed: false, menuAcceptPressed: false, servePressed: false)
            let contactTick = simulation.advance(input: smashHeld)
            if contactTick.snapshot.phase == TennisPointPhase.hitstop { hitstopTick = contactTick }
        }
        guard let hitstopTick else { return XCTFail("expected deterministic human smash contact: \(startTick.events)") }
        let contactBall = try! XCTUnwrap(hitstopTick.snapshot.ball)
        let held = TennisInputFrame(movement: TennisPoint(x: 0, y: 0), pressedShotButtons: [.a, .b], shotEvents: [], menuLeftPressed: false, menuRightPressed: false, menuAcceptPressed: false, servePressed: false)
        for _ in 0..<6 {
            let heldTick = simulation.advance(input: held)
            XCTAssertEqual(heldTick.snapshot.phase, TennisPointPhase.hitstop)
            XCTAssertEqual(heldTick.snapshot.ball?.elapsedMilliseconds, contactBall.elapsedMilliseconds)
        }
        let resumedWhileHeld = simulation.advance(input: held)
        XCTAssertEqual(resumedWhileHeld.snapshot.phase, TennisPointPhase.rally)
        XCTAssertEqual(resumedWhileHeld.snapshot.ball?.elapsedMilliseconds, contactBall.elapsedMilliseconds)
        let released = TennisInputFrame(movement: TennisPoint(x: 0, y: 0), pressedShotButtons: [], shotEvents: [.init(button: .a, edge: .released), .init(button: .b, edge: .released)], menuLeftPressed: false, menuRightPressed: false, menuAcceptPressed: false, servePressed: false)
        let resumed = simulation.advance(input: released)
        XCTAssertEqual(resumed.snapshot.phase, TennisPointPhase.rally)
    }

    private func snapshotWithBall() -> TennisMatchSnapshot {
        var state = snapshot()
        state.ball = TennisBallFlight(hitter: .human, shot: .smash, contactQuality: .perfect, origin: TennisPoint(x: 40, y: 100), landing: TennisPoint(x: 120, y: 40), shadow: TennisPoint(x: 120, y: 40), height: 12, elapsedMilliseconds: 0, contactToBounceMilliseconds: 700, responseWindowMilliseconds: 350, bounceHeight: 12, skidDistance: 8, bounceCount: 0)
        return state
    }

    private func presentationWithRiskCues() -> TennisPresentationState {
        TennisPresentationState(
            cues: [
                TennisCue(kind: .smashFlash, owner: .human, shot: .smash, position: TennisPoint(x: 40, y: 100), callout: nil, elapsedMilliseconds: 0, minimumLifetimeMilliseconds: 100, persistsUntilLanding: false),
                TennisCue(kind: .smashStarburst, owner: .human, shot: .smash, position: TennisPoint(x: 40, y: 100), callout: nil, elapsedMilliseconds: 0, minimumLifetimeMilliseconds: 100, persistsUntilLanding: false),
                TennisCue(kind: .shotDirection, owner: .human, shot: .smash, position: TennisPoint(x: 40, y: 100), callout: nil, elapsedMilliseconds: 0, minimumLifetimeMilliseconds: 300, persistsUntilLanding: false),
                TennisCue(kind: .faultCallout, owner: nil, shot: nil, position: nil, callout: .out, elapsedMilliseconds: 0, minimumLifetimeMilliseconds: 300, persistsUntilLanding: false)
            ],
            players: [.human: TennisPlayerPresentation(motion: .idle, direction: TennisPoint(x: 1, y: 0), shot: nil, elapsedMilliseconds: 0, isChargeCapped: false, impactElapsedMilliseconds: nil), .cpu: TennisPlayerPresentation(motion: .idle, direction: TennisPoint(x: -1, y: 0), shot: nil, elapsedMilliseconds: 0, isChargeCapped: false, impactElapsedMilliseconds: nil)],
            ball: TennisBallPresentation(contactElapsedMilliseconds: nil, bounceElapsedMilliseconds: nil)
        )
    }

    private func commandList(in renderer: DisplayRenderClient) -> [DrawCmd] {
        Mirror(reflecting: renderer).children.first { $0.label == "cmdList" }?.value as? [DrawCmd] ?? []
    }

    private func commandTrace(_ commands: [DrawCmd]) -> String {
        commands.map { "\($0.animationId):\($0.dest.x),\($0.dest.y):\($0.color.rawValue)" }.joined(separator: "|")
    }
}

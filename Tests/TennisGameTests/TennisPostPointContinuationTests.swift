import XCTest
@testable import TennisGame

final class TennisPostPointContinuationTests: XCTestCase {
    private let empty = TennisInputFrame(movement: TennisPoint(x: 0, y: 0), pressedShotButtons: [], shotEvents: [], menuLeftPressed: false, menuRightPressed: false, menuAcceptPressed: false, servePressed: false)
    private let serve = TennisInputFrame(movement: TennisPoint(x: 0, y: 0), pressedShotButtons: [], shotEvents: [], menuLeftPressed: false, menuRightPressed: false, menuAcceptPressed: false, servePressed: true)

    private func tickToPointEnd(_ simulation: inout TennisSimulation, maxTicks: Int = 300) -> TennisTickResult {
        _ = simulation.advance(input: empty)
        _ = simulation.advance(input: serve)
        var ended: TennisTickResult?
        for _ in 0..<maxTicks {
            let tick = simulation.advance(input: empty)
            if tick.snapshot.phase == .ended { ended = tick; break }
        }
        return ended!
    }

    // MARK: Ball continuation for each of the four point-ending reasons

    func testBallContinuesSlidingNotNulledAfterOutOfBoundsServeAndRestsInPlayArea() {
        var configuration = TennisGameConfiguration.approvedMVP
        configuration.humanServeBox = TennisRect(minX: -100, minY: 40, maxX: -100, maxY: 40)
        var simulation = TennisSimulation(surface: .hard, configuration: configuration)
        let ended = tickToPointEnd(&simulation)
        XCTAssertTrue(ended.events.contains(.pointEnded(.cpu, .outOfBounds)), "terminal events: \(ended.events)")
        assertBallSlidesAndRestsInBounds(&simulation)
    }

    func testBallContinuesSlidingNotNulledAfterIllegalServeAndRestsInPlayArea() {
        var configuration = TennisGameConfiguration.approvedMVP
        configuration.humanServeBox = TennisRect(minX: 80, minY: 40, maxX: 80, maxY: 40)
        var simulation = TennisSimulation(surface: .hard, configuration: configuration)
        let ended = tickToPointEnd(&simulation)
        XCTAssertTrue(ended.events.contains(.pointEnded(.cpu, .illegalServe)), "terminal events: \(ended.events)")
        assertBallSlidesAndRestsInBounds(&simulation)
    }

    func testBallContinuesSlidingNotNulledAfterSecondBounceAndRestsInPlayArea() {
        var configuration = TennisGameConfiguration.approvedMVP
        configuration.openingServer = .cpu
        var simulation = TennisSimulation(surface: .hard, configuration: configuration)
        let ended = tickToPointEnd(&simulation, maxTicks: 180)
        XCTAssertTrue(ended.events.contains(.pointEnded(.human, .secondBounce)), "terminal events: \(ended.events)")
        assertBallSlidesAndRestsInBounds(&simulation)
    }

    func testBallContinuesSlidingNotNulledAfterNetFaultAndRestsInPlayArea() {
        var configuration = TennisGameConfiguration.approvedMVP
        configuration.openingServer = .cpu
        var simulation = TennisSimulation(surface: .hard, configuration: configuration)
        let moveDiagonally = TennisInputFrame(movement: TennisPoint(x: 1, y: -1), pressedShotButtons: [], shotEvents: [], menuLeftPressed: false, menuRightPressed: false, menuAcceptPressed: false, servePressed: false)
        let moveRight = TennisInputFrame(movement: TennisPoint(x: 1, y: 0), pressedShotButtons: [], shotEvents: [], menuLeftPressed: false, menuRightPressed: false, menuAcceptPressed: false, servePressed: false)
        _ = simulation.advance(input: empty)
        _ = simulation.advance(input: serve)
        for _ in 0..<24 { _ = simulation.advance(input: moveDiagonally) }
        for _ in 0..<8 { _ = simulation.advance(input: moveRight) }
        var settled = false
        for _ in 0..<240 {
            let tick = simulation.advance(input: empty)
            if tick.snapshot.ball?.consecutiveGroundContacts == 1 { settled = true; break }
        }
        XCTAssertTrue(settled)
        let bothPressed = TennisInputFrame(movement: TennisPoint(x: 0, y: 0), pressedShotButtons: [.a, .b], shotEvents: [.init(button: .a, edge: .pressed), .init(button: .b, edge: .pressed)], menuLeftPressed: false, menuRightPressed: false, menuAcceptPressed: false, servePressed: false)
        _ = simulation.advance(input: bothPressed)
        let held = TennisInputFrame(movement: TennisPoint(x: 0, y: 0), pressedShotButtons: [.a, .b], shotEvents: [], menuLeftPressed: false, menuRightPressed: false, menuAcceptPressed: false, servePressed: false)
        var ended: TennisTickResult?
        for _ in 0..<40 {
            let tick = simulation.advance(input: held)
            if tick.snapshot.phase == .ended { ended = tick; break }
        }
        XCTAssertTrue(try! XCTUnwrap(ended).events.contains(.fault(.net)))
        assertBallSlidesAndRestsInBounds(&simulation)
    }

    /// A fault's landing point itself can legitimately sit outside the play area (that is what
    /// "out of bounds" means) — the clamp requirement is about where the skid comes to *rest*, not
    /// about every transient sample while it slides there. So this only asserts non-nil throughout,
    /// and in-bounds once the fixed short skid duration has fully elapsed.
    private func assertBallSlidesAndRestsInBounds(_ simulation: inout TennisSimulation) {
        XCTAssertNotNil(simulation.snapshot.ball, "the ball must not be nulled when a point ends")
        var lastBall: TennisBallFlight?
        for _ in 0..<50 {
            let tick = simulation.advance(input: empty)
            guard let ball = tick.snapshot.ball else { return XCTFail("ball was nulled during the post-point continuation") }
            lastBall = ball
        }
        let resting = try! XCTUnwrap(lastBall)
        XCTAssertTrue((0...159).contains(resting.position.x), "resting ball x \(resting.position.x) left the visible play area")
        XCTAssertTrue((0...143).contains(resting.position.y), "resting ball y \(resting.position.y) left the visible play area")
    }

    // MARK: Score overlay cue lifetime

    func testScoreOverlayCueAppearsOnPointEndAndExpiresAt2Seconds() {
        var controller = TennisPresentationController()
        let human = TennisPlayerState(side: .human, courtEnd: .near, position: TennisPoint(x: 40, y: 100), preset: .balanced)
        let cpu = TennisPlayerState(side: .cpu, courtEnd: .far, position: TennisPoint(x: 120, y: 40), preset: .power)
        let snapshot = TennisMatchSnapshot(surface: .hard, players: [.human: human, .cpu: cpu], ball: nil, score: TennisScore(human: 3, cpu: 2), server: .human, phase: .ended, liveBallPhase: .pointEnding, matchWinner: nil)
        controller.advance(events: [.pointEnded(.human, .secondBounce)], snapshot: snapshot, elapsedMilliseconds: 0)
        XCTAssertTrue(controller.state.cues.contains { $0.kind == .scoreOverlay })
        controller.advance(events: [], snapshot: snapshot, elapsedMilliseconds: 1999)
        XCTAssertTrue(controller.state.cues.contains { $0.kind == .scoreOverlay }, "overlay must not expire before its 2.0s minimum lifetime")
        controller.advance(events: [], snapshot: snapshot, elapsedMilliseconds: 1)
        XCTAssertFalse(controller.state.cues.contains { $0.kind == .scoreOverlay }, "overlay must expire once its 2.0s minimum lifetime elapses")
    }

    // MARK: Next-serve delay

    func testNextServeSetupWaitsFor2SecondsThenClearsBallForANormalPoint() {
        var configuration = TennisGameConfiguration.approvedMVP
        configuration.humanServeBox = TennisRect(minX: 80, minY: 40, maxX: 80, maxY: 40)
        var simulation = TennisSimulation(surface: .hard, configuration: configuration)
        let ended = tickToPointEnd(&simulation)
        XCTAssertNil(ended.snapshot.matchWinner)

        for tickIndex in 0..<124 {
            let tick = simulation.advance(input: empty)
            XCTAssertEqual(tick.snapshot.phase, .ended, "next-serve setup must not fire before 2.0s (tick \(tickIndex))")
            XCTAssertNotNil(tick.snapshot.ball)
        }
        let afterWindow = simulation.advance(input: empty)
        XCTAssertNotEqual(afterWindow.snapshot.phase, .ended, "next-serve setup must fire once 2.0s elapses")
        XCTAssertNil(afterWindow.snapshot.ball, "beginPoint() must clear the ball for the new point")
    }

    // MARK: Match-ending point keeps matchWinner and delays the overlay-gated transition

    func testMatchEndingPointKeepsMatchWinnerIntactAndOverlayGatesTheResultTransition() {
        // Both serve boxes are unreachable, so every serve faults and the receiver always wins the
        // point. The server alternates strictly every 2 points (GAME-2), so the leading side's
        // margin oscillates but climbs; deterministically, the 22nd point pushes the score to
        // 12-10, crossing the win-by-2-at-11 threshold.
        var configuration = TennisGameConfiguration.approvedMVP
        configuration.humanServeBox = TennisRect(minX: -1000, minY: -1000, maxX: -1000, maxY: -1000)
        configuration.cpuServeBox = TennisRect(minX: -1000, minY: -1000, maxX: -1000, maxY: -1000)
        var simulation = TennisSimulation(surface: .hard, configuration: configuration)
        var presentation = TennisPresentationController()
        presentation.resetForMatch(snapshot: simulation.snapshot)

        var input = empty
        var matchEndedTick: TennisTickResult?
        for _ in 0..<8000 {
            let tick = simulation.advance(input: input)
            presentation.advance(events: tick.events, snapshot: tick.snapshot, elapsedMilliseconds: 16)
            input = tick.snapshot.phase == .awaitingServeInput ? serve : empty
            if tick.snapshot.matchWinner != nil { matchEndedTick = tick; break }
        }
        let ended = try! XCTUnwrap(matchEndedTick, "expected the match to reach a winner")
        let winner = try! XCTUnwrap(ended.snapshot.matchWinner)
        XCTAssertTrue(ended.events.contains(.matchEnded(winner)), "terminal events: \(ended.events)")
        XCTAssertTrue(presentation.state.cues.contains { $0.kind == .scoreOverlay }, "the overlay must appear so the controller can gate the .result transition on it")

        // matchWinner must never be cleared afterward — the `snapshot.matchWinner == nil` guard on
        // beginPoint() must hold even once phaseElapsedMilliseconds crosses 2.0s repeatedly.
        for _ in 0..<300 {
            let tick = simulation.advance(input: empty)
            presentation.advance(events: tick.events, snapshot: tick.snapshot, elapsedMilliseconds: 16)
            XCTAssertEqual(tick.snapshot.matchWinner, winner, "matchWinner must remain intact once the match has ended")
            XCTAssertEqual(tick.snapshot.phase, .ended, "a match-ending point must never resume into a new point")
        }
        XCTAssertFalse(presentation.state.cues.contains { $0.kind == .scoreOverlay }, "the overlay must have expired by now, which is what actually unblocks the controller's .result transition")
    }
}

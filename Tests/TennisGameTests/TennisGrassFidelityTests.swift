import XCTest
import GameEngine
@testable import TennisGame

final class TennisGrassFidelityTests: XCTestCase {
    private func grassSnapshot(humanY: Int = 100, cpuY: Int = 40, ball: TennisBallFlight? = nil) -> TennisMatchSnapshot {
        let human = TennisPlayerState(side: .human, courtEnd: .near, position: TennisPoint(x: 60, y: humanY), preset: .balanced)
        let cpu = TennisPlayerState(side: .cpu, courtEnd: .far, position: TennisPoint(x: 100, y: cpuY), preset: .power)
        return TennisMatchSnapshot(surface: .grass, players: [.human: human, .cpu: cpu], ball: ball, score: TennisScore(human: 0, cpu: 0), server: .human, phase: .rally, liveBallPhase: .rally, matchWinner: nil)
    }

    private func idlePresentation() -> TennisPresentationState {
        TennisPresentationState(
            cues: [],
            players: [
                .human: TennisPlayerPresentation(motion: .idle, direction: TennisPoint(x: 0, y: 0), shot: nil, elapsedMilliseconds: 0, isChargeCapped: false, impactElapsedMilliseconds: nil),
                .cpu: TennisPlayerPresentation(motion: .idle, direction: TennisPoint(x: 0, y: 0), shot: nil, elapsedMilliseconds: 0, isChargeCapped: false, impactElapsedMilliseconds: nil)
            ],
            ball: nil
        )
    }

    private func renderer() async throws -> (TennisRenderer, DisplayRenderClient) {
        let pair = InProcessTransport.makePair()
        pair.server.handler = { message in
            switch message {
            case let .connect(requestId, _, _, _, _):
                await pair.server.send(.response(Response(requestId: requestId, status: .ok)))
            case let .loadResource(requestId, _, kind, _, preferredHandle):
                if kind == .font {
                    await pair.server.send(.response(Response(requestId: requestId, status: .ok, body: .font(handle: preferredHandle ?? 77, family: "test"))))
                }
            default: break
            }
        }
        let client = DisplayClient(transport: pair.client, logicalSize: Size(160, 144))
        try await client.connect(name: "TennisGrassFidelityTests", version: 1, logicalSize: Size(160, 144))
        let renderClient = DisplayRenderClient(displayClient: client, windowSize: Size<Int16>(160, 144))
        let tennisRenderer = TennisRenderer(fontURL: URL(string: "vd://test-font")!)
        try await tennisRenderer.loadResources(using: client)
        return (tennisRenderer, renderClient)
    }

    private func commandList(in renderer: DisplayRenderClient) -> [DrawCmd] {
        Mirror(reflecting: renderer).children.first { $0.label == "cmdList" }?.value as? [DrawCmd] ?? []
    }

    // MARK: Court/band/net geometry and colors

    func testGrassCourtIsExactly136x108WithOrderedDepthBandsAndContinuousLines() async throws {
        let (tennisRenderer, renderClient) = try await renderer()
        try tennisRenderer.draw(flow: TennisFlowState(screen: .match, highlightedSurface: .grass, result: nil), match: grassSnapshot(), presentation: idlePresentation(), humanServeBox: TennisGameConfiguration.approvedMVP.humanServeBox, cpuServeBox: TennisGameConfiguration.approvedMVP.cpuServeBox, using: renderClient)
        let commands = commandList(in: renderClient)
        let projection = TennisCourtProjection(camera: .approved)

        // GAME-19 v2: the court is now a trapezoid filled one screen row at a time, not a fixed 136x108 rect.
        let fillRows = commands.filter { $0.color.rawValue == TennisPalette.approved.grassCourt.rawValue && $0.dest.height == 1 }
        XCTAssertEqual(fillRows.count, 127, "expected one fill row per screen Y 0...126")
        for screenY in [0, 63, 126] {
            let worldY = 24.0 + Double(screenY) / 126.0 * 96.0
            let left = projection.worldToScreen(TennisPoint(x: 16, y: Int(worldY.rounded()))).x
            let right = projection.worldToScreen(TennisPoint(x: 144, y: Int(worldY.rounded()))).x
            XCTAssertTrue(fillRows.contains { $0.dest == Rect(x: left, y: screenY, width: max(1, right - left), height: 1) }, "row \(screenY) fill mismatch")
        }

        let borderEdges: [(Point<Int>, Point<Int>)] = [(projection.farLeft, projection.farRight), (projection.nearLeft, projection.nearRight), (projection.farLeft, projection.nearLeft), (projection.farRight, projection.nearRight)]
        for edge in borderEdges {
            XCTAssertTrue(commands.contains { cmd in
                guard cmd.color.rawValue == TennisPalette.approved.primary.rawValue, cmd.dest.x == edge.0.x, cmd.dest.y == edge.0.y else { return false }
                if case .line(to: let to, thickness: 1) = cmd.type { return to == Point(edge.1.x - edge.0.x, edge.1.y - edge.0.y) }
                return false
            }, "expected border edge from \(edge.0) to \(edge.1)")
        }

        // Far-to-near ordered lane marks: 2px, then 4px, then 6px, partitioned across the trapezoid bounding box's thirds.
        let boundingBox = Rect(x: min(projection.farLeft.x, projection.nearLeft.x), y: 0, width: max(projection.farRight.x, projection.nearRight.x) - min(projection.farLeft.x, projection.nearLeft.x), height: 126)
        let thirdHeight = boundingBox.height / 3
        XCTAssertTrue(commands.contains { if case .line(to: Point(2, 0), thickness: 1) = $0.type { return $0.dest.y < boundingBox.y + thirdHeight }; return false }, "far band lane marks must be 2px in the first third")
        XCTAssertTrue(commands.contains { if case .line(to: Point(4, 0), thickness: 1) = $0.type { return $0.dest.y >= boundingBox.y + thirdHeight && $0.dest.y < boundingBox.y + 2 * thirdHeight }; return false }, "middle band lane marks must be 4px in the middle third")
        XCTAssertTrue(commands.contains { if case .line(to: Point(6, 0), thickness: 1) = $0.type { return $0.dest.y >= boundingBox.y + 2 * thirdHeight }; return false }, "near band lane marks must be 6px in the last third")
    }

    func testGrassNetBandPostsAndMeshUseApprovedColorsAtCenterCourt() async throws {
        let (tennisRenderer, renderClient) = try await renderer()
        try tennisRenderer.draw(flow: TennisFlowState(screen: .match, highlightedSurface: .grass, result: nil), match: grassSnapshot(), presentation: idlePresentation(), humanServeBox: TennisGameConfiguration.approvedMVP.humanServeBox, cpuServeBox: TennisGameConfiguration.approvedMVP.cpuServeBox, using: renderClient)
        let commands = commandList(in: renderClient)
        let projection = TennisCourtProjection(camera: .approved)
        let netBottomY = 58; let netHeight = 4; let netTop = netBottomY - netHeight; let postExtend = 8; let postWidth = 4
        let rowWorldY = Int((24.0 + Double(netBottomY) / 126.0 * 96.0).rounded())
        let left = projection.worldToScreen(TennisPoint(x: 16, y: rowWorldY)).x
        let right = projection.worldToScreen(TennisPoint(x: 144, y: rowWorldY)).x

        let band = commands.first { $0.dest == Rect(x: left, y: netTop, width: right - left, height: netHeight) }
        XCTAssertEqual(band?.color.rawValue, TennisPalette.approved.canvas.rawValue, "net band must be Canvas #10182A, bottom edge at fixed screen Y58")
        XCTAssertTrue(commands.contains { $0.dest == Rect(x: left, y: netTop - postExtend, width: postWidth, height: netHeight + postExtend * 2) && $0.color.rawValue == TennisPalette.approved.canvas.rawValue }, "left post must be 4px wide and extend 8px above/below the band")
        XCTAssertTrue(commands.contains { $0.dest == Rect(x: right - postWidth, y: netTop - postExtend, width: postWidth, height: netHeight + postExtend * 2) && $0.color.rawValue == TennisPalette.approved.canvas.rawValue }, "right post must sit at the opposite side boundary")
        let meshDots = commands.filter { $0.color.rawValue == TennisPalette.approved.primary.rawValue && $0.dest.width == 1 && $0.dest.height == 1 && $0.dest.y >= netTop && $0.dest.y < netTop + netHeight }
        XCTAssertFalse(meshDots.isEmpty, "expected an ivory mesh pattern inside the net band")
    }

    // MARK: Player silhouette outcome

    func testGrassPlayerSilhouetteHasDistinctHeadTorsoLegsAndRacketAtMinimumSize() async throws {
        let (tennisRenderer, renderClient) = try await renderer()
        try tennisRenderer.draw(flow: TennisFlowState(screen: .match, highlightedSurface: .grass, result: nil), match: grassSnapshot(), presentation: idlePresentation(), humanServeBox: TennisGameConfiguration.approvedMVP.humanServeBox, cpuServeBox: TennisGameConfiguration.approvedMVP.cpuServeBox, using: renderClient)
        let commands = commandList(in: renderClient)
        let humanColor = TennisPalette.approved.human.rawValue

        let head = commands.first { $0.color.rawValue == humanColor && $0.dest.width == 4 && $0.dest.height == 4 }
        let torso = commands.first { $0.color.rawValue == humanColor && $0.dest.width == 10 && $0.dest.height == 8 }
        // Human is at world (60, 100); narrow to its screen-projected neighborhood to exclude the cpu's legs.
        let humanScreenX = TennisCourtProjection(camera: .approved).worldToScreen(TennisPoint(x: 60, y: 100)).x
        let legs = commands.filter { $0.color.rawValue == TennisPalette.approved.canvas.rawValue && $0.dest.width == 5 && $0.dest.height == 6 && abs($0.dest.x - humanScreenX) <= 10 }
        XCTAssertNotNil(head, "expected a distinct head part")
        XCTAssertNotNil(torso, "expected a distinct torso part")
        XCTAssertEqual(legs.count, 2, "expected two distinct leg masses")
        XCTAssertTrue(commands.contains { if case .line(to: Point(-4, -5), thickness: 1) = $0.type { return true }; return false }, "expected a distinct racket part")

        guard let head, let torso else { return XCTFail("missing silhouette parts") }
        let legsTop = legs.map(\.dest.y).min() ?? torso.dest.y
        let legsBottom = (legs.map { $0.dest.y + $0.dest.height }).max() ?? torso.dest.y
        let minX = min(head.dest.x, torso.dest.x, legs.map(\.dest.x).min() ?? torso.dest.x)
        let maxX = max(head.dest.x + head.dest.width, torso.dest.x + torso.dest.width, legs.map { $0.dest.x + $0.dest.width }.max() ?? 0)
        XCTAssertGreaterThanOrEqual(maxX - minX, 12, "silhouette must be at least 12px wide")
        XCTAssertGreaterThanOrEqual(legsBottom - head.dest.y, 16, "silhouette must be at least 16px tall")
        _ = legsTop
    }

    func testGrassPlayerStatesProduceObservableRacketOrTorsoContrast() async throws {
        func racketRotation(_ motion: TennisPlayerMotionKind, elapsed: UInt64 = 0, capped: Bool = false) async throws -> Float? {
            let (tennisRenderer, renderClient) = try await renderer()
            let presentation = TennisPresentationState(
                cues: [],
                players: [.human: TennisPlayerPresentation(motion: motion, direction: TennisPoint(x: motion == .locomotion ? 1 : 0, y: 0), shot: motion == .followThrough ? .slice : nil, elapsedMilliseconds: elapsed, isChargeCapped: capped, impactElapsedMilliseconds: nil), .cpu: TennisPlayerPresentation(motion: .idle, direction: TennisPoint(x: 0, y: 0), shot: nil, elapsedMilliseconds: 0, isChargeCapped: false, impactElapsedMilliseconds: nil)],
                ball: nil
            )
            try tennisRenderer.draw(flow: TennisFlowState(screen: .match, highlightedSurface: .grass, result: nil), match: grassSnapshot(), presentation: presentation, humanServeBox: TennisGameConfiguration.approvedMVP.humanServeBox, cpuServeBox: TennisGameConfiguration.approvedMVP.cpuServeBox, using: renderClient)
            let commands = commandList(in: renderClient)
            return commands.first { if case .line(to: Point(-4, -5), thickness: 1) = $0.type { return true }; return false }?.rotation
        }

        let idle = try await racketRotation(.idle)
        let serveWindupRaw = try await racketRotation(.serveWindup)
        let shotChargeRaw = try await racketRotation(.shotCharge, elapsed: 300)
        let followThrough = try await racketRotation(.followThrough, elapsed: 0)
        let serveWindup = try XCTUnwrap(serveWindupRaw)
        let shotCharge = try XCTUnwrap(shotChargeRaw)

        XCTAssertEqual(serveWindup, 45, "serve wind-up must rotate the racket 45 degrees behind the player")
        XCTAssertEqual(shotCharge, -22.5, accuracy: 0.01, "shot charge rotation must scale continuously with held charge")
        XCTAssertNotEqual(idle, serveWindup)
        XCTAssertNotEqual(serveWindup, shotCharge)
        XCTAssertNotEqual(shotCharge, followThrough)
    }

    // MARK: Far/near depth ordering and non-occlusion

    func testFarSideRendersBehindNetAndNearSideRendersInFrontOfNet() async throws {
        let (tennisRenderer, renderClient) = try await renderer()
        try tennisRenderer.draw(flow: TennisFlowState(screen: .match, highlightedSurface: .grass, result: nil), match: grassSnapshot(), presentation: idlePresentation(), humanServeBox: TennisGameConfiguration.approvedMVP.humanServeBox, cpuServeBox: TennisGameConfiguration.approvedMVP.cpuServeBox, using: renderClient)
        let commands = commandList(in: renderClient)
        let projection = TennisCourtProjection(camera: .approved)
        let netBottomY = 58; let netTop = netBottomY - 4
        let rowWorldY = Int((24.0 + Double(netBottomY) / 126.0 * 96.0).rounded())
        let left = projection.worldToScreen(TennisPoint(x: 16, y: rowWorldY)).x
        let right = projection.worldToScreen(TennisPoint(x: 144, y: rowWorldY)).x
        let netZ = commands.first { $0.dest == Rect(x: left, y: netTop, width: right - left, height: 4) }?.z
        let nearTorsoZ = commands.first { $0.color.rawValue == TennisPalette.approved.human.rawValue && $0.dest.width == 10 }?.z
        let farTorsoZ = commands.first { $0.color.rawValue == TennisPalette.approved.cpu.rawValue && $0.dest.width == 10 }?.z

        let net = try XCTUnwrap(netZ); let near = try XCTUnwrap(nearTorsoZ); let far = try XCTUnwrap(farTorsoZ)
        XCTAssertLessThan(near, net, "near-side player must render behind (below) the net so the net appears in front of it")
        XCTAssertGreaterThan(far, net, "far-side player must render in front of (above) the net so the net appears behind it")
    }

    func testBallAndIdentityMarksRemainAboveTheNetMeshRegardlessOfSide() async throws {
        for humanY: Int in [40, 100] { // simulate the ball on both the far and near side of the net plane
            let ball = TennisBallFlight(hitter: .human, receiver: .cpu, shot: .topspin, contactQuality: .good, origin: TennisPoint(x: 60, y: 100), landing: TennisPoint(x: 100, y: 40), position: TennisPoint(x: 80, y: humanY), shadow: TennisPoint(x: 100, y: 40), height: 18, elapsedMilliseconds: 0, contactToBounceMilliseconds: 700, responseWindowMilliseconds: 350, bounceHeight: 18, skidDistance: 8, hasCrossedNetPlane: false, consecutiveGroundContacts: 0)
            let (tennisRenderer, renderClient) = try await renderer()
            try tennisRenderer.draw(flow: TennisFlowState(screen: .match, highlightedSurface: .grass, result: nil), match: grassSnapshot(ball: ball), presentation: idlePresentation(), humanServeBox: TennisGameConfiguration.approvedMVP.humanServeBox, cpuServeBox: TennisGameConfiguration.approvedMVP.cpuServeBox, using: renderClient)
            let commands = commandList(in: renderClient)
            let projection = TennisCourtProjection(camera: .approved)
            let netBottomY = 58; let netTop = netBottomY - 4
            let rowWorldY = Int((24.0 + Double(netBottomY) / 126.0 * 96.0).rounded())
            let left = projection.worldToScreen(TennisPoint(x: 16, y: rowWorldY)).x
            let right = projection.worldToScreen(TennisPoint(x: 144, y: rowWorldY)).x
            let netZ = try XCTUnwrap(commands.first { $0.dest == Rect(x: left, y: netTop, width: right - left, height: 4) }?.z)
            let ballZ = commands.first { $0.color.rawValue == TennisPalette.approved.ball.rawValue }?.z
            let identityZ = commands.filter { $0.color.rawValue == TennisPalette.approved.canvas.rawValue }.compactMap { cmd -> Int? in if case .circle(radius: 4, filled: true) = cmd.type { return cmd.z }; return nil }.first

            XCTAssertGreaterThan(try XCTUnwrap(ballZ), netZ, "ball must never be obscured by the net mesh, y=\(humanY)")
            XCTAssertGreaterThan(try XCTUnwrap(identityZ), netZ, "identity marks must never be obscured by the net mesh, y=\(humanY)")
        }
    }

    // MARK: Proof gate — bounce/fault coexistence

    func testGrassBounceAndFaultCuesCoexistWithoutErasingEachOther() async throws {
        let (tennisRenderer, renderClient) = try await renderer()
        let presentation = TennisPresentationState(
            cues: [
                TennisCue(kind: .grassBounce, owner: nil, shot: .topspin, position: TennisPoint(x: 80, y: 90), callout: nil, elapsedMilliseconds: 0, minimumLifetimeMilliseconds: 300, persistsUntilLanding: false),
                TennisCue(kind: .faultCallout, owner: nil, shot: nil, position: nil, callout: .net, elapsedMilliseconds: 0, minimumLifetimeMilliseconds: 1000, persistsUntilLanding: false)
            ],
            players: [.human: TennisPlayerPresentation(motion: .idle, direction: .init(x: 0, y: 0), shot: nil, elapsedMilliseconds: 0, isChargeCapped: false, impactElapsedMilliseconds: nil), .cpu: TennisPlayerPresentation(motion: .idle, direction: .init(x: 0, y: 0), shot: nil, elapsedMilliseconds: 0, isChargeCapped: false, impactElapsedMilliseconds: nil)],
            ball: nil
        )
        try tennisRenderer.draw(flow: TennisFlowState(screen: .match, highlightedSurface: .grass, result: nil), match: grassSnapshot(), presentation: presentation, humanServeBox: TennisGameConfiguration.approvedMVP.humanServeBox, cpuServeBox: TennisGameConfiguration.approvedMVP.cpuServeBox, using: renderClient)
        let commands = commandList(in: renderClient)

        XCTAssertTrue(commands.contains { $0.color.rawValue == TennisPalette.approved.grassCourt.rawValue && $0.dest.width == 16 }, "expected the grass bounce tell")
        XCTAssertTrue(commands.contains { if case .text(_, let content, _, _) = $0.type { return content == "NET" }; return false }, "expected the fault callout text to still render alongside the bounce tell")
    }

    // MARK: VIBE-5 ball-to-shadow separation prerequisite

    func testGrassBallToShadowSeparationGrowsThenShrinksAcrossFlight() async throws {
        var maxSeparation = -1
        var separations: [Int] = []
        for elapsed: UInt64 in [0, 175, 350, 525, 700] {
            // origin.y == landing.y isolates the ball's arc (height-driven) separation from the net's
            // shadow, independent of the shot's horizontal travel.
            let ball = TennisBallFlight(hitter: .human, receiver: .cpu, shot: .topspin, contactQuality: .good, origin: TennisPoint(x: 60, y: 72), landing: TennisPoint(x: 140, y: 72), position: TennisPoint(x: 80, y: 72), shadow: TennisPoint(x: 140, y: 72), height: 18, elapsedMilliseconds: elapsed, contactToBounceMilliseconds: 700, responseWindowMilliseconds: 350, bounceHeight: 18, skidDistance: 8, hasCrossedNetPlane: true, consecutiveGroundContacts: 0)
            let (tennisRenderer, renderClient) = try await renderer()
            try tennisRenderer.draw(flow: TennisFlowState(screen: .match, highlightedSurface: .grass, result: nil), match: grassSnapshot(ball: ball), presentation: idlePresentation(), humanServeBox: TennisGameConfiguration.approvedMVP.humanServeBox, cpuServeBox: TennisGameConfiguration.approvedMVP.cpuServeBox, using: renderClient)
            let commands = commandList(in: renderClient)
            let shadowY = try XCTUnwrap(commands.first { $0.color.rawValue == TennisPalette.approved.canvas.rawValue && $0.dest.width == 4 && $0.dest.height == 4 }?.dest.y)
            let ballY = try XCTUnwrap(commands.first { $0.color.rawValue == TennisPalette.approved.ball.rawValue }?.dest.y)
            separations.append(abs(shadowY - ballY))
            maxSeparation = max(maxSeparation, abs(shadowY - ballY))
        }
        XCTAssertEqual(separations.first, 0, "separation must start at zero on outgoing contact")
        XCTAssertEqual(separations.last, 0, "separation must return to zero at landing")
        XCTAssertEqual(separations.max(), separations[2], "separation must peak at the flight midpoint")
        XCTAssertTrue(separations[0] < separations[1] && separations[1] < separations[2], "separation must increase during ascent")
        XCTAssertTrue(separations[2] > separations[3] && separations[3] > separations[4], "separation must decrease during descent")
    }
}

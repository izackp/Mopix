import Foundation
import GameEngine
import SDL2Swift
import TennisCore
import TennisInput

@MainActor
final class TennisApp: Application {
    static let logicalSize = Size(160, 144)
    private var matchCoordinator: TennisMatchCoordinator!
    private var presentation: TennisPresentationFlow!
    private var scene: TennisScene!
    private var headlessScenario: TennisHeadlessScenario?
    private(set) var registeredFixedCoordinatorCount = 0
    private(set) var registeredEventCoordinatorCount = 0

    override init() throws {
        try super.init()

        let simulation = TennisApp.makeSimulation()
        let humanRouter = TennisInputRouter(
            humanInput: TennisVirtualControllerInputSource(),
            sequenceResolver: DefaultTennisShotSequenceResolver(),
            initialFrame: TennisInputFrame(direction: TennisDirection(x: 0, y: 0), pressedButtons: [], heldButtons: [])
        )
        let matchCoordinator = TennisApp.makeCoordinator(surface: .hard, simulation: simulation, humanRouter: humanRouter)
        self.matchCoordinator = matchCoordinator

        let windowFrame = Rect(
            x: 0,
            y: 0,
            width: TennisApp.logicalSize.width,
            height: TennisApp.logicalSize.height
        )
        let window = try FullWindow(
            parent: self,
            title: "Tennis",
            frame: windowFrame,
            windowOptions: headlessWindowOptions,
            options: isHeadless ? [] : [Renderer.Option.presentVsync]
        )
        let font = try [
            FontDesc(family: "Arial", weight: 100, size: 8),
            FontDesc(family: "Helvetica", weight: 100, size: 8),
            FontDesc.defaultFont
        ].lazy.compactMap({ try? window.imageManager.fetchFont(desc: $0) }).first ?? nil
        guard let font else {
            throw GenericError("Tennis HUD font unavailable")
        }
        let textRenderer = TennisFontTextRenderer(font: font)
        let flow = TennisPresentationFlow(
            matchFactory: { surface in TennisApp.makeCoordinator(surface: surface) },
            textRenderer: textRenderer
        )
        self.presentation = flow
        self.scene = TennisScene(coordinator: matchCoordinator, hud: TennisHUD(font: font), presentation: flow)
        flow.onCoordinatorChange = { [weak self] coordinator in
            self?.replaceCoordinator(coordinator)
        }
        window.drawable = scene
        addFixedListener(matchCoordinator, msPerTick: 16)
        addEventListener(matchCoordinator)
        addEventListener(flow)
        registeredFixedCoordinatorCount += 1
        registeredEventCoordinatorCount += 1
        addWindow(window)

        if isHeadless && CommandLine.arguments.contains("--tennis-evidence") {
            let scenario = TennisHeadlessScenario(flow: flow, scene: scene,
                                                   outputDir: headlessConfig?.outputDir ?? URL(fileURLWithPath: "./"))
            textRenderer.onDraw = { [weak scenario] text, commandIDs in
                scenario?.recordText(text, commandIDs: commandIDs)
            }
            scenario.onFinished = { [weak self] in self?.isRunning = false }
            self.headlessScenario = scenario
            addFixedListener(scenario.fixedDriver, msPerTick: 16)
            addDeltaListener(scenario.captureDriver)
        }
    }

    private func replaceCoordinator(_ replacement: TennisMatchCoordinator?) {
        if registeredFixedCoordinatorCount > 0 {
            removeFixedListener(matchCoordinator)
            registeredFixedCoordinatorCount = 0
        }
        if registeredEventCoordinatorCount > 0 {
            removeEventListener(matchCoordinator)
            registeredEventCoordinatorCount = 0
        }

        guard let replacement else {
            scene.resetPresentationFeedback()
            return
        }
        matchCoordinator = replacement
        scene.replaceCoordinator(replacement)
        addFixedListener(replacement, msPerTick: 16)
        addEventListener(replacement)
        registeredFixedCoordinatorCount = 1
        registeredEventCoordinatorCount = 1
    }

    var integrationPresentation: TennisPresentationFlow { presentation }
    var integrationSceneCoordinator: TennisMatchCoordinator { scene.integrationCoordinator }
    var integrationRegisteredCoordinator: TennisMatchCoordinator? {
        registeredFixedCoordinatorCount == 1 && registeredEventCoordinatorCount == 1 ? matchCoordinator : nil
    }

    static func makeSimulation(surface: CourtSurface = .hard) -> TennisSimulation {
        let boundary = TennisRect(minX: 0, minY: 0, maxX: 10000, maxY: 20000)
        let topBox = TennisRect(minX: 0, minY: 0, maxX: 5000, maxY: 5000)
        let bottomBox = TennisRect(minX: 0, minY: 15000, maxX: 5000, maxY: 20000)
        let court = CourtRules(
            surface: surface,
            singlesBoundary: boundary,
            serviceBoxes: TennisServiceBoxes(topLeft: topBox, topRight: topBox, bottomLeft: bottomBox, bottomRight: bottomBox),
            netY: 10000
        )
        let balanced = PlayerStats(power: 100, speed: 100, control: 100, spin: 100)
        let players = [
            TennisSide.human: TennisPlayerState(side: .human, position: TennisPoint(x: 5000, y: 20000), stats: balanced, preset: .balanced),
            TennisSide.cpu: TennisPlayerState(side: .cpu, position: TennisPoint(x: 5000, y: 0), stats: balanced, preset: .power)
        ]
        let ball = TennisBallState(position: TennisPoint(x: 5000, y: 20000), height: 0, velocity: TennisVelocity(x: 0, y: 0, z: 0), shotKind: .serve, lastHitter: nil, isInFlight: false)
        let state = TennisSimulationState(tick: 0, server: .human, players: players, ball: ball)
        return TennisSimulation(rules: court, ruleBook: DefaultTennisRuleBook(), random: SeededTennisRandomSource(seed: 0x54454E4E4953), state: state)
    }

    static func makeCoordinator(surface: CourtSurface) -> TennisMatchCoordinator {
        makeCoordinator(surface: surface, simulation: makeSimulation(surface: surface), humanRouter: TennisInputRouter(
            humanInput: TennisVirtualControllerInputSource(),
            sequenceResolver: DefaultTennisShotSequenceResolver(),
            initialFrame: TennisInputFrame(direction: TennisDirection(x: 0, y: 0), pressedButtons: [], heldButtons: [])
        ))
    }

    private static func makeCoordinator(surface: CourtSurface, simulation: TennisSimulation, humanRouter: TennisInputRouter) -> TennisMatchCoordinator {
        TennisMatchCoordinator(
            simulation: simulation,
            scorekeeper: TennisMatchScorekeeper(initialServer: .human),
            humanController: TennisHumanController(inputRouter: humanRouter),
            cpuController: TennisCPUController(
                policy: TennisCPUDecisionPolicy(reactionDelayTicks: 2, rallyFloor: 6),
                random: SeededTennisRandomSource(seed: 0x54454E4E4953)
            )
        )
    }

    #if DEBUG
    var integrationGraph: (coordinator: TennisMatchCoordinator, fixedCount: Int, eventCount: Int) {
        return (matchCoordinator, registeredFixedCoordinatorCount, registeredEventCoordinatorCount)
    }
    #endif
}

private final class TennisHeadlessScenario {
    let fixedDriver: TennisHeadlessFixedDriver
    let captureDriver: TennisHeadlessCaptureDriver
    private let flow: TennisPresentationFlow
    private let scene: TennisScene
    private let outputDir: URL
    private let evidence = TennisHeadlessEvidenceSink()
    private var tick = 0
    private var glyphTexts: [String] = []
    private var textCommandIDs: [UInt64] = []
    var onFinished: (() -> Void)?

    init(flow: TennisPresentationFlow, scene: TennisScene, outputDir: URL) {
        self.flow = flow
        self.scene = scene
        self.outputDir = outputDir
        let fixedDriver = TennisHeadlessFixedDriver()
        let captureDriver = TennisHeadlessCaptureDriver()
        self.fixedDriver = fixedDriver
        self.captureDriver = captureDriver
        fixedDriver.scenario = self
        captureDriver.scenario = self
    }

    func fixedStep() {
        tick += 1
        switch tick {
        case 2:
            flow.onCommand(.start)
        case 3:
            flow.onCommand(.chooseSurface(.grass))
            flow.integrationCoordinator?.simulationDidEmit(TennisSimulationEvent(tick: 0, kind: .shotHit(side: .human, shot: .topspin, quality: .good)))
            flow.integrationCoordinator?.simulationDidEmit(TennisSimulationEvent(tick: 0, kind: .bounce(surface: .grass)))
        case 4:
            flow.matchDidComplete(.human, score: TennisMatchScore(humanPoints: 11, cpuPoints: 0, server: .human, matchWinner: .human))
        case 6:
            flow.onCommand(.continue)
        default:
            break
        }
    }

    func recordText(_ text: String, commandIDs: [UInt64]) {
        glyphTexts.append(text)
        textCommandIDs.append(contentsOf: commandIDs)
    }

    func afterDraw() {
        let observation = flow.makeObservation(
            feedback: scene.integrationFeedback,
            glyphTexts: glyphTexts,
            drawCommandIDs: scene.integrationLastDrawCommandIDs + textCommandIDs
        )
        evidence.observe(observation)
        glyphTexts.removeAll(keepingCapacity: true)
        textCommandIDs.removeAll(keepingCapacity: true)
        guard tick >= 6 else { return }
        do {
            try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)
            let payload = evidence.finish().map(Self.jsonObject(for:))
            let data = try JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted, .sortedKeys])
            try data.write(to: outputDir.appendingPathComponent("tennis_evidence.json"))
            print("Saved \(outputDir.appendingPathComponent("tennis_evidence.json").path)")
        } catch {
            fputs("Headless evidence write failed: \(error.localizedDescription)\n", stderr)
        }
        onFinished?()
    }

    private static func jsonObject(for observation: TennisPresentationObservation) -> [String: Any] {
        [
            "screen": String(describing: observation.screen),
            "selectedSurface": observation.selectedSurface.map { String(describing: $0) } as Any,
            "activeMatchSurface": observation.activeMatchSurface.map { String(describing: $0) } as Any,
            "coordinatorIdentity": observation.coordinatorIdentity.map { String(describing: $0) } as Any,
            "result": observation.result.map {
                ["winner": String(describing: $0.winner), "score": ["humanPoints": $0.score.humanPoints,
                 "cpuPoints": $0.score.cpuPoints, "server": String(describing: $0.score.server)]]
            } as Any,
            "score": observation.score.map {
                ["humanPoints": $0.humanPoints, "cpuPoints": $0.cpuPoints, "server": String(describing: $0.server),
                 "matchWinner": $0.matchWinner.map { String(describing: $0) } as Any]
            } as Any,
            "charge": observation.charge.map {
                ["activeSide": String(describing: $0.activeSide), "value": $0.value, "capReached": $0.capReached]
            } as Any,
            "surfaceBounce": observation.feedback.surfaceBounce.map { String(describing: $0.surface) } as Any,
            "glyphTexts": observation.glyphTexts,
            "drawCommandIDs": observation.drawCommandIDs
        ]
    }
}

private final class TennisHeadlessFixedDriver: IUpdate {
    weak var scenario: TennisHeadlessScenario?
    func step(_ delta: UInt64) { scenario?.fixedStep() }
}

private final class TennisHeadlessCaptureDriver: IUpdate {
    weak var scenario: TennisHeadlessScenario?
    func step(_ delta: UInt64) { scenario?.afterDraw() }
}

private final class TennisVirtualControllerInputSource: TennisHumanInputSource {
    func frame(for controller: VirtualController) -> TennisInputFrame {
        let buttons = controller.state.buttons
        var directionX = 0
        var directionY = 0
        if buttons.contains(.dpadLeft) { directionX -= 1 }
        if buttons.contains(.dpadRight) { directionX += 1 }
        if buttons.contains(.dpadUp) { directionY -= 1 }
        if buttons.contains(.dpadDown) { directionY += 1 }
        let previous = controller.statePrevious.buttons
        var pressed = Set<TennisActionButton>()
        var held = Set<TennisActionButton>()
        if buttons.contains(.action) { held.insert(.a) }
        if buttons.contains(.action2) { held.insert(.b) }
        if buttons.contains(.action) && !previous.contains(.action) { pressed.insert(.a) }
        if buttons.contains(.action2) && !previous.contains(.action2) { pressed.insert(.b) }
        return TennisInputFrame(direction: TennisDirection(x: directionX, y: directionY), pressedButtons: pressed, heldButtons: held)
    }
}

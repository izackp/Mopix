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
        let matchCoordinator = TennisMatchCoordinator(
            simulation: simulation,
            scorekeeper: TennisMatchScorekeeper(initialServer: .human),
            humanController: TennisHumanController(inputRouter: humanRouter),
            cpuController: TennisCPUController(
                policy: TennisCPUDecisionPolicy(reactionDelayTicks: 2, rallyFloor: 6),
                random: SeededTennisRandomSource(seed: 0x54454E4E4953)
            )
        )
        self.matchCoordinator = matchCoordinator
        let flow = TennisPresentationFlow { _ in matchCoordinator }
        self.presentation = flow

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
        self.scene = TennisScene(coordinator: matchCoordinator, hud: TennisHUD(font: font), presentation: flow)
        window.drawable = scene
        addFixedListener(matchCoordinator, msPerTick: 16)
        addEventListener(matchCoordinator)
        addEventListener(flow)
        registeredFixedCoordinatorCount += 1
        registeredEventCoordinatorCount += 1
        addWindow(window)
    }

    static func makeSimulation() -> TennisSimulation {
        let boundary = TennisRect(minX: 0, minY: 0, maxX: 10000, maxY: 20000)
        let topBox = TennisRect(minX: 0, minY: 0, maxX: 5000, maxY: 5000)
        let bottomBox = TennisRect(minX: 0, minY: 15000, maxX: 5000, maxY: 20000)
        let court = CourtRules(
            surface: .hard,
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

    #if DEBUG
    var integrationGraph: (coordinator: TennisMatchCoordinator, fixedCount: Int, eventCount: Int) {
        return (matchCoordinator, registeredFixedCoordinatorCount, registeredEventCoordinatorCount)
    }
    #endif
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

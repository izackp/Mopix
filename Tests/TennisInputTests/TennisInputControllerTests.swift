import XCTest
import GameEngine
@testable import TennisCore
@testable import TennisInput

final class TennisInputControllerTests: XCTestCase {
    func testSequenceResolutionAndExpiryFallback() {
        let resolver = DefaultTennisShotSequenceResolver(sequenceExpiryTicks: 4, chargeCap: 100)
        XCTAssertEqual(shape(resolver.resolve(frame: frame(pressed: [.a], held: [.a]), tick: 10)), .none)
        XCTAssertEqual(shape(resolver.resolve(frame: frame(held: [.a]), tick: 11)), .none)
        XCTAssertEqual(shape(resolver.resolve(frame: frame(), tick: 14)), .swing(.standaloneA, 2))

        resolver.reset()
        XCTAssertEqual(shape(resolver.resolve(frame: frame(pressed: [.a], held: [.a]), tick: 20)), .none)
        XCTAssertEqual(shape(resolver.resolve(frame: frame(pressed: [.b], held: [.b]), tick: 21)), .swing(.aThenB, 2))
        XCTAssertEqual(shape(resolver.resolve(frame: frame(pressed: [.b], held: [.b]), tick: 22)), .none)
        XCTAssertEqual(shape(resolver.resolve(frame: frame(pressed: [.a, .b], held: [.a, .b]), tick: 23)), .swing(.simultaneousAB, 2))
    }

    func testChargeClampsAndResetClearsPendingSequence() {
        let resolver = DefaultTennisShotSequenceResolver(sequenceExpiryTicks: 5, chargeCap: 3)
        _ = resolver.resolve(frame: frame(pressed: [.b], held: [.b]), tick: 0)
        _ = resolver.resolve(frame: frame(held: [.b]), tick: 1)
        _ = resolver.resolve(frame: frame(held: [.b]), tick: 2)
        _ = resolver.resolve(frame: frame(held: [.b]), tick: 3)
        resolver.reset()
        XCTAssertEqual(shape(resolver.resolve(frame: frame(), tick: 10)), .none)
        XCTAssertEqual(shape(resolver.resolve(frame: frame(pressed: [.a, .b], held: [.a, .b]), tick: 11)), .swing(.simultaneousAB, 1))
    }

    func testRouterUsesGameEngineCommandStateAndHumanController() {
        let source = CommandFrameSource()
        let router = TennisInputRouter(humanInput: source, sequenceResolver: DefaultTennisShotSequenceResolver(sequenceExpiryTicks: 2), initialFrame: frame())
        let human = TennisHumanController(inputRouter: router)
        let pressA = InputCommand(id: ButtonId.action.command.rawValue, value: 1)
        router.onCommandList(InputCommandList(clientId: 1, deviceId: 1, commands: [pressA]))
        XCTAssertEqual(shape(human.intent(for: 0)), .none)
        router.onCommandList(InputCommandList(clientId: 1, deviceId: 1, commands: []))
        XCTAssertEqual(shape(human.intent(for: 2)), .swing(.standaloneA, 1))
        human.resetPoint()
        XCTAssertEqual(shape(human.intent(for: 3)), .none)
    }

    func testCPUReactionDelayAndEqualSeedDecisionReplay() {
        let policy = TennisCPUDecisionPolicy(reactionDelayTicks: 2, rallyFloor: 6)
        let first = TennisCPUController(policy: policy, random: SeededTennisRandomSource(seed: 99))
        let second = TennisCPUController(policy: policy, random: SeededTennisRandomSource(seed: 99))
        let state = cpuState(ballPosition: TennisPoint(x: 2000, y: 8000))
        XCTAssertEqual(shape(first.intent(for: state, tick: 10)), .none)
        XCTAssertEqual(shape(first.intent(for: state, tick: 11)), .none)
        let firstDecision = shape(first.intent(for: state, tick: 12))
        let secondDecision = shape(second.intent(for: state, tick: 10))
        _ = second.intent(for: state, tick: 11)
        let secondAtReady = shape(second.intent(for: state, tick: 12))
        XCTAssertEqual(firstDecision, secondAtReady)
        XCTAssertEqual(secondDecision, .none)

        let farState = cpuState(ballPosition: TennisPoint(x: 8000, y: 15000))
        let mover = TennisCPUController(policy: policy, random: SeededTennisRandomSource(seed: 1))
        _ = mover.intent(for: farState, tick: 0)
        _ = mover.intent(for: farState, tick: 1)
        guard case .move(let direction) = mover.intent(for: farState, tick: 2) else { return XCTFail("CPU should move after reaction delay") }
        XCTAssertEqual(direction, TennisDirection(x: 1, y: 1))
    }

    func testCPURallyFloorUsesSafeShotsBeforeSeededVariety() {
        let random = SequenceRandomSource(values: [4, 100, 4, 100])
        let controller = TennisCPUController(policy: TennisCPUDecisionPolicy(reactionDelayTicks: 0, rallyFloor: 2), random: random)
        let state = cpuState(ballPosition: TennisPoint(x: 5000, y: 5000))
        XCTAssertEqual(shape(controller.intent(for: state, tick: 0)), .swing(.standaloneA, 0))
        XCTAssertEqual(shape(controller.intent(for: state, tick: 1)), .swing(.standaloneA, 0))
        XCTAssertEqual(shape(controller.intent(for: state, tick: 2)), .swing(.bThenA, 100))

        controller.resetPoint()
        XCTAssertEqual(shape(controller.intent(for: state, tick: 3)), .swing(.standaloneA, 0))
    }

    private func frame(direction: TennisDirection = TennisDirection(x: 0, y: 0), pressed: Set<TennisActionButton> = [], held: Set<TennisActionButton> = []) -> TennisInputFrame { TennisInputFrame(direction: direction, pressedButtons: pressed, heldButtons: held) }
    private func shape(_ intent: TennisActionIntent) -> IntentShape { switch intent { case .none: return .none; case .move(let direction): return .move(direction); case .swing(let sequence, let charge): return .swing(sequence, charge) } }
    private func cpuState(ballPosition: TennisPoint) -> TennisSimulationState {
        let stats = PlayerStats(power: 100, speed: 100, control: 100, spin: 100)
        let players = [TennisSide.human: TennisPlayerState(side: .human, position: TennisPoint(x: 5000, y: 18000), stats: stats, preset: .balanced), TennisSide.cpu: TennisPlayerState(side: .cpu, position: TennisPoint(x: 5000, y: 5000), stats: stats, preset: .power)]
        let ball = TennisBallState(position: ballPosition, height: 500, velocity: TennisVelocity(x: 0, y: 0, z: 0), shotKind: .topspin, lastHitter: .human, isInFlight: true)
        return TennisSimulationState(tick: 0, server: .human, players: players, ball: ball)
    }
}

private final class CommandFrameSource: TennisHumanInputSource {
    func frame(for controller: VirtualController) -> TennisInputFrame {
        let current = controller.state.buttons
        let previous = controller.statePrevious.buttons
        var held = Set<TennisActionButton>(); var pressed = Set<TennisActionButton>()
        if current.contains(.action) { held.insert(.a) }; if current.contains(.action2) { held.insert(.b) }
        if current.contains(.action) && !previous.contains(.action) { pressed.insert(.a) }
        if current.contains(.action2) && !previous.contains(.action2) { pressed.insert(.b) }
        return TennisInputFrame(direction: TennisDirection(x: 0, y: 0), pressedButtons: pressed, heldButtons: held)
    }
}

private enum IntentShape: Equatable {
    case none
    case move(TennisDirection)
    case swing(TennisSwingSequence, Int)
}

private final class SequenceRandomSource: TennisRandomSource {
    private var values: [Int]
    init(values: [Int]) { self.values = values }
    func nextInt(upperBound: Int) -> Int { min(upperBound - 1, max(0, values.isEmpty ? 0 : values.removeFirst())) }
}

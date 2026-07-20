import Foundation
import GameEngine

public enum TennisActionButton: Hashable { case a, b }

public struct TennisInputFrame {
    public let direction: TennisDirection
    public let pressedButtons: Set<TennisActionButton>
    public let heldButtons: Set<TennisActionButton>
    public init(direction: TennisDirection, pressedButtons: Set<TennisActionButton>, heldButtons: Set<TennisActionButton>) {
        self.direction = direction; self.pressedButtons = pressedButtons; self.heldButtons = heldButtons
    }
}

public protocol TennisHumanInputSource {
    func frame(for controller: VirtualController) -> TennisInputFrame
}

public protocol TennisShotSequenceResolver {
    func resolve(frame: TennisInputFrame, tick: UInt64) -> TennisActionIntent
    func reset()
}

public final class DefaultTennisShotSequenceResolver: TennisShotSequenceResolver {
    public let sequenceExpiryTicks: UInt64
    public let chargeCap: Int
    private var pendingButton: TennisActionButton?
    private var pendingTick: UInt64 = 0
    private var charge: Int = 0

    public init(sequenceExpiryTicks: UInt64 = 6, chargeCap: Int = 100) {
        self.sequenceExpiryTicks = max(1, sequenceExpiryTicks); self.chargeCap = max(0, chargeCap)
    }

    public func resolve(frame: TennisInputFrame, tick: UInt64) -> TennisActionIntent {
        let hasA = frame.pressedButtons.contains(.a)
        let hasB = frame.pressedButtons.contains(.b)
        let isHoldingAction = frame.heldButtons.contains(.a) || frame.heldButtons.contains(.b)
        if isHoldingAction { charge = min(chargeCap, charge + 1) }

        if let pendingButton {
            if tick >= pendingTick + sequenceExpiryTicks {
                let fallback = standalone(pendingButton)
                self.pendingButton = nil
                let fallbackCharge = cappedCharge()
                charge = 0
                return .swing(sequence: fallback, charge: fallbackCharge)
            }
            if hasA && hasB {
                self.pendingButton = nil
                let result: TennisActionIntent = .swing(sequence: .simultaneousAB, charge: cappedCharge())
                charge = 0
                return result
            }
            if (pendingButton == .a && hasB) || (pendingButton == .b && hasA) {
                let sequence: TennisSwingSequence = pendingButton == .a ? .aThenB : .bThenA
                self.pendingButton = nil
                let result: TennisActionIntent = .swing(sequence: sequence, charge: cappedCharge())
                charge = 0
                return result
            }
            return movementOrNone(frame)
        }

        if hasA && hasB {
            let result: TennisActionIntent = .swing(sequence: .simultaneousAB, charge: cappedCharge())
            charge = 0
            return result
        }
        if hasA || hasB {
            let first: TennisActionButton = hasA ? .a : .b
            pendingButton = first; pendingTick = tick
            charge = max(charge, isHoldingAction ? 1 : 0)
            return movementOrNone(frame)
        }
        return movementOrNone(frame)
    }

    public func reset() { pendingButton = nil; pendingTick = 0; charge = 0 }

    private func standalone(_ button: TennisActionButton) -> TennisSwingSequence { button == .a ? .standaloneA : .standaloneB }
    private func cappedCharge() -> Int { min(chargeCap, max(0, charge)) }
    private func movementOrNone(_ frame: TennisInputFrame) -> TennisActionIntent { frame.direction.x == 0 && frame.direction.y == 0 ? .none : .move(direction: frame.direction) }
}

public final class TennisInputRouter: ICommandListener {
    public let humanInput: TennisHumanInputSource
    public let sequenceResolver: TennisShotSequenceResolver
    public private(set) var latestFrame: TennisInputFrame
    private let controller: VirtualController

    public init(humanInput: TennisHumanInputSource, sequenceResolver: TennisShotSequenceResolver, initialFrame: TennisInputFrame) {
        self.humanInput = humanInput; self.sequenceResolver = sequenceResolver; self.latestFrame = initialFrame
        self.controller = VirtualController(clientId: 0, deviceId: 0, state: .blank, statePrevious: .blank)
    }

    public func onCommandList(_ commandList: InputCommandList) {
        controller.pushCommandList(commandList)
        latestFrame = humanInput.frame(for: controller)
    }

    public func intent(for tick: UInt64) -> TennisActionIntent { sequenceResolver.resolve(frame: latestFrame, tick: tick) }
    public func resetPoint() { sequenceResolver.reset() }
}

public protocol TennisController {
    func intent(for state: TennisSimulationState, tick: UInt64) -> TennisActionIntent
    func resetPoint()
}

public final class TennisHumanController: TennisController {
    public let inputRouter: TennisInputRouter
    public init(inputRouter: TennisInputRouter) { self.inputRouter = inputRouter }
    public func intent(for state: TennisSimulationState, tick: UInt64) -> TennisActionIntent { inputRouter.intent(for: tick) }
    public func resetPoint() { inputRouter.resetPoint() }
}

public struct TennisCPUDecisionPolicy {
    public let reactionDelayTicks: Int
    public let rallyFloor: Int
    public init(reactionDelayTicks: Int, rallyFloor: Int) { self.reactionDelayTicks = max(0, reactionDelayTicks); self.rallyFloor = max(0, rallyFloor) }
}

public final class TennisCPUController: TennisController {
    public let policy: TennisCPUDecisionPolicy
    public let random: TennisRandomSource
    private var decisionAvailableTick: UInt64 = 0
    private var lastObservedHitter: TennisSide?

    public init(policy: TennisCPUDecisionPolicy, random: TennisRandomSource) { self.policy = policy; self.random = random }

    public func intent(for state: TennisSimulationState, tick: UInt64) -> TennisActionIntent {
        if state.pointEnd != nil { return .none }
        if state.ball.isInFlight && state.ball.lastHitter != lastObservedHitter {
            lastObservedHitter = state.ball.lastHitter
            decisionAvailableTick = tick &+ UInt64(policy.reactionDelayTicks)
        }
        guard tick >= decisionAvailableTick else { return .none }
        guard let cpu = state.players[.cpu] else { return .none }

        if !state.ball.isInFlight {
            guard state.server == .cpu else { return movementTowardBall(cpu: cpu, ball: state.ball) }
            return .swing(sequence: nextSequence(), charge: nextCharge())
        }
        if distanceSquared(cpu.position, state.ball.position) > 1_440_000 {
            return movementTowardBall(cpu: cpu, ball: state.ball)
        }
        return .swing(sequence: nextSequence(), charge: nextCharge())
    }

    public func resetPoint() { decisionAvailableTick = 0; lastObservedHitter = nil }

    private func nextSequence() -> TennisSwingSequence {
        switch random.nextInt(upperBound: 5) { case 0: return .standaloneA; case 1: return .standaloneB; case 2: return .simultaneousAB; case 3: return .aThenB; default: return .bThenA }
    }
    private func nextCharge() -> Int { random.nextInt(upperBound: 101) }
    private func movementTowardBall(cpu: TennisPlayerState, ball: TennisBallState) -> TennisActionIntent { .move(direction: TennisDirection(x: sign(ball.position.x - cpu.position.x), y: sign(ball.position.y - cpu.position.y))) }
    private func sign(_ value: TennisFixed) -> Int { value < 0 ? -1 : value > 0 ? 1 : 0 }
    private func distanceSquared(_ a: TennisPoint, _ b: TennisPoint) -> Int64 { let x = Int64(a.x - b.x); let y = Int64(a.y - b.y); return x * x + y * y }
}

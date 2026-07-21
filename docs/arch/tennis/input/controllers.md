# Sources/TennisInput/TennisInputControllers.swift [TennisInput]

```swift
// TARGET: TennisInput
// OWNED BY: TennisInput owns engine-facing command translation, sequence resolution, and
// controller decisions. Shared gameplay intent/value types are owned by TennisCore.
// DEPENDENCIES: GameEngine input APIs plus TennisCore; no renderer, presentation, or match-flow.

enum TennisActionButton {
    case a
    case b
}

struct TennisInputFrame {
    let direction: TennisDirection
    let pressedButtons: Set<TennisActionButton>
    let heldButtons: Set<TennisActionButton>

    init(direction: TennisDirection, pressedButtons: Set<TennisActionButton>, heldButtons: Set<TennisActionButton>)
}

protocol TennisHumanInputSource {
    func frame(for controller: VirtualController) -> TennisInputFrame
}

protocol TennisShotSequenceResolver {
    func resolve(frame: TennisInputFrame, tick: UInt64) -> TennisActionIntent
    func reset()
}

final class DefaultTennisShotSequenceResolver: TennisShotSequenceResolver {
    let sequenceExpiryTicks: UInt64
    let chargeCap: Int
    private var pendingButton: TennisActionButton?
    private var pendingTick: UInt64
    private var charge: Int

    init(sequenceExpiryTicks: UInt64 = 6, chargeCap: Int = 100)
    func resolve(frame: TennisInputFrame, tick: UInt64) -> TennisActionIntent
    func reset()
}

final class TennisInputRouter: ICommandListener {
    let humanInput: TennisHumanInputSource
    let sequenceResolver: TennisShotSequenceResolver
    private(set) var latestFrame: TennisInputFrame
    private let controller: VirtualController

    init(humanInput: TennisHumanInputSource, sequenceResolver: TennisShotSequenceResolver, initialFrame: TennisInputFrame)
    func onCommandList(_ commandList: InputCommandList)
    func intent(for tick: UInt64) -> TennisActionIntent
    func resetPoint()
}

protocol TennisController {
    func intent(for state: TennisSimulationState, tick: UInt64) -> TennisActionIntent
    func resetPoint()
}

final class TennisHumanController: TennisController {
    let inputRouter: TennisInputRouter

    init(inputRouter: TennisInputRouter)
    func intent(for state: TennisSimulationState, tick: UInt64) -> TennisActionIntent
    func resetPoint()
}

struct TennisCPUDecisionPolicy {
    let reactionDelayTicks: Int
    let rallyFloor: Int

    init(reactionDelayTicks: Int, rallyFloor: Int)
}

final class TennisCPUController: TennisController {
    let policy: TennisCPUDecisionPolicy
    let random: TennisRandomSource
    private var decisionAvailableTick: UInt64
    private var lastObservedHitter: TennisSide?
    private var rallyShots: Int

    init(policy: TennisCPUDecisionPolicy, random: TennisRandomSource)
    func intent(for state: TennisSimulationState, tick: UInt64) -> TennisActionIntent
    func resetPoint()
}
```

`TennisDirection`, `TennisSwingSequence`, and `TennisActionIntent` are canonical declarations
in [../core/simulation.md](../core/simulation.md); this document references them but does not
redeclare them. `TennisInputRouter` translates engine commands into one deterministic input frame per
fixed tick. `A -> B` and `B -> A` sequence expiry resolves to the first button's
standalone shot. Controllers may inspect the simulation snapshot but may not mutate it.
The CPU uses the match's seeded random source and regular movement only; it never receives
a teleport or physics bypass.

// TEST: sequence expiry fallback, charge cap cue state, and input reset between points.
// TEST: CPU reaction delay is enforced and fixed-seed decisions replay identically.

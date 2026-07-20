# Tennis Input and Controller Signatures

```swift
// OWNED BY: TennisInputRouter owns per-tick intents and the human sequence/charge state.
// DEPENDENCIES: GameEngine input value types; Tennis simulation value types; no renderer.

enum TennisActionButton {
    case a
    case b
}

struct TennisDirection {
    let x: Int
    let y: Int
}

struct TennisInputFrame {
    let direction: TennisDirection
    let pressedButtons: Set<TennisActionButton>
    let heldButtons: Set<TennisActionButton>
}

enum TennisSwingSequence {
    case standaloneA
    case standaloneB
    case simultaneousAB
    case aThenB
    case bThenA
}

enum TennisActionIntent {
    case none
    case move(direction: TennisDirection)
    case swing(sequence: TennisSwingSequence, charge: Int)
}

protocol TennisHumanInputSource {
    func frame(for controller: VirtualController) -> TennisInputFrame
}

protocol TennisShotSequenceResolver {
    func resolve(frame: TennisInputFrame, tick: UInt64) -> TennisActionIntent
    func reset()
}

final class TennisInputRouter: ICommandListener {
    let humanInput: TennisHumanInputSource
    let sequenceResolver: TennisShotSequenceResolver
    private(set) var latestFrame: TennisInputFrame

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
}

final class TennisCPUController: TennisController {
    let policy: TennisCPUDecisionPolicy
    let random: TennisRandomSource
    private var decisionAvailableTick: UInt64

    init(policy: TennisCPUDecisionPolicy, random: TennisRandomSource)
    func intent(for state: TennisSimulationState, tick: UInt64) -> TennisActionIntent
    func resetPoint()
}
```

`TennisInputRouter` translates engine commands into one deterministic input frame per
fixed tick. `A -> B` and `B -> A` sequence expiry resolves to the first button's
standalone shot. Controllers may inspect the simulation snapshot but may not mutate it.
The CPU uses the match's seeded random source and regular movement only; it never receives
a teleport or physics bypass.

// TEST: sequence expiry fallback, charge cap cue state, and input reset between points.
// TEST: CPU reaction delay is enforced and fixed-seed decisions replay identically.

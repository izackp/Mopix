# Sources/TennisInput/TennisInputControllers.swift [TennisInput]

```text
// TARGET: TennisInput
// OWNED BY: TennisInput owns GameEngine command translation, sequence resolution, human input,
// and CPU decisions. Shared gameplay intent/value types remain owned by TennisCore.
// DEPENDENCIES: GameEngine input APIs and TennisCore. No renderer, SDL, match-flow, or presentation.

TennisActionButton | Hashable

TennisInputFrame
  pub direction: TennisDirection
  pub pressedButtons: Set<TennisActionButton>
  pub heldButtons: Set<TennisActionButton>
  pub init(direction: TennisDirection, pressedButtons: Set<TennisActionButton>, heldButtons: Set<TennisActionButton>)

TennisHumanInputSource
  frame(for controller: VirtualController) -> TennisInputFrame
    << TennisInputRouter.onCommandList(_:)

TennisShotSequenceResolver
  resolve(frame: TennisInputFrame, tick: UInt64) -> TennisActionIntent
    << TennisInputRouter.intent(for:)
  reset()
    << TennisInputRouter.resetPoint()

DefaultTennisShotSequenceResolver < TennisShotSequenceResolver
  pub sequenceExpiryTicks: UInt64
  pub chargeCap: Int
  priv pendingButton: TennisActionButton?
  priv pendingTick: UInt64
  priv charge: Int
  pub init(sequenceExpiryTicks: UInt64 = 6, chargeCap: Int = 100)
  pub resolve(frame: TennisInputFrame, tick: UInt64) -> TennisActionIntent
    >> standalone(_:) cappedCharge() movementOrNone(_:)
  pub reset()
  priv standalone(_ button: TennisActionButton) -> TennisSwingSequence
  priv cappedCharge() -> Int
  priv movementOrNone(_ frame: TennisInputFrame) -> TennisActionIntent

TennisInputRouter < ICommandListener
  pub humanInput: TennisHumanInputSource
  pub sequenceResolver: TennisShotSequenceResolver
  pub latestFrame: TennisInputFrame
  priv controller: VirtualController
  pub init(humanInput: TennisHumanInputSource, sequenceResolver: TennisShotSequenceResolver, initialFrame: TennisInputFrame)
    >> VirtualController.init(clientId:deviceId:state:statePrevious:)
  pub onCommandList(_ commandList: InputCommandList)
    >> VirtualController.pushCommandList(_:) TennisHumanInputSource.frame(for:)
  pub intent(for tick: UInt64) -> TennisActionIntent
    >> TennisShotSequenceResolver.resolve(frame:tick:)
  pub resetPoint()
    >> TennisShotSequenceResolver.reset()

TennisController
  intent(for state: TennisSimulationState, tick: UInt64) -> TennisActionIntent
  resetPoint()

TennisHumanController < TennisController
  pub inputRouter: TennisInputRouter
  pub init(inputRouter: TennisInputRouter)
  pub intent(for state: TennisSimulationState, tick: UInt64) -> TennisActionIntent
    >> TennisInputRouter.intent(for:)
  pub resetPoint()
    >> TennisInputRouter.resetPoint()

TennisCPUDecisionPolicy
  pub reactionDelayTicks: Int
  pub rallyFloor: Int
  pub init(reactionDelayTicks: Int, rallyFloor: Int)

TennisCPUController < TennisController
  pub policy: TennisCPUDecisionPolicy
  pub random: TennisRandomSource
  priv decisionAvailableTick: UInt64
  priv lastObservedHitter: TennisSide?
  priv rallyShots: Int
  pub init(policy: TennisCPUDecisionPolicy, random: TennisRandomSource)
  pub intent(for state: TennisSimulationState, tick: UInt64) -> TennisActionIntent
    >> nextSequence() nextCharge() movementTowardBall(cpu:ball:)
  pub resetPoint()
  priv nextSequence() -> TennisSwingSequence
    >> TennisRandomSource.nextInt(upperBound:)
  priv nextCharge() -> Int
    >> TennisRandomSource.nextInt(upperBound:)
  priv movementTowardBall(cpu: TennisPlayerState, ball: TennisBallState) -> TennisActionIntent
  priv sign(_ value: TennisFixed) -> Int
  priv distanceSquared(_ a: TennisPoint, _ b: TennisPoint) -> Int64
```

`TennisDirection`, `TennisSwingSequence`, and `TennisActionIntent` are imported from
[../../core/TennisSimulation.md](../../core/TennisSimulation.md), never redeclared here.
The resolver emits the first button's standalone sequence when its expiry elapses, clamps charge
to `chargeCap`, and resets pending sequence/charge state at a point boundary. `TennisInputRouter`
consumes `InputCommandList` through `VirtualController` once per fixed tick. The human controller
delegates to that router; the CPU uses only the injected seeded `TennisRandomSource`, honors its
reaction delay, and applies `rallyFloor` before random rally choices.

// TEST: expiry fallback, charge cap/reset, command translation, human delegation, CPU delay,
// rally floor, and equal-seed CPU replay.

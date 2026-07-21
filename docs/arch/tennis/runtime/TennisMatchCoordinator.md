# Sources/Tennis/TennisMatchCoordinator.swift [Tennis]

This is the current CodeMapper-style source map for the coordinator. The live map includes the
snapshot boundary, fixed-step call graph, queued event path, and point-reset ownership.

```text
// TARGET: Tennis executable
// OWNED BY: TennisMatchCoordinator owns fixed-tick orchestration, point lifecycle, controller
// wiring, match snapshots, and the boundary between TennisCore simulation events and match scoring.
// DEPENDENCIES: GameEngine IUpdate, IEventListener, SDL_Event.toCommand(), InputCommand,
// InputCommandList; TennisCore TennisSimulation, TennisMatchScorekeeper, TennisRuleBook,
// TennisTickInput, TennisSimulationDelegate; TennisInput TennisHumanController and
// TennisCPUController. No renderer, VirtualDrive, menu, or HUD dependency.

TennisMatchDelegate | AnyObject
  matchDidEndPoint(_ reason: PointEndReason, winner: TennisSide, score: TennisMatchScore)
  matchDidComplete(_ winner: TennisSide, score: TennisMatchScore)

TennisMatchSnapshot | Equatable
  pub score: TennisMatchScore
  pub simulation: TennisSimulationState
  pub init(score: TennisMatchScore, simulation: TennisSimulationState)

TennisMatchCoordinator < IUpdate | IEventListener | TennisSimulationDelegate
  pub simulation: TennisSimulation
  pub humanController: TennisHumanController
  pub cpuController: TennisCPUController
  pub private(set) score: TennisMatchScore
  pub weak var delegate: TennisMatchDelegate?
  priv scorekeeper: TennisMatchScorekeeper
  priv pendingCommands: [InputCommand]
  priv tick: UInt64
  priv pendingPointEnd: PointEndReason?
  pub init(simulation: TennisSimulation, scorekeeper: TennisMatchScorekeeper, humanController: TennisHumanController, cpuController: TennisCPUController)
    >> TennisSimulationDelegate assignment
  pub step(_ delta: UInt64)
    >> flushPendingCommands() TennisHumanController.intent(for:tick:)
       TennisCPUController.intent(for:tick:) TennisSimulation.snapshot()
       TennisTickInput.init(human:cpu:) TennisSimulation.step(tickInput:)
       completePointIfNeeded()
  pub snapshot() -> TennisMatchSnapshot
    >> TennisSimulation.snapshot()
  pub onEvents(_ events: [SDL_Event])
    >> SDL_Event.toCommand()
  pub simulationDidEmit(_ event: TennisSimulationEvent)
    >> TennisSimulationEvent.kind
  pub resetMatch(server: TennisSide)
    >> TennisMatchScorekeeper.reset(server:) TennisSimulation.resetPoint(server:) TennisController.resetPoint()
  priv flushPendingCommands()
    >> TennisInputRouter.onCommandList(_:)
  priv completePointIfNeeded()
    >> TennisSimulationState.pointEnd TennisRuleBook.pointWinner(for:)
       TennisMatchScorekeeper.recordPoint(winner:) TennisMatchDelegate.matchDidEndPoint(_:winner:score:)
       TennisSimulation.resetPoint(server:) TennisHumanController.resetPoint()
       TennisCPUController.resetPoint() TennisMatchDelegate.matchDidComplete(_:score:)
```

`TennisApp` installs one coordinator with `Application.addFixedListener(_:msPerTick:)` and
`Application.addEventListener(_:)`; the fixed-listener interval is the sole game-logic clock.
`step(_:)` advances the coordinator tick exactly once per fixed callback and treats `delta` as the
engine's fixed tick duration, never as a frame-dependent simulation multiplier. It samples one
simulation snapshot, asks both controllers for intents using that same tick/state, and submits one
`TennisTickInput`; TennisCore retains deterministic human-before-CPU simultaneous-contact priority.

The coordinator owns the authoritative monotonic tick. A point or match reset clears gameplay
state, score/controller state, and pending commands, but neither advances nor rewinds that tick;
`TennisSimulation.resetPoint(server:)` preserves the current simulation tick. Thus one fixed
callback contains at most one simulation step, and a point-ending callback cannot create a second
logic tick. `TennisMatchSnapshot` is the read-only boundary consumed by `TennisScene`.

`onEvents(_:)` only converts and queues input commands. The next fixed step forwards one
`InputCommandList` to the human controller's existing `TennisInputRouter`, preserving the
router's press, hold, expiry, and reset semantics. CPU decisions remain injected through the
existing seeded `TennisRandomSource`; the coordinator does not add randomness or alter controller
behavior.

When the simulation reaches `pointEnd`, the coordinator obtains the winner from the simulation's
rule book, records exactly one point, publishes the point result, and either resets both
controllers and the simulation for the scorekeeper's next server or publishes match completion.
No point reset occurs after match completion, and no further simulation step is submitted while a
match winner exists. Serve faults follow the same path because `pointWinner(for:)` awards them to
the receiver.

// TEST: one fixed callback produces one simulation tick and one paired human/CPU intent sample.
// TEST: command events reach the human router on the next fixed tick; CPU uses the same snapshot.
// TEST: snapshot() exposes score and simulation state after the same fixed step that consumed
// the input, allowing TennisScene to render the resulting positions.
// TEST: every PointEndReason awards exactly one point, resets state/controllers, and rotates the
// server only after two points; serve faults award the receiver.
// TEST: first-to-11 win-by-two publishes completion and prevents further reset or simulation steps.

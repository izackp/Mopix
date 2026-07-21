# Sources/Tennis/TennisMatchCoordinator.swift [Tennis]

```text
// TARGET: Tennis executable
// OWNED BY: TennisMatchCoordinator owns fixed-tick orchestration, point lifecycle, controller
// wiring, and the boundary between TennisCore simulation events and match scoring.
// DEPENDENCIES: GameEngine IUpdate, IEventListener, SDL_Event.toCommand(), InputCommand,
// InputCommandList; TennisCore TennisSimulation, TennisMatchScorekeeper, TennisRuleBook,
// TennisTickInput, TennisSimulationDelegate; TennisInput TennisHumanController and
// TennisCPUController. No renderer, VirtualDrive, menu, or HUD dependency.

TennisMatchDelegate | AnyObject
  matchDidEndPoint(_ reason: PointEndReason, winner: TennisSide, score: TennisMatchScore)
  matchDidComplete(_ winner: TennisSide, score: TennisMatchScore)

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
    >> flushPendingCommands() TennisController.intent(for:tick:) TennisSimulation.step(tickInput:)
       completePointIfNeeded()
  pub onEvents(_ events: [SDL_Event])
    >> SDL_Event.toCommand()
  pub simulationDidEmit(_ event: TennisSimulationEvent)
    >> TennisMatchDelegate.matchDidEndPoint(_:winner:score:) TennisMatchDelegate.matchDidComplete(_:score:)
  pub resetMatch(server: TennisSide)
    >> TennisMatchScorekeeper.reset(server:) TennisSimulation.resetPoint(server:) TennisController.resetPoint()
  priv flushPendingCommands()
    >> TennisInputRouter.onCommandList(_:)
  priv completePointIfNeeded()
    >> TennisRuleBook.pointWinner(for:) TennisMatchScorekeeper.recordPoint(winner:)
       TennisSimulation.resetPoint(server:) TennisController.resetPoint()
```

`TennisApp` installs one coordinator with `Application.addFixedListener(_:msPerTick:)` and
`Application.addEventListener(_:)`; the fixed-listener interval is the sole game-logic clock.
`step(_:)` advances the coordinator tick once per fixed callback and treats `delta` as the engine's
fixed tick duration, never as a frame-dependent simulation multiplier. It samples one simulation
snapshot, asks both controllers for intents using that same tick/state, and submits one
`TennisTickInput`; TennisCore retains deterministic human-before-CPU simultaneous-contact priority.

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
// TEST: every PointEndReason awards exactly one point, resets state/controllers, and rotates the
// server only after two points; serve faults award the receiver.
// TEST: first-to-11 win-by-two publishes completion and prevents further reset or simulation steps.

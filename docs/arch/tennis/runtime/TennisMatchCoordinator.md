# Sources/Tennis/TennisMatchCoordinator.swift [Tennis]

```text
// TARGET: Tennis executable
// OWNED BY: TennisMatchCoordinator owns fixed-tick orchestration, point lifecycle, controller
// wiring, match snapshots, charge projection, and the boundary between TennisCore events and
// match scoring/presentation events.
// DEPENDENCIES: GameEngine IUpdate, IEventListener, SDL_Event.toCommand(), InputCommand,
// InputCommandList; TennisCore TennisSimulation, TennisMatchScorekeeper, TennisRuleBook,
// TennisTickInput, TennisSimulationDelegate; TennisInput TennisHumanController,
// TennisCPUController, and TennisInputRouter; TennisPresentation.swift value/event types. No
// renderer, menu-flow, or font dependency.

TennisMatchDelegate | AnyObject
  matchDidEndPoint(_ reason: PointEndReason, winner: TennisSide, score: TennisMatchScore)
  matchDidComplete(_ winner: TennisSide, score: TennisMatchScore)

TennisMatchSnapshot | Equatable
  pub score: TennisMatchScore
  pub simulation: TennisSimulationState
  pub charge: TennisChargeSnapshot
  pub init(score: TennisMatchScore, simulation: TennisSimulationState, charge: TennisChargeSnapshot? = nil)
    >> TennisChargeSnapshot.init(activeSide:value:capReached:)
    << TennisMatchCoordinator.snapshot()

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
  pub private(set) latestCharge: TennisChargeSnapshot
  pub private(set) presentationEvents: [TennisMatchPresentationEvent]
  pub init(simulation: TennisSimulation, scorekeeper: TennisMatchScorekeeper, humanController: TennisHumanController, cpuController: TennisCPUController)
    >> TennisSimulation.delegate = self
  pub snapshot() -> TennisMatchSnapshot
    >> TennisSimulation.snapshot() TennisMatchSnapshot.init(score:simulation:charge:)
  pub step(_ delta: UInt64)
    >> flushPendingCommands() TennisSimulation.snapshot()
       TennisHumanController.intent(for:tick:) TennisCPUController.intent(for:tick:)
       TennisChargeSnapshot.init(activeSide:value:capReached:)
       TennisSimulation.step(tickInput:) completePointIfNeeded()
  pub onEvents(_ events: [SDL_Event])
    >> SDL_Event.toCommand() pendingCommands.append(_:)
  pub simulationDidEmit(_ event: TennisSimulationEvent)
    >> TennisSimulationEvent.kind TennisRuleBook.pointWinner(for:)
       presentationEvents.append(_:)
  pub consumePresentationEvents() -> [TennisMatchPresentationEvent]
    >> presentationEvents.removeAll(keepingCapacity:)
  pub resetMatch(server: TennisSide)
    >> TennisMatchScorekeeper.reset(server:) TennisSimulation.resetPoint(server:)
       TennisChargeSnapshot.init(activeSide:value:capReached:)
       TennisHumanController.resetPoint() TennisCPUController.resetPoint()
  priv flushPendingCommands()
    >> TennisInputRouter.onCommandList(_:)
  priv completePointIfNeeded()
    >> TennisSimulationState.pointEnd TennisRuleBook.pointWinner(for:)
       TennisMatchScorekeeper.recordPoint(winner:)
       TennisMatchDelegate.matchDidEndPoint(_:winner:score:)
       TennisSimulation.resetPoint(server:)
       TennisHumanController.resetPoint() TennisCPUController.resetPoint()
       TennisMatchDelegate.matchDidComplete(_:score:)
```

The coordinator is the fixed-tick clock boundary. `delta` is ignored as a simulation multiplier;
one fixed callback samples one simulation snapshot, one human intent, and one CPU intent, then
submits one `TennisTickInput`. `latestCharge` currently records the human swing charge or resets
to zero with the simulation server as active side; it is copied into `TennisMatchSnapshot` for
the HUD.

Simulation events are translated into `TennisMatchPresentationEvent` values and retained until
`TennisScene.draw` calls `consumePresentationEvents()`. This queue is presentation delivery state,
not gameplay authority. Score and point completion remain owned by the scorekeeper/rule book, and
point resets preserve the monotonic simulation tick.

// TEST: one fixed callback produces one simulation tick, one paired intent sample, and one
// post-step snapshot.
// TEST: every point-end reason produces exactly one presentation/score resolution and reset path.
// TEST: snapshot charge and presentation event consumption are deterministic and point resets
// clear charge state without advancing the fixed tick.

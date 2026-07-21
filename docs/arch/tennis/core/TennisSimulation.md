# Sources/TennisCore/TennisSimulation.swift [TennisCore]

```text
// TARGET: TennisCore
// OWNED BY: TennisCore owns every type declared below and the fixed-tick simulation.
// DEPENDENCIES: Foundation value types only. No GameEngine, TennisInput, renderer, SDL,
// match-flow, or presentation dependency. TennisInput may depend on this target; this target
// never depends on TennisInput.

TennisPoint | Equatable
  pub x: TennisFixed
  pub y: TennisFixed
  pub init(x: TennisFixed, y: TennisFixed)

TennisVelocity | Equatable
  pub x: TennisFixed
  pub y: TennisFixed
  pub z: TennisFixed
  pub init(x: TennisFixed, y: TennisFixed, z: TennisFixed)

TennisSide | Hashable
CourtSurface | Hashable

PlayerStats | Equatable
  pub power: Int
  pub speed: Int
  pub control: Int
  pub spin: Int
  pub init(power: Int, speed: Int, control: Int, spin: Int)

PlayerPreset | Hashable

TennisRect | Equatable
  pub minX: TennisFixed
  pub minY: TennisFixed
  pub maxX: TennisFixed
  pub maxY: TennisFixed
  pub init(minX: TennisFixed, minY: TennisFixed, maxX: TennisFixed, maxY: TennisFixed)

TennisServiceBoxes | Equatable
  pub topLeft: TennisRect
  pub topRight: TennisRect
  pub bottomLeft: TennisRect
  pub bottomRight: TennisRect
  pub init(topLeft: TennisRect, topRight: TennisRect, bottomLeft: TennisRect, bottomRight: TennisRect)

CourtRules | Equatable
  pub surface: CourtSurface
  pub singlesBoundary: TennisRect
  pub serviceBoxes: TennisServiceBoxes
  pub netY: TennisFixed
  pub init(surface: CourtSurface, singlesBoundary: TennisRect, serviceBoxes: TennisServiceBoxes, netY: TennisFixed)

ShotKind | Hashable
ContactQuality | Hashable
TennisSwingSequence | Hashable
TennisActionIntent
TennisPointPhase | Hashable
  serveWindUp | rally

TennisDirection | Equatable
  pub x: Int
  pub y: Int
  pub init(x: Int, y: Int)

ShotCommand
  side: TennisSide
  kind: ShotKind
  target: TennisPoint
  charge: Int
  contactQuality: ContactQuality
  init(side: TennisSide, kind: ShotKind, target: TennisPoint, charge: Int, contactQuality: ContactQuality)

TennisPlayerState
  pub side: TennisSide
  pub position: TennisPoint
  pub stats: PlayerStats
  pub preset: PlayerPreset
  pub swingPending: Bool
  pub hitstopTicksRemaining: Int
  pub init(side: TennisSide, position: TennisPoint, stats: PlayerStats, preset: PlayerPreset, swingPending: Bool = false, hitstopTicksRemaining: Int = 0)

TennisBallState
  pub position: TennisPoint
  pub height: TennisFixed
  pub velocity: TennisVelocity
  pub shotKind: ShotKind
  pub lastHitter: TennisSide?
  pub isInFlight: Bool
  pub init(position: TennisPoint, height: TennisFixed, velocity: TennisVelocity, shotKind: ShotKind, lastHitter: TennisSide? = nil, isInFlight: Bool = false)

PointEndReason | Equatable
TennisSimulationState
  pub tick: UInt64
  pub server: TennisSide
  pub phase: TennisPointPhase
  pub serveWindUpTicksRemaining: Int
  pub players: [TennisSide: TennisPlayerState]
  pub ball: TennisBallState
  pub pointEnd: PointEndReason?
  pub hitstopTicksRemaining: Int
  pub init(tick: UInt64, server: TennisSide, phase: TennisPointPhase, serveWindUpTicksRemaining: Int = 12, players: [TennisSide: TennisPlayerState], ball: TennisBallState, pointEnd: PointEndReason? = nil, hitstopTicksRemaining: Int = 0)

TennisSimulationEvent
  pub tick: UInt64
  pub kind: TennisSimulationEventKind
  pub init(tick: UInt64, kind: TennisSimulationEventKind)

TennisSimulationEventKind | Equatable

TennisRandomSource
  nextInt(upperBound: Int) -> Int

TennisRuleBook
  playerStats(for preset: PlayerPreset) -> PlayerStats
  contactQuality(distance: TennisFixed) -> ContactQuality
  isSmashEligible(ballHeight: TennisFixed, playerDistance: TennisFixed) -> Bool
  shotKind(for sequence: TennisSwingSequence, smashEligible: Bool) -> ShotKind
  isLegalServe(landing: TennisPoint, server: TennisSide, court: CourtRules) -> Bool
  pointWinner(for reason: PointEndReason) -> TennisSide

TennisSimulationDelegate | AnyObject
  simulationDidEmit(_ event: TennisSimulationEvent)

SeededTennisRandomSource < TennisRandomSource
  priv state: UInt64
  pub init(seed: UInt64)
  pub nextInt(upperBound: Int) -> Int

DefaultTennisRuleBook < TennisRuleBook
  pub init()
  pub playerStats(for preset: PlayerPreset) -> PlayerStats
  pub contactQuality(distance: TennisFixed) -> ContactQuality
  pub isSmashEligible(ballHeight: TennisFixed, playerDistance: TennisFixed) -> Bool
  pub shotKind(for sequence: TennisSwingSequence, smashEligible: Bool) -> ShotKind
  pub isLegalServe(landing: TennisPoint, server: TennisSide, court: CourtRules) -> Bool
  pub pointWinner(for reason: PointEndReason) -> TennisSide
  priv opposite(_ side: TennisSide) -> TennisSide
    << DefaultTennisRuleBook.pointWinner(for:)

TennisTickInput
  pub human: TennisActionIntent
  pub cpu: TennisActionIntent
  pub init(human: TennisActionIntent, cpu: TennisActionIntent)

TennisSimulation
  pub rules: CourtRules
  pub ruleBook: TennisRuleBook
  pub random: TennisRandomSource
  pub delegate: TennisSimulationDelegate?
  pub state: TennisSimulationState
  priv static let serveWindUpDurationTicks: Int = 12
  priv bounceCount: Int
  priv netHeight: TennisFixed
  priv gravity: TennisFixed
  pub init(rules: CourtRules, ruleBook: TennisRuleBook, random: TennisRandomSource, state: TennisSimulationState)
  pub snapshot() -> TennisSimulationState
    << TennisInput controller reads snapshots through TennisCore contracts
  pub resetPoint(server: TennisSide)
    >> baselineCenter(for:) TennisVelocity.init(x:y:z:)
  pub step(tickInput: TennisTickInput)
    >> move(_:intent:) canContact(_:) hit(side:sequence:charge:) advanceBall()
  priv move(_ side: TennisSide, intent: TennisActionIntent)
    << TennisSimulation.step(tickInput:)
  priv distance(_ a: TennisPoint, _ b: TennisPoint) -> TennisFixed
    << canContact(_:) hit(side:sequence:charge:)
  priv canContact(_ side: TennisSide) -> Bool
    << TennisSimulation.step(tickInput:)
  priv hit(side: TennisSide, sequence: TennisSwingSequence, charge: Int)
    >> TennisRuleBook.contactQuality(distance:) TennisRuleBook.isSmashEligible(ballHeight:playerDistance:)
    >> TennisRuleBook.shotKind(for:smashEligible:) TennisRuleBook.isLegalServe(landing:server:court:)
    << TennisSimulation.step(tickInput:)
  priv serveLanding(server: TennisSide, player: TennisPlayerState, charge: Int) -> TennisPoint
    >> TennisRandomSource.nextInt(upperBound:)
    << TennisSimulation.hit(side:sequence:charge:)
  priv targetPoint(for side: TennisSide, shot: ShotKind, player: TennisPlayerState) -> TennisPoint
    >> TennisRandomSource.nextInt(upperBound:)
  priv surfaceSpeed() -> TennisFixed
  priv advanceBall()
    >> inside(_:_: ) receivingSide(at:) end(_:) emit(_:)
  priv receivingSide(at point: TennisPoint) -> TennisSide
  priv baselineCenter(for side: TennisSide) -> TennisPoint
  priv inside(_ rect: TennisRect, _ point: TennisPoint) -> Bool
  priv end(_ reason: PointEndReason)
    >> emit(_:)
  priv emit(_ kind: TennisSimulationEventKind)
    >> TennisSimulationDelegate.simulationDidEmit(_:)

// ALIASES: public typealias TennisFixed = Int32.
```

The fixed-tick simulation owns all gameplay mutation, integer/fixed-point state, deterministic
seed consumption, serve phase/landing, landing-point legality, and point-end semantics. A reset
point starts in `serveWindUp` with `serveWindUpTicksRemaining` set to
`serveWindUpDurationTicks` (12). Movement is rejected during wind-up. Each fixed gameplay tick
consumes one remaining wind-up tick without launching; only a server swing received on a later
fixed tick, after the counter reaches zero, performs the one-time launch transition to `rally`.
Serve input received during the countdown is ignored by the simulation and cannot be replayed as a
launch merely because the button remains held; input re-arming remains owned by TennisInput. An
illegal serve is represented as `serveFault(server:landing:)`; `pointWinner(for:)` awards the
point to the receiver. `secondBounce(side:)` identifies the receiving side at the second landing,
and the winner is the opposite side. Human intent is processed before CPU intent on simultaneous
contact.

The five swing sequences remain canonical in `TennisCore`: standalone A → topspin, standalone B
→ slice, A-then-B → lob, B-then-A → drop, and simultaneous A+B → smash when eligible, otherwise
flat. `ShotCommand` is internal/reserved and is not a `step` parameter.

`TennisSimulation.resetPoint(server:)` is a gameplay-state reset, not a clock operation. It
restores the server, players, ball, and point-end fields while preserving `state.tick`; the
runtime coordinator owns the monotonic fixed tick and calls reset only after the point-end step.
The match reset follows the same rule: it clears match/point state without creating an extra
simulation tick or rewinding the runtime clock.

The fixed-tick ball integration owns the seconds-based RVK-10/TZL-8/TZL-9 pacing envelopes in
[gameplay.md](../../../specs/tennis/gameplay.md) and [match_hud.md](../../../specs/tennis/match_hud.md):
surface speed, shot arc, bounce response, and charge affect simulation state and events. Renderer
cadence is not a pacing control. The current 16 ms fixed cadence quantizes the 0.192-second
RVK-18 serve wind-up to 12 gameplay ticks and the 0.128-second post-bounce response floor to
8 ticks. The acceptance matrix observes existing snapshots/events at fixed ticks;
“contact opportunity” is an acceptance-derived boundary from immutable state and current contact
rules, not a new public simulation accessor or event. Matched surface comparisons use the same
deterministic seed, initial state, target, and charge band while preserving Clay > Hard > Grass
travel ordering.

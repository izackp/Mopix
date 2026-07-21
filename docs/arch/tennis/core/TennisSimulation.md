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
  pub players: [TennisSide: TennisPlayerState]
  pub ball: TennisBallState
  pub pointEnd: PointEndReason?
  pub hitstopTicksRemaining: Int
  pub init(tick: UInt64, server: TennisSide, players: [TennisSide: TennisPlayerState], ball: TennisBallState, pointEnd: PointEndReason? = nil, hitstopTicksRemaining: Int = 0)

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
seed consumption, serve landing, landing-point legality, and point-end semantics. An illegal
serve is represented as `serveFault(server:landing:)`; `pointWinner(for:)` awards the point to
the receiver. `secondBounce(side:)` identifies the receiving side at the second landing, and the
winner is the opposite side. Human intent is processed before CPU intent on simultaneous contact.

The five swing sequences remain canonical in `TennisCore`: standalone A → topspin, standalone B
→ slice, A-then-B → lob, B-then-A → drop, and simultaneous A+B → smash when eligible, otherwise
flat. `ShotCommand` is internal/reserved and is not a `step` parameter.

// TEST: fixed-seed replay produces identical states/events, including legal and illegal serves.
// TEST: landing-only serve legality, receiver winner, second-bounce side, and baseline reset.
// TEST: all sequence mappings, smash fallback, contact bands, simultaneous-contact priority,
// same-tick bounce, net/out faults, and smash/full-charge hitstop.

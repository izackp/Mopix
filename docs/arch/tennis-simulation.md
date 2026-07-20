# Tennis Simulation Signature

```swift
// OWNED BY: TennisMatchRuntime owns the active TennisSimulation and its immutable rules.
// DEPENDENCIES: Foundation value types only; no renderer, SDL, VirtualController, or menu types.
// Fixed-tick only. All gameplay state uses Int or fixed-point integers; no Float/Double state
// or floating-point-dependent branches. A fixed seed is supplied by the match owner.

typealias TennisFixed = Int32

struct TennisPoint {
    var x: TennisFixed
    var y: TennisFixed
}

struct TennisVelocity {
    var x: TennisFixed
    var y: TennisFixed
    var z: TennisFixed
}

enum TennisSide {
    case human
    case cpu
}

enum CourtSurface {
    case hard
    case clay
    case grass
}

struct PlayerStats {
    var power: Int
    var speed: Int
    var control: Int
    var spin: Int
}

enum PlayerPreset {
    case balanced
    case power
}

struct CourtRules {
    let surface: CourtSurface
    let singlesBoundary: TennisRect
    let serviceBoxes: TennisServiceBoxes
    let netY: TennisFixed
}

struct TennisRect {
    let minX: TennisFixed
    let minY: TennisFixed
    let maxX: TennisFixed
    let maxY: TennisFixed
}

struct TennisServiceBoxes {
    let topLeft: TennisRect
    let topRight: TennisRect
    let bottomLeft: TennisRect
    let bottomRight: TennisRect
}

enum ShotKind {
    case topspin
    case slice
    case flat
    case lob
    case drop
    case smash
    case serve
}

enum ContactQuality {
    case perfect
    case good
    case poor
}

struct ShotCommand {
    let side: TennisSide
    let kind: ShotKind
    let target: TennisPoint
    let charge: Int
    let contactQuality: ContactQuality
}

struct TennisPlayerState {
    let side: TennisSide
    var position: TennisPoint
    var stats: PlayerStats
    var preset: PlayerPreset
    var swingPending: Bool
    var hitstopTicksRemaining: Int
}

struct TennisBallState {
    var position: TennisPoint
    var height: TennisFixed
    var velocity: TennisVelocity
    var shotKind: ShotKind
    var lastHitter: TennisSide?
    var isInFlight: Bool
}

enum PointEndReason {
    case secondBounce(side: TennisSide)
    case netFault(hitter: TennisSide)
    case outOfBounds(hitter: TennisSide)
}

struct TennisSimulationState {
    var tick: UInt64
    var server: TennisSide
    var players: [TennisSide: TennisPlayerState]
    var ball: TennisBallState
    var pointEnd: PointEndReason?
    var hitstopTicksRemaining: Int
}

struct TennisSimulationEvent {
    let tick: UInt64
    let kind: TennisSimulationEventKind
}

enum TennisSimulationEventKind {
    case serveHit(side: TennisSide)
    case shotHit(side: TennisSide, shot: ShotKind, quality: ContactQuality)
    case bounce(surface: CourtSurface)
    case netContact(side: TennisSide)
    case outOfBounds(side: TennisSide)
    case pointEnded(reason: PointEndReason)
}

protocol TennisRandomSource {
    func nextInt(upperBound: Int) -> Int
}

protocol TennisRuleBook {
    func playerStats(for preset: PlayerPreset) -> PlayerStats
    func contactQuality(distance: TennisFixed) -> ContactQuality
    func isSmashEligible(ballHeight: TennisFixed, playerDistance: TennisFixed) -> Bool
    func shotKind(for sequence: TennisSwingSequence, smashEligible: Bool) -> ShotKind
    func isLegalServe(landing: TennisPoint, server: TennisSide, court: CourtRules) -> Bool
    func pointWinner(for reason: PointEndReason) -> TennisSide
}

protocol TennisSimulationDelegate: AnyObject {
    func simulationDidEmit(_ event: TennisSimulationEvent)
}

final class TennisSimulation {
    let rules: CourtRules
    let ruleBook: TennisRuleBook
    let random: TennisRandomSource
    weak var delegate: TennisSimulationDelegate?
    private(set) var state: TennisSimulationState

    init(rules: CourtRules, ruleBook: TennisRuleBook, random: TennisRandomSource, state: TennisSimulationState)
    func step(tickInput: TennisTickInput)
    func snapshot() -> TennisSimulationState
    func resetPoint(server: TennisSide)
}

struct TennisTickInput {
    let human: TennisActionIntent
    let cpu: TennisActionIntent
}
```

`TennisSimulation.step` is the only owner of ball movement, bounce/net/out legality,
contact resolution, hitstop, and point-end events. Simultaneous contact is resolved by
the fixed `human`-before-`cpu` priority inside this subsystem, never by caller order.
The bounce crossing must clamp height to zero and apply the bounce on the same tick.
Target vectors should be selected from predefined court targets or fixed integer vectors;
there is no runtime normalization requirement.
`TennisActionIntent.swing`'s `TennisSwingSequence` (defined in the input/controller
signature) carries the resolved press pattern only; `TennisSimulation.step` is the sole
caller of `TennisRuleBook.shotKind(for:smashEligible:)`, which maps `standaloneA` →
topspin, `standaloneB` → slice, `aThenB` → lob, `bThenA` → drop, and `simultaneousAB` →
smash when `isSmashEligible` else flat. `ShotCommand` is a reserved value type for the
rule book's internal use and is not a `step` parameter; it is not required to build the
first deterministic slice.

// TEST: fixed-seed replay produces identical `TennisSimulationEvent` sequences.
// TEST: serve legality, all five rally shot kinds, smash fallback, contact-quality bands,
// simultaneous human priority, same-tick bounce, net fault, out fault, and second bounce.
// TEST: hitstop occurs only for smash and fully charged shots; routine contacts remain fluid.

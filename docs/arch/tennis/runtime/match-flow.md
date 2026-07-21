# Tennis runtime/match-flow [Tennis]

```swift
// TARGET: Tennis executable
// OWNED BY: TennisMatchRuntime owns match score, screen state, controllers, simulation,
// and the single seeded random source. It is registered with Application as fixed-tick IUpdate.
// DEPENDENCIES: GameEngine application APIs; TennisCore simulation types; TennisInput controller
// types; presentation snapshot/event protocols. It does not issue renderer commands.

enum TennisScreen {
    case title
    case surfaceSelect
    case match
    case result
}

struct TennisScore {
    var human: Int
    var cpu: Int
}

struct TennisMatchConfig {
    let surface: CourtSurface?
    let seed: UInt64
    let humanPreset: PlayerPreset
    let cpuPreset: PlayerPreset
}

struct TennisMatchState {
    var screen: TennisScreen
    var score: TennisScore
    var server: TennisSide
    var pointsPlayed: Int
    var winner: TennisSide?
    var selectedSurface: CourtSurface?
}

enum TennisMatchEvent {
    case screenChanged(TennisScreen)
    case scoreChanged(TennisScore)
    case pointStarted(server: TennisSide)
    case matchEnded(winner: TennisSide)
}

protocol TennisMatchDelegate: AnyObject {
    func matchDidEmit(_ event: TennisMatchEvent)
}

protocol TennisMatchRandomFactory {
    func make(seed: UInt64) -> TennisRandomSource
}

final class TennisMatchRuntime: IUpdate, TennisSimulationDelegate, TennisPresentationSnapshotSource {
    let config: TennisMatchConfig
    let randomFactory: TennisMatchRandomFactory
    let humanController: TennisController
    let cpuController: TennisController
    let simulation: TennisSimulation
    weak var delegate: TennisMatchDelegate?
    private(set) var state: TennisMatchState

    init(config: TennisMatchConfig, randomFactory: TennisMatchRandomFactory, humanController: TennisController, cpuController: TennisController, simulation: TennisSimulation, initialState: TennisMatchState)
    func step(_ delta: UInt64)
    func simulationDidEmit(_ event: TennisSimulationEvent)
    func selectSurface(_ surface: CourtSurface)
    func startMatch()
    func continueFromResult()
    func snapshot() -> TennisPresentationSnapshot
}

protocol TennisPresentationSnapshotSource {
    func snapshot() -> TennisPresentationSnapshot
}

struct TennisPresentationSnapshot {
    let screen: TennisScreen
    let score: TennisScore
    let server: TennisSide
    let surface: CourtSurface?
    let simulation: TennisSimulationState?
    let activeCharge: Int?
    let chargeCapReached: Bool
    let lastEvent: TennisMatchEvent?
}
```

The runtime advances through `Application.addFixedListener(_:msPerTick:)`; `delta` is
tick metadata, not permission to scale gameplay by elapsed frame time. Screen flow is
title → surface select → match → result → surface select. Server alternation and first-to
11-by-2 scoring live here, while point legality stays in `TennisSimulation`. Result state
does not auto-restart; `continueFromResult()` performs the explicit return.

`TennisMatchRuntime` is the integration owner, not the declaration owner, of simulation and
controller objects. Their canonical signatures remain in [../core/simulation.md](../core/simulation.md)
and [../input/controllers.md](../input/controllers.md).

// TEST: score reaches first-to-11 only with a two-point lead; server alternates every two points.
// TEST: illegal serve awards the point immediately and emits the correct result event.
// TEST: result screen persists until continue and selected surface is used for the next match.

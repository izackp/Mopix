# Tennis Match Feedback Signature

```text
// TARGET: Tennis executable
// OWNED BY: TennisMatchFeedbackReducer owns transient, renderable feedback state and expiry. It
// translates authoritative match/simulation events into visual cues; it does not decide legality,
// score, shot kind, or surface physics.
// DEPENDENCIES: TennisSimulationEvent, TennisMatchPresentationEvent, PointEndReason, ShotKind,
// CourtSurface, and TennisMatchSnapshot; fixed-tick UInt64 timestamps. Renderer-free and no input
// dependency.

TennisMatchPresentationEvent
  shotHit(side: TennisSide, shot: ShotKind)
  bounce(surface: CourtSurface)
  netContact
  outOfBounds
  serveFault(landing: TennisPoint)
  pointEnded(reason: PointEndReason, winner: TennisSide)
  matchCompleted(winner: TennisSide)

TennisMatchFeedbackState
  pub shotTrail: ShotTrailCue?
  pub landingMarker: TennisLandingMarker?
  pub surfaceBounce: SurfaceBounceCue?
  pub pointEnd: PointEndCue?
  pub faultCallout: FaultCalloutCue?
  pub init(...)

TennisMatchFeedbackReducer
  pub state: TennisMatchFeedbackState
  pub consume(_ event: TennisMatchPresentationEvent, tick: UInt64)
  pub advance(to tick: UInt64)
  pub reset()
```

The reducer is the sole owner of transient cue lifetime. Topspin, slice, and smash map to red,
blue, and purple trail cues. Airborne balls produce a landing marker/shadow. Each surface has a
distinct bounce cue. Net fault and out-of-bounds resolve to different point-end cues, and a serve
fault produces the readable `FAULT` callout plus its reserved audio hook. Audio is an optional
consumer of the same event stream, not a dependency of visual feedback.

The coordinator translates simulation events and point lifecycle into
`TennisMatchPresentationEvent`; the reducer must never reconstruct events by polling mutable
simulation internals. Event timestamps use the coordinator's fixed tick, never render delta.

// TEST: equal event streams and fixed ticks produce equal feedback states and expiry transitions.
// TEST: serve fault, net fault, and out-of-bounds produce distinguishable visible cues.
// TEST: each shot kind and each CourtSurface selects its required trail/bounce variant.

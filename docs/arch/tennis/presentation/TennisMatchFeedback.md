# Sources/Tennis/TennisPresentation.swift — Match Feedback Signature

```text
// TARGET: Tennis executable
// OWNED BY: TennisMatchFeedbackReducer owns transient renderable feedback state and expiry. It
// translates authoritative TennisMatchPresentationEvent values; it does not decide legality,
// score, shot kind, or surface physics.
// DEPENDENCIES: TennisMatchPresentationEvent, PointEndReason, ShotKind, CourtSurface, SDLColor,
// TennisPoint, and fixed-tick UInt64 timestamps from TennisCore/presentation. Renderer-free and
// no input dependency.

TennisMatchPresentationEvent
  shotHit(side: TennisSide, shot: ShotKind)
  bounce(surface: CourtSurface)
  netContact
  outOfBounds
  serveFault(landing: TennisPoint)
  pointEnded(reason: PointEndReason, winner: TennisSide)
  matchCompleted(winner: TennisSide)

TennisShotTrail | Equatable
  pub color
  pub expiresAt

TennisLandingMarker | Equatable
  pub point
  pub expiresAt

TennisSurfaceBounce | Equatable
  pub surface
  pub expiresAt

TennisPointEndKind | Equatable

TennisPointEndCue | Equatable
  pub kind
  pub expiresAt

TennisFaultCallout | Equatable
  pub text
  pub landing
  pub expiresAt

TennisMatchFeedbackState | Equatable
  pub shotTrail
  pub landingMarker
  pub surfaceBounce
  pub pointEnd
  pub faultCallout
  pub init(shotTrail: TennisShotTrail? = nil, landingMarker: TennisLandingMarker? = nil, surfaceBounce: TennisSurfaceBounce? = nil, pointEnd: TennisPointEndCue? = nil, faultCallout: TennisFaultCallout? = nil)

TennisMatchFeedbackReducer
  pub private(set) state: TennisMatchFeedbackState
  pub init()
  pub consume(_ event: TennisMatchPresentationEvent, tick: UInt64)
  pub advance(to tick: UInt64)
  pub reset()
```

`consume` maps topspin/slice/smash to trail colors, records surface bounce and distinct net/out
point-end cues, and creates the `FAULT` callout for serve faults. `advance` expires all transient
state. `TennisScene` owns the reducer instance and calls both consume and advance once per drawn
match snapshot. The current reducer declares landing-marker state but does not populate it; the
scene supplies the required airborne-ball shadow directly from simulation state.

// TEST: equal event/tick streams produce equal feedback states and expiry transitions.
// TEST: serve fault, net fault, and out-of-bounds remain distinguishable.
// TEST: each shot kind and each CourtSurface produces the declared reducer state.

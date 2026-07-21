# Sources/TennisCore/TennisMatchScore.swift [TennisCore]

```text
// TARGET: TennisCore
// OWNED BY: TennisCore owns match scoring state and deterministic point-to-match transitions.
// DEPENDENCIES: Foundation value types only. No GameEngine, TennisInput, renderer, SDL,
// match coordinator, or presentation dependency.

TennisMatchScore | Equatable
  pub humanPoints: Int
  pub cpuPoints: Int
  pub server: TennisSide
  pub pointsSinceServerRotation: Int
  pub matchWinner: TennisSide?
  pub init(humanPoints: Int, cpuPoints: Int, server: TennisSide, pointsSinceServerRotation: Int = 0, matchWinner: TennisSide? = nil)

TennisMatchResolution | Equatable
  pub pointWinner: TennisSide
  pub score: TennisMatchScore
  pub matchWinner: TennisSide?
  pub init(pointWinner: TennisSide, score: TennisMatchScore, matchWinner: TennisSide?)

TennisMatchScorekeeper
  pub private(set) score: TennisMatchScore
  pub init(initialServer: TennisSide)
  pub reset(server: TennisSide)
  pub recordPoint(winner: TennisSide) -> TennisMatchResolution
  priv incrementedScore(for winner: TennisSide) -> TennisMatchScore
  priv matchWinner(for score: TennisMatchScore) -> TennisSide?
  priv rotatedServer(after score: TennisMatchScore) -> TennisSide
```

`TennisMatchScorekeeper` is the only owner of point totals, server-rotation count, and match
completion state. `server` identifies the server for the next point. A point increments exactly
one side, then the server changes after every second completed point. Match completion is reached
only when the leading side has at least 11 points and leads by at least 2; a 10–10 score does not
complete the match. The scorekeeper does not inspect `PointEndReason`; the coordinator first asks
`TennisRuleBook.pointWinner(for:)`, including receiver-wins serve faults, then records that side.

// TEST: first-to-11 completion, win-by-two at 10–10, both winner paths, and no premature match end.
// TEST: server remains through one point, rotates after two points, and rotation resets its counter.
// TEST: scorekeeper transitions are deterministic and preserve the supplied initial server.

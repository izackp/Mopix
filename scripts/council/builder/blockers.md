# Builder Blockers

No active blockers.

## REVIEW-1 — 2026-07-20
**Classification**: BLOCKING
**File**: `Sources/GameEngine/TennisSimulation.swift`
**Issue**: Tennis-domain runtime state and input types were added to the generic `GameEngine`
target. The locked architecture assigns simulation ownership to the Tennis runtime and assigns
`TennisActionIntent`/sequence types to the input-controller boundary; this placement makes the
engine library own game-specific public API and prevents a clean Tennis module boundary.
**Expected**: Move the implementation into a Tennis-owned reusable target (prefer a small
`TennisCore` library target consumed by the `Tennis` executable and its focused test target),
with input-owned public types separated from simulation-owned types. `GameEngine` should expose
only the existing engine APIs.
**Status**: RESOLVED — 2026-07-20

## REVIEW-2 — 2026-07-20
**Classification**: BLOCKING
**File**: `Sources/GameEngine/TennisSimulation.swift`
**Issue**: The implementation still exposes `TennisActionIntent.swing(buttons:charge:)`, while
the locked input and simulation signatures require `swing(sequence:charge:)` with
`TennisSwingSequence`. It also has no `TennisRuleBook.shotKind(for:smashEligible:)`, so the
simulation cannot distinguish standalone A/B from A→B Lob and B→A Drop. This is the exact
ambiguity previously identified in BLOCKER-1.
**Expected**: Carry the resolved sequence from the input boundary and have simulation-owned
rule logic map standaloneA→Topspin, standaloneB→Slice, A→B→Lob, B→A→Drop, and simultaneous
A+B→Smash when eligible, otherwise Flat. Update focused tests to use and verify that contract.
**Status**: RESOLVED — 2026-07-20

## REVIEW-3 — 2026-07-20
**Classification**: BLOCKING
**File**: `Sources/GameEngine/TennisSimulation.swift`
**Issue**: Second-bounce termination stores `lastHitter` in `PointEndReason.secondBounce(side:)`,
but `side` is the side on which the second bounce occurred. The point-winner rule then awards
the point to the opposite side, so a ball hit by Human and bouncing twice on CPU's side is
represented as a Human-side bounce and awards Human the point.
**Expected**: Track the receiving/court side at the bounce location and emit that side in
`secondBounce(side:)`; keep `pointWinner` as the opposing-side winner. Add a test where the
last hitter and bounce side differ.
**Status**: RESOLVED — 2026-07-20

## REVIEW-4 — 2026-07-20
**Classification**: BLOCKING
**File**: `Sources/GameEngine/TennisSimulation.swift`
**Issue**: RVK-12 requires power, speed, control, and spin to affect shot speed, move speed, aim
precision, and spin/bounce strength. The implementation only uses speed for movement; power,
control, and spin do not affect gameplay state or shot outcomes.
**Expected**: Apply all four preset stats through deterministic integer/fixed-point rules, or
escalate a spec amendment to PL before changing the contract. Do not silently ship unused public
stats. Add focused tests proving each stat changes its specified outcome.
**Status**: RESOLVED — 2026-07-20

## REVIEW-5 — 2026-07-20
**Classification**: BLOCKING
**File**: `Tests/GameEngineTests/GameEngineTests.swift`
**Issue**: Focused tests cover one replay tick, smash/fallback, bounce/net/out, rule-book serve
legality, and contact bands, but do not cover the locked `// TEST:` contract for Lob, Drop,
Topspin/Slice mapping, illegal-serve point termination, hitstop on fully charged non-smash
shots, surface-specific profiles, or second-bounce side/winner semantics.
**Expected**: Add focused deterministic tests for each listed regression-prone contract after the
swing-sequence API is corrected. Tests must assert event kind and relevant state, not merely that
the simulation advances.
**Status**: RESOLVED — 2026-07-20

## REVIEW-6 — 2026-07-20
**Classification**: NON-BLOCKING FOR SIMULATION HANDOFF; BLOCKING FOR PACKAGE-GREEN RELEASE GATE
**File**: `Sources/Tennis/TennisScene.swift`
**Issue**: Package-wide `swift test`/build currently fails because the pre-existing presentation
slice references nonexistent `RendererClient`; the actual engine API is `DisplayRenderClient`.
This failure is outside the simulation's fixed-point/determinism boundary and does not indicate a
simulation implementation defect.
**Expected**: Defer correction to the Tennis presentation slice, where the scene and future
`TennisPresentation` implementation must use `DisplayRenderClient`. Do not block simulation
handoff on this renderer migration, but do not call the overall package build green until it is
fixed.
**Status**: OPEN

## REVIEW-7 — 2026-07-20
**Classification**: BLOCKING
**File**: `Sources/GameEngine/TennisSimulation.swift`
**Issue**: Serve legality is checked against the ball's current position before a serve flight,
not against the serve's landing point. An illegal serve is then encoded as `netFault`, even when
the serve simply misses the diagonally opposite service box. This does not satisfy RVK-3/RVK-4's
landing-point rule or provide a truthful point-end cue.
**Expected**: Model a deterministic serve target/landing and evaluate service-box legality at
that landing point. If the locked event/reason model cannot represent an illegal serve distinctly,
escalate that contract gap to PL before implementation; do not silently relabel every service
fault as a net fault.
**Status**: RESOLVED — 2026-07-20

## BLOCKER-1 — 2026-07-20
**File**: `Sources/GameEngine/TennisSimulation.swift`
**Issue**: The locked `TennisActionIntent.swing(buttons:charge:)` carries no sequence/kind information. The simulation therefore cannot distinguish `A -> B` Lob from standalone `A` Topspin, or `B -> A` Drop from standalone `B` Slice; `ShotCommand` is not accepted by `TennisSimulation.step`.
**Attempted**: Asked ARCH directly twice through `council.sh`; no answer was returned. Implemented the unambiguous standalone, flat, serve, and smash-fallback paths and left sequential mapping unresolved.
**Question for Architect**: Specify the intended mapping/state owner without silently changing the locked contract, or approve the smallest contract addition needed to carry resolved shot kind.
**Status**: RESOLVED — 2026-07-20

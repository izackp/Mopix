# Builder Blockers

No active blockers.

## REVIEW-34 — 2026-07-21
**Classification**: BLOCKING FOR FINAL ARCHITECTURE VERIFICATION
**File**: `docs/arch/tennis/presentation/index.md`, `docs/arch/tennis/runtime/TennisScene.md`
**Issue**: The current source and regenerated maps correctly contain no Tennis-specific headless
evidence driver or observation API, but these architecture docs still describe a “required
headless observation seam,” an “end-to-end evidence trace,” and integration accessors consumed by
“the deterministic headless evidence driver.” Those statements authorize deleted implementation
scope and contradict REVIEW-32/33’s locked-spec contract.
**Expected**: Describe the integration accessors as test-only application-graph verification
seams, and remove references to a Tennis-specific headless evidence driver or required observation
trace. Keep the generic GameEngine headless loop as the only headless runtime path.
**Status**: RESOLVED — 2026-07-21

## REVIEW-35 — 2026-07-21
**Classification**: BLOCKING FOR FINAL RELEASE READINESS
**File**: `Tests/TennisTests/TennisMatchFlowTests.swift`, current release evidence
**Issue**: The current HEAD passes focused tests and proves selected-coordinator identity for hard,
clay, and grass, but it has no valid end-to-end player-visible evidence through title, surface
selection, each selected match, HUD/feedback, result hold, and continue. The prior c447842 evidence
used the Tennis-specific harness removed by b913513 and exited 133, so it cannot certify current
HEAD.
**Expected**: Produce equivalent current-HEAD evidence through the generic GameEngine headless
loop and SDL event path, or a documented manual run, covering all three surfaces and the complete
NQF flow. Do not restore a Tennis-specific driver or observation API.
**Status**: OPEN

## REVIEW-33 — 2026-07-21
**Classification**: BLOCKING FOR ARCHITECTURE VERIFICATION
**File**: `docs/arch/tennis/runtime/TennisApp.md`, `docs/arch/tennis/presentation/TennisMenuFlow.md`, `Sources/Tennis/TennisApp.swift.map`, `Sources/Tennis/TennisPresentation.swift.map`
**Issue**: Commit `b913513` removes the Tennis-specific headless harness and its observation API from source, but the committed architecture docs still declare and describe `TennisHeadlessScenario`, `TennisHeadlessFixedDriver`, `TennisHeadlessCaptureDriver`, `TennisHeadlessEvidenceSink`, `TennisPresentationObservation`, `makeObservation`, and `TennisFontTextRenderer.onDraw`. Regenerating CodeMapper for `Sources/Tennis` still writes maps containing those deleted symbols, so the source/map/signature sweep is not clean.
**Expected**: Remove the deleted harness and observation declarations from the architecture docs, then produce CodeMapper maps that match the checked-out source. Keep the live GameEngine headless loop and SDL event path as the only runtime execution path; do not restore Tennis-specific drivers merely to satisfy the stale contract.
**Status**: RESOLVED — 2026-07-21

## REVIEW-32 — 2026-07-21
**Classification**: BLOCKING FOR SPEC-BACKED ARCHITECTURE
**File**: `Sources/Tennis/TennisApp.swift`, `Sources/Tennis/TennisPresentation.swift`, `docs/arch/tennis/runtime/TennisApp.md`, `docs/arch/tennis/presentation/TennisMenuFlow.md`
**Issue**: `TennisHeadlessScenario`, `TennisHeadlessFixedDriver`, `TennisHeadlessCaptureDriver`, and `TennisHeadlessEvidenceSink` are implementation-driven scope, not contracts in the locked Tennis specs. `docs/specs/tennis/acceptance.proposal.md` is still a proposal and cannot authorize these Tennis-specific runtime types; the locked gameplay, HUD, and menu specs define player-facing behavior only.
**Expected**: Remove the Tennis-specific runtime-driver/evidence path from the implementation and architecture contract. Use the existing GameEngine headless loop and input/event path to drive the real `TennisApp`, including its registered fixed listener, SDL event listener, scene, and presentation flow; do not add a Tennis-specific runtime driver. Preserve only spec-backed runtime structure and verification seams.
**Status**: OPEN

## REVIEW-30 — 2026-07-21
**Classification**: BLOCKING FOR HEADLESS RELEASE EVIDENCE
**File**: `Sources/Tennis/TennisApp.swift:211`, headless acceptance artifacts
**Issue**: The multi-surface headless scenario writes a trace containing all three complete
surface cycles, but the executable then exits with status 133 (`Swift/ContiguousArrayBuffer.swift:
690: Fatal error: Index out of range`). After the final continue advances `surfaceIndex` to
`surfaces.count`, a subsequent post-draw callback evaluates `surfaces[surfaceIndex]` before the
completion guard, indexing `surfaces[3]`.
**Evidence**: `--tennis-evidence --screenshots ... --ticks 18 --write-commands` produced the
trace `title -> surfaceSelect -> match -> result -> result -> surfaceSelect` three times and
native 160x144 PNG/draw-command artifacts, but returned `EXIT=133`. The trace includes hard cue
17, clay cue 18, and grass cue 19, so this is a termination defect rather than missing coverage.
**Expected**: Make the finished scenario idempotent before indexing the surface array (or remove
the capture driver/mark completion before the next callback) so the same full evidence run exits
successfully with status 0 and preserves the three-surface trace.
**Status**: OPEN

## REVIEW-31 — 2026-07-21
**Classification**: BLOCKING FOR FINAL ARCHITECTURE VERIFICATION
**File**: `Sources/Tennis/TennisApp.swift.map`, `docs/arch/tennis/runtime/TennisApp.md`
**Issue**: The regenerated CodeMapper output does not match the source at `c447842`. The map
still declares the pre-cycle `TennisHeadlessScenario.tick` property and one-surface driver shape,
while source declares `surfaces`, `surfaceIndex`, `cycleTick`, `pendingSurfaceAdvance`, and
`evidenceSurfaces`, and `jsonObject(for:surface:)`. The committed TennisApp signature doc has the
same stale headless declaration and one-surface description.
**Evidence**: CodeMapper was rerun with `swift run --package-path ../CodeMapper CodeMapper
--sources "$PWD" --filter Tennis --path Sources/Tennis`; it wrote five maps, but
`Sources/Tennis/TennisApp.swift.map` still reports `priv tick` and
`jsonObject(for observation: TennisPresentationObservation)`. Source inspection reports the
cycle fields and the two-argument JSON helper. This prevents a clean map-to-signature sweep even
though package tests pass.
**Expected**: Regenerate a map that reflects the checked-out source and reconcile the intentional
multi-surface headless contract in `docs/arch/tennis/runtime/TennisApp.md` before the release
architecture gate. Do not treat the stale map as evidence of structural completeness.
**Status**: OPEN

## REVIEW-28 — 2026-07-20
**Classification**: BLOCKING FOR COMPLETE SURFACE RELEASE EVIDENCE
**File**: `Sources/Tennis/TennisApp.swift`, `Tests/TennisTests/TennisMatchFlowTests.swift`, headless acceptance artifacts
**Issue**: `--tennis-evidence` now proves the complete live path for one selected surface (grass):
title, surface select, selected match, shot/bounce feedback, result hold, and continue. The live
capture is hardcoded to `.grass`; hard and clay are covered by direct factory/scene tests, but no
second or third executable app-graph capture proves those selected coordinators replace the
registered listeners and scene for all three NQF-2 choices.
**Evidence**: `/tmp/tennis-arch-review.LDm1H0/tennis_evidence.json` contains
`title -> surfaceSelect -> match(grass) -> result -> result -> surfaceSelect`; the match command
IDs include shot trail `15` and grass cue `19`. `testSurfaceFactoryPropagatesSelectedCourtSurface`
and `testEachSurfaceBounceProducesDistinctCueAndAudioHook` are isolated coverage, not live
Application-loop evidence for each selection.
**Expected**: Parameterize the deterministic headless scenario or run equivalent executable
captures for hard, clay, and grass, asserting each selected surface's coordinator identity is the
one registered with both Application loops and injected into TennisScene, with its distinct cue
visible in command evidence.
**Status**: OPEN

## REVIEW-29 — 2026-07-20
**Classification**: BLOCKING FOR FINAL ARCHITECTURE RELEASE REVIEW
**File**: `docs/arch/tennis/runtime/TennisApp.md`, `docs/arch/tennis/runtime/TennisScene.md`, `docs/arch/tennis/presentation/TennisMenuFlow.md`, `Sources/Tennis/*.swift.map`
**Issue**: The regenerated maps contain implementation symbols introduced by `adf8861` that are
not declared in the committed signature docs: `TennisApp.replaceCoordinator`, the scene
`replaceCoordinator`/feedback observation seam, `TennisPresentationFlow.onCoordinatorChange`,
`makeObservation`, `TennisPresentationObservation.result`, and the executable's deterministic
headless scenario drivers. The maps otherwise reconcile the selected coordinator's remove/add
edges and the evidence call graph.
**Expected**: Reconcile the signature docs with the intentional runtime/evidence boundary before
calling the architecture release review complete. Keep test/evidence-only seams explicitly marked
as such and document the selected-coordinator replacement and observation ownership once.
**Status**: OPEN

## REVIEW-25 — 2026-07-20
**Classification**: BLOCKING FOR LIVE MATCH FLOW (BD-1 FOLLOW-THROUGH)
**File**: `Sources/Tennis/TennisApp.swift:48-57`, `Sources/Tennis/TennisScene.swift:42-53`
**Issue**: The selected-surface factory now creates distinct coordinators, and the focused factory
test proves hard/clay/grass `CourtRules.surface` values. However, `TennisApp` registers only the
initial hard coordinator at lines 55-56 and injects that same instance into `TennisScene` at line
53. `TennisPresentationFlow.beginMatch(surface:)` creates a new coordinator, but does not register
it with the fixed/event loops or replace the scene's coordinator. After surface selection, the new
match never advances and the scene continues observing the initial hard coordinator.
**Expected**: Make the selected match coordinator the registered fixed/event listener and the
scene's observed coordinator, or introduce an explicit runtime session owner that swaps all three
boundaries atomically. Verify a real key-driven selection for hard, clay, and grass reaches fixed
ticks, renders the selected rules/feedback, and can reach result.
**Status**: OPEN

## REVIEW-26 — 2026-07-20
**Classification**: BLOCKING FOR ARCHITECTURE REVIEW HANDOFF
**File**: `docs/arch/tennis/runtime/TennisApp.md`, `docs/arch/tennis/runtime/TennisMatchCoordinator.md`, `docs/arch/tennis/presentation/`, `Sources/Tennis/*.swift.map`
**Issue**: The fresh maps now include `makeSimulation(surface:)`, `makeCoordinator(surface:)`,
the `textRenderer` constructor dependency, `TennisTextRenderer`/`TennisFontTextRenderer`, the
surface audio hook, both charge branches, and surface cue calls. The committed architecture docs
still describe the pre-7bfe304 constructor/factory shape and do not declare these symbols or
dependencies, so the map-to-contract comparison is not clean.
**Expected**: Reconcile the architecture docs with the current on-disk maps before the next
implementation handoff; document the selected-coordinator ownership boundary explicitly. This is
documentation drift, not a request to change the locked TZL/NQF specs.
**Status**: OPEN

## REVIEW-27 — 2026-07-20
**Classification**: BLOCKING FOR RELEASE EVIDENCE / FINAL USER-PLAY GATE
**File**: `Tests/TennisTests/TennisMatchFlowTests.swift`, headless acceptance artifacts
**Issue**: The full suite passes 33/33 and direct tests cover TTF command emission, isolated menu/
result transitions, surface rules, surface cue IDs/audio hooks, and both charge branches. The
headless run exits successfully and produces 160x144 PNG/JSON artifacts with real image glyph
commands; the title screenshot visibly contains `TENNIS` and `PRESS A`. It does not inject menu
input, so no headless evidence exists for surface-select, a selected match/HUD, feedback during a
point, result hold, or continue. The current tests also do not exercise the live app graph after
`beginMatch(surface:)`, which is the failure in REVIEW-25.
**Expected**: After REVIEW-25 is fixed, run a real user-play/headless path through title → each
surface-select option → match HUD → point feedback → result hold → continue. Capture screenshots
and draw-command evidence for readable TTF labels, score/server/charge HUD, distinct surface cues,
and result continuation. Full tests remain green.
**Status**: OPEN

**Remaining release blockers**: REVIEW-25 (selected coordinator is not live), REVIEW-26 (architecture
docs/maps are not reconciled to 7bfe304), and REVIEW-27 (no end-to-end user-play evidence). The
final user-play gate is a human-visible run proving all three surfaces and the complete NQF flow;
passing isolated tests or title-only screenshots is insufficient.

## REVIEW-20 — 2026-07-20
**Classification**: BLOCKING FOR ARCHITECTURE VERIFICATION
**File**: `Sources/Tennis/TennisPresentation.swift`, `Sources/Tennis/TennisApp.swift`, `Sources/Tennis/TennisMatchCoordinator.swift`, `Sources/Tennis/TennisScene.swift`, `docs/arch/tennis/presentation/`, `docs/arch/tennis/runtime/`
**Issue**: The implementation shape has diverged from the current presentation contracts, and the
on-disk CodeMapper artifacts do not represent the milestone. The live targeted CodeMapper stdout
contains `TennisPresentationFlow`, `TennisHUD`, `TennisMatchFeedbackReducer`, charge state, and
the new scene call graph, but the generated `TennisApp.swift.map` and
`TennisMatchCoordinator.swift.map` remain pre-milestone and no `TennisPresentation.swift.map` is
materialized. The contracts also name `TennisMatchFactory.make(surface:)`, HUD helper methods,
and `continueFromResult()` that are absent or replaced by a closure/private implementation.
**Expected**: Reconcile the presentation/runtime signature docs and regenerated maps with the
intentional implementation shape before the next architecture gate. Preserve the narrow
ownership boundaries; if the closure is retained, document it as the factory boundary and map
its surface dependency explicitly. Do not treat stale on-disk maps as verification evidence.
**Status**: OPEN

## REVIEW-21 — 2026-07-20
**Classification**: BLOCKING FOR PRESENTATION ACCEPTANCE
**File**: `Sources/Tennis/TennisPresentation.swift:145-156`
**Issue**: Title, surface-select, and result labels are emitted as solid `.fill` rectangles by
`TennisPresentationFlow.drawText`, not as readable text. Headless capture at 160x144 produced
`frame_1.png` through `frame_3.png` with only the background and two horizontal white bars;
each command JSON contained exactly three commands. The visible state cannot communicate
`TENNIS`, surface choices, winner, or continuation to a player.
**Expected**: Use the existing TTF/font rendering boundary for menu and result labels, with
distinct stable draw IDs, and provide draw-command/screenshot evidence for title, surface select,
match HUD, and result states. Result must remain visibly held until the continue input.
**Status**: OPEN

## REVIEW-22 — 2026-07-20
**Classification**: BLOCKING FOR MATCH-FEEDBACK ACCEPTANCE
**File**: `Sources/Tennis/TennisPresentation.swift:56-68`, `Sources/Tennis/TennisScene.swift:87-93`
**Issue**: The reducer records `surfaceBounce`, but `TennisScene` never renders that state. Thus
the required per-surface visual tell from TZL-6 is absent; hard, clay, and grass bounce events
have no distinct visible output. The landing-marker field is similarly unused, although the
scene's airborne-ball shadow does satisfy the alternative shadow path. Audio may remain silent
because TZL-5 reserves hooks rather than requiring shipped audio.
**Expected**: Render a distinct visual bounce variant keyed by `CourtSurface` and retain the
airborne shadow/marker path. Add evidence that all three surface events select different visible
draw output; do not add audio implementation as a substitute for the visual tell.
**Status**: OPEN

## REVIEW-23 — 2026-07-20
**Classification**: BLOCKING FOR HUD CONTRACT ACCEPTANCE
**File**: `Sources/Tennis/TennisMatchCoordinator.swift:61-68`
**Issue**: `latestCharge` is updated only from `humanIntent`. A CPU swing resets the snapshot to
zero with `activeSide` set to the server, so the HUD cannot show the active CPU player's charge or
cap cue. This does not satisfy TZL-3 or the current HUD contract's human/CPU charge boundary.
**Expected**: Publish the charge for the player whose current fixed-tick intent is active (human or
CPU), with deterministic reset/cap semantics, and verify both sides' charge indicators through
draw-command evidence. Keep charge ownership at the coordinator snapshot boundary rather than
letting HUD inspect TennisInput.
**Status**: OPEN

## REVIEW-24 — 2026-07-20
**Classification**: BLOCKING FOR SURFACE-SELECTION ACCEPTANCE (BD-1)
**File**: `Sources/Tennis/TennisApp.swift:34`, `Sources/Tennis/TennisApp.swift:68-81`
**Issue**: `TennisPresentationFlow` receives a factory closure that ignores its `CourtSurface`
argument and always returns the one coordinator created from `makeSimulation()`. That simulation
hardcodes `CourtSurface.hard`, so choosing clay or grass changes only
`state.selectedSurface`; the live match still runs hard-court rules. BD-1 is confirmed.
**Expected**: Build the selected surface into the match factory and construct a coordinator whose
`CourtRules.surface` and surface profile match the chosen value for every new match. Add a narrow
verification that hard, clay, and grass selections produce distinct coordinator snapshots/rules
and that result continuation returns to selection before creating the next coordinator.
**Status**: OPEN

**Next milestone**: Presentation contract reconciliation plus acceptance hardening. First align
the signature docs/maps with the intentional runtime shape; then make menu/result labels readable,
render surface-specific bounce cues, expose both human/CPU active charge values, and wire a
surface-aware `TennisMatchFactory`. Add focused draw-command/state-transition evidence for all
four screens and all three surfaces, then rerun CodeMapper, focused tests, full `swift test`, and
headless screenshots. No match spec amendment is required for surface selection: NQF-2 already
requires the selected MVP surface to flow into the match, and the current presentation contract
already has `make(surface:)`. Amend the contract only if PL explicitly chooses a mutable single
coordinator design instead of the existing factory-per-match boundary.

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

## REVIEW-18 — 2026-07-20
**Classification**: BLOCKING FOR CODEMAPPER VERIFICATION
**File**: `Sources/Tennis/TennisScene.swift`, `Sources/Tennis/TennisMatchCoordinator.swift`
**Issue**: Fresh CodeMapper generation for the Tennis executable writes a scene map whose
renderer parameters are still named `RendererClient`, despite the source and architecture
contract using `DisplayRenderClient`. The same run emits no `TennisMatchCoordinator.swift.map`,
so the new snapshot, coordinator tick, event, and simulation call graph cannot be swept against
the signature doc. This is a verification/tooling mismatch, not a failing compiled runtime path.
**Expected**: Regenerate maps that reflect the current source declarations and include the
coordinator's `TennisMatchSnapshot`, `snapshot()`, `step(_:)`, `onEvents(_:)`, and reset/event
dependencies. Re-run the map-to-signature comparison before declaring the vertical slice
architecture-verified.
**Status**: OPEN

## REVIEW-19 — 2026-07-20
**Classification**: BLOCKING FOR INTEGRATION TEST HANDOFF
**File**: `Tests/TennisTests/TennisMatchFlowTests.swift`
**Issue**: The seven runtime tests cover direct coordinator event injection, fixed stepping,
reset monotonicity, snapshot rendering, scoring, and completion, but none constructs
`TennisApp` or verifies the executable registration graph (`addFixedListener` and
`addEventListener`) with the same coordinator instance used by `TennisScene`. Deterministic
construction is present in `TennisApp.makeSimulation()` with fixed seeds, but there is no test
that two equivalent runtime constructions produce equivalent initial snapshots or that an
engine-delivered event traverses the registered application path.
**Expected**: Add a narrow executable integration test for app assembly/registration and a
same-seed construction assertion, or provide an equivalent test seam that proves the
input→registered fixed tick→simulation→snapshot→render path without duplicating the app graph.
**Status**: OPEN

## REVIEW-16 — 2026-07-20
**Classification**: BLOCKING
**File**: `Sources/Tennis/TennisMatchCoordinator.swift`, `Sources/TennisCore/TennisSimulation.swift`
**Issue**: A point-ending coordinator callback advances `TennisSimulation.state.tick` once in
`step`, then advances it again when `completePointIfNeeded()` calls `resetPoint(server:)`. The
focused test therefore observes `0 -> 2` for one fixed callback. This conflicts with the
da2159a coordinator contract that one fixed callback produces one simulation tick and creates a
second logic-tick transition at every point boundary.
**Expected**: Keep coordinator and simulation tick semantics consistent: one fixed callback must
advance simulation time once; point reset must not add an extra simulation tick, or the contract
must be explicitly amended before implementation proceeds.
**Status**: OPEN

## REVIEW-17 — 2026-07-20
**Classification**: BLOCKING
**File**: `Sources/Tennis/TennisApp.swift`
**Issue**: The new `TennisMatchCoordinator` is not assembled or registered by the runtime app.
`TennisApp` still creates only `TennisScene` and adds the window; it does not construct the
simulation/controllers/scorekeeper or call `addFixedListener` and `addEventListener`. The
match-flow tests exercise the coordinator in isolation, so the actual Tennis executable still
has no fixed-tick match flow, scoring, or controller wiring.
**Expected**: Implement the da2159a app wiring: assemble the TennisCore/TennisInput dependencies,
retain the coordinator, register it as the fixed-tick `IUpdate` listener and SDL event listener,
and keep renderer/presentation ownership separate.
**Status**: OPEN

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

## REVIEW-13 — 2026-07-20
**Classification**: BLOCKING FOR ARCHITECTURE-DOC HANDOFF
**File**: `docs/arch/tennis/runtime/TennisScene.md`
**Issue**: The source migration in 50c5249 correctly uses `DisplayRenderClient`, and the
`Tennis` target builds, but the CodeMapper output and signature doc still declare
`RendererClient` for `TennisScene.draw`, `fill`, and `view`. The architecture contract is stale
and no longer matches the source or current GameEngine API.
**Expected**: Update the TennisScene signature doc and its dependency/call annotations to
`DisplayRenderClient`; preserve the existing declaration-only structure.
**Status**: OPEN

## REVIEW-14 — 2026-07-20
**Classification**: BLOCKING FOR TEST-GREEN HANDOFF
**File**: `Tests/TennisInputTests/TennisInputControllerTests.swift:40`
**Issue**: The test-call correction now matches `TennisController.intent(for:tick:)`, but the
assertion still expects charge `1`. With the existing resolver contract, the initial held press
and the following held frame produce charge `2`; this is a stale expectation, not a b39/50 source
regression.
**Expected**: Correct the focused expectation to the resolver’s established deterministic charge
result, then rerun the TennisInput suite.
**Status**: OPEN

## REVIEW-15 — 2026-07-20
**Classification**: BLOCKING FOR TEST-GREEN HANDOFF
**File**: `Tests/TennisCoreTests/TennisSimulationTests.swift:35,69`
**Issue**: The two failing serve tests label a `serviceBoxes: .remote` fixture as illegal, but
the fixture also installs those remote rectangles as the active court service boxes. The
landing-based rule therefore sees the generated landing as legal. These are stale fixtures, not
a regression in 50c5249 or in the serve-fault implementation.
**Expected**: Make the illegal-serve fixture generate a landing outside the active court’s
service boxes while retaining a valid legal-serve fixture; preserve equal-seed landing/event
assertions and rerun TennisCore plus package-wide tests.
**Status**: OPEN

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

## REVIEW-8 — 2026-07-20
**Classification**: BLOCKING
**File**: `Sources/TennisCore/TennisSimulation.swift`
**Issue**: `resetPoint(server:)` resets the ball and hit state but does not restore either
player to a baseline position. `serveLanding` then derives the serve offset from the current
server position, so a server can remain away from baseline and the serve is no longer governed
by RVK-3's fixed baseline-center rule.
**Expected**: Establish the fixed baseline-center placement at the point-reset boundary, or add
an explicit match/simulation placement contract that guarantees it before a serve. The current
implementation leaves the required owner and invariant unenforced.
**Status**: RESOLVED — 2026-07-20

## REVIEW-9 — 2026-07-20
**Classification**: BLOCKING
**File**: `Tests/TennisCoreTests/TennisSimulationTests.swift`
**Issue**: The serve-fault test verifies one seeded landing and its fault event, but no focused
test compares two identical seeded serve simulations' landing points/events. The locked
simulation TEST note requires deterministic serve landing, and the existing multi-tick replay
test exercises a rally rather than the serve path.
**Expected**: Add a focused equal-seed serve replay assertion covering landing, legality result,
and emitted event shape for both legal and illegal serve cases.
**Status**: RESOLVED — 2026-07-20

## REVIEW-10 — 2026-07-20
**Classification**: NON-BLOCKING
**File**: `Sources/TennisCore/TennisSimulation.swift`
**Issue**: `ShotCommand` is documented as reserved/internal and unused by `TennisSimulation`,
but the implementation exposes it as a public TennisCore type, unnecessarily enlarging the
public module API.
**Expected**: Keep the reserved type internal or remove it when no longer needed; do not expose
unused implementation-only state as public API.
**Status**: RESOLVED — 2026-07-20

## REVIEW-11 — 2026-07-20
**Classification**: BLOCKING
**File**: `Package.swift`, `Sources/TennisCore/TennisInputControllers.swift`
**Issue**: The dependency-free TennisCore simulation target now depends on `GameEngine` solely
to host GameEngine-dependent input/controller types (`VirtualController`, `ICommandListener`,
and `InputCommandList`). This violates `tennis-simulation.md`'s simulation boundary and makes
the simulation transitively renderer/SDL-capable even though the simulation itself does not need
those APIs.
**Expected**: Keep `TennisCore` dependency-free. Move input/controllers into a separate
Tennis-owned target (for example `TennisInput`) that depends on both `GameEngine` and
`TennisCore`; place the input/controller tests in that target's test target. The Tennis
executable may depend on both runtime targets.
**Status**: RESOLVED — 2026-07-20

## REVIEW-12 — 2026-07-20
**Classification**: BLOCKING
**File**: `Sources/TennisCore/TennisInputControllers.swift`
**Issue**: `TennisCPUDecisionPolicy.rallyFloor` is stored but never read. The CPU therefore
commits a shot whenever it is in contact range and has no deterministic rally-safe/unforced-error
behavior corresponding to RVK-13's required 6–8-shot baseline.
**Expected**: Use the policy in a deterministic CPU decision state machine, or escalate a scope
decision before exposing the field. The implementation must preserve the same player-visible shot
vocabulary and seeded replay guarantees while honoring the rally-floor requirement.
**Status**: RESOLVED — 2026-07-20

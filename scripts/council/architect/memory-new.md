# ARCH scratch memory

## Task: tennis runtime signature docs

On branch `claude-tennis-game`, created declaration-only signatures in `docs/arch/` for
fixed-point deterministic simulation, input/controllers, match flow, and rendering/presentation.
Cross-subsystem check completed: no duplicate type purposes, boundaries are explicit, and specs
RVK-1..15, TZL-1..7, and NQF-1..4 are represented. No source implementation changed.

## Task: feasibility review of tennis proposals (docs/specs/tennis/)
Appended ARCH: feedback to gameplay.proposal.md, front_end.proposal.md, acceptance.proposal.md.

Key points raised:
- Gameplay sim (trajectory/bounce/contact-quality/spin) is float-shaped by nature but
  engine requires fixed-point/integer sim math — flagged as design-up-front item, not
  retrofit, since it also feeds acceptance's fixed-seed determinism requirement.
- PL-2 simultaneous contact: priority resolution must be deterministic (fixed index order),
  not processing-order dependent, or breaks replay/seed reproducibility.
- PL-8/GD-1 hitstop: no engine conflict either way; prefer scoped (smash-only) trigger for
  smaller diff surface, not a hard requirement.
- Front end: no existing audio subsystem in engine currently — placeholder hooks are cheap
  now, but wiring real audio later is a new subsystem, not a small add-on. Flagged as future
  cost, not a blocker (spec explicitly allows silence for MVP).
- VirtualDrive-only asset constraint reminder for Builder (routine, no proposal conflict).
- Acceptance fixed-seed requirement needs single seeded PRNG for CPU decisions, no ambient
  System.random calls — recommend spec state this explicitly.
- Debug viz toggle and per-tick log dump both cheap, fit existing IUpdate/addFixedListener
  pattern, no subprocess concerns (file I/O only).

No blocking objections — all feedback advisory/cost-flagging per spec-process.md rules
(ARCH never vetoes, PL may promote over unaddressed notes).

## Branch check resolved
User switched to `claude-tennis-game` before follow-up work; workflow rule (no edits on
non-claude branches) satisfied for all work below.

## Task: contract-fix on tennis-rendering-presentation.md
Builder handoff review across all four docs/arch/tennis-*.md signature docs against actual
source declarations:
- Confirmed bug: `tennis-rendering-presentation.md` declared `RendererClient` (9 sites:
  DEPENDENCIES comment, `TennisPresentation.draw`, all 8 `TennisDrawCommandSink` methods).
  Actual engine type per `Sources/GameEngine/Windowing/LiteWindow.swift:15`
  (`IDrawable.draw(_:_:)`) and `Sources/GameEngine/BatchRenderer/RPC/DisplayRenderClient.swift`
  is `DisplayRenderClient`. `RendererClient` has no surviving `.swift` source (map file
  only) — stale name. Corrected all 9 sites via sed to `DisplayRenderClient`.
- Verified `ImageAtlas` (ImageHandling/ImageAtlas.swift, public class), `AtlasLoader`
  (ImageHandling/ImageManager.swift, public class), `VDUrl` (Resources/VirtualDrive.swift,
  `public typealias VDUrl = URL`), `VirtualDrive` (public class) — all public, all
  compatible with doc usage, no visibility issues.
- Verified `VirtualController`, `ICommandListener`, `InputCommandList`, `IUpdate`,
  `IEventListener` (input-controllers.md, match-flow.md) all exist and are public.
- Structural check across all four docs: no function bodies (declaration-only), no
  Float/Double in any simulation-state type (tennis-simulation.md's "Float/Double" hit is
  prose in the DEPENDENCIES comment banning them, not a type usage).
- Only touched the rendering doc + this memory file; did not touch source, PL/GD files, or
  the other three arch docs (no issues found in them).
Committed as a separate ARCH contract-fix commit, pushed via cpush.sh.

## Task: minimal contract addition — swing-sequence ambiguity
Builder blocked: `TennisActionIntent.swing(buttons:charge:)` can't distinguish standalone
`A` (topspin) from a resolved `A -> B` (lob) — both collapse to `buttons={a}` once the
sequence resolver finishes. `ShotCommand` also unreachable (never a `step` param) —
confirmed vestigial by grep, not itself a blocker.

Decision: minimal additive contract change, not a workaround inside implementation.
- `tennis-input-controllers.md`: added `enum TennisSwingSequence` (standaloneA,
  standaloneB, simultaneousAB, aThenB, bThenA). Changed
  `TennisActionIntent.swing(buttons:charge:)` -> `swing(sequence:charge:)`, dropping the
  now-redundant raw `buttons` field (only consumer was this case).
- `tennis-simulation.md`: added `TennisRuleBook.shotKind(for sequence:smashEligible:)
  -> ShotKind`. Added prose stating `TennisSimulation.step` is the sole caller, mapping
  standaloneA/B -> topspin/slice, aThenB -> lob, bThenA -> drop, simultaneousAB -> smash
  (if `isSmashEligible`) else flat. Documented `ShotCommand` as reserved/internal, not
  required for the first deterministic slice.
- State-owner split: input layer (`TennisShotSequenceResolver`) owns press-sequence
  timing/resolution; simulation (`TennisRuleBook`) owns the eligibility-dependent
  Smash-vs-Flat split, since that needs ball height/distance (sim state), not input's to
  decide.
- Checked match-flow.md and rendering-presentation.md for stale references to the old
  shape — none found, no further edits needed there.
Not yet committed — pending same commit/push discipline as prior contract-fix (separate
ARCH commit via cpush.sh).

## Task: review c29e89c simulation milestone

Reviewed `c29e89c` against current locked architecture/specs and package APIs. Filed REVIEW-1..6
in `scripts/council/builder/blockers.md` without touching source, tests, specs, or PL files.
Blocking findings: simulation is incorrectly in generic GameEngine target, old swing-buttons
contract remains and sequence mapping is absent, second-bounce side/winner semantics are wrong,
RVK-12 power/control/spin effects are unused, and focused tests miss locked regression cases.
RendererClient failure is real for package-green status but non-blocking for simulation handoff;
it belongs to the later Tennis presentation slice and must use DisplayRenderClient.

## Task: serve-fault contract correction

Applied PL's RVK-3/RVK-4 decision to `tennis-simulation.md`: added distinct
`PointEndReason.serveFault(server:landing:)` and `TennisSimulationEventKind.serveFault`,
documented simulation-owned deterministic fixed-point landing calculation and landing-only
legality, and specified receiver-wins semantics through `pointWinner(for:)`. No source, tests,
specs, or PL files changed.

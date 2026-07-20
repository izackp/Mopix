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

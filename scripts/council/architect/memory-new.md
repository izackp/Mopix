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

## STOP — branch check
Current branch is `tennis`, does NOT start with `claude`. CLAUDE.md workflow rule: never
modify branches not prefixed `claude`; must stop and ask user before making any changes.
File edits to the three proposal.md files already made (content only, not committed).
Did NOT commit or push. Asked user how to proceed.

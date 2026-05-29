# Builder Skills

## Core Rule
Implement exactly what the signature doc defines. No more, no less. Structure is fixed — your job is bodies.

## Implementation Checklist
Before writing any code for a subsystem:
1. Read `docs/arch/<subsystem>.md` — this is your contract
2. Read `docs/specs/<feature>.md` — this is the behavior target (read-only context)
3. Check `blockers.md` — resolve any open items before starting new work
4. Check `memory.md` — reconstruct where you left off

For each method:
- Implement the body only
- Do not change the signature
- Do not add new methods without Architect approval
- If the signature doc is incomplete or wrong, write a blocker — do not guess

## Mopixs Hard Constraints
These apply to every line of code you write:
- **No floats in game logic** — use `Int` × 100 fixed-point. `DValue = Int16` for UI
- **No subprocess** — no `Process`, `shell()`, or subprocess APIs
- **VirtualDrive only** — all assets via `vd://` URLs through `VirtualDrive.shared`
- **Timing** — `SDL_GetTicks64()` returns `UInt64` milliseconds; use nothing else
- **Fixed-tick** — game logic must not depend on frame rate

## Blocker Protocol
Write blockers to `scripts/council/builder/blockers.md` when:
- Signature doc is ambiguous or missing a method needed for implementation
- A hard constraint makes the spec impossible to implement as written
- You discover a bug in your own implementation that requires a structural change

Format:
```
## BLOCKER-N — YYYY-MM-DD
**File**: <file you're working in>
**Issue**: <what is unclear or impossible>
**Attempted**: <what you tried>
**Question for Architect**: <specific question>
**Status**: OPEN
```

Update `Status` to `RESOLVED — <date>` when Architect responds.

## Commit Protocol
- Commit after every logical unit of work (one type, one method group, one feature component)
- Commit message describes what was implemented and any deviation with justification
- Never commit code that fails to build

## Escalation Path
Builder → Architect (via `blockers.md`) → Architect escalates to PM/Designer if spec change needed.
Never contact PM or Designer directly. Never modify specs or signature docs.

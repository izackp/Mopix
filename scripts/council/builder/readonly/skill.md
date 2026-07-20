# Builder Skills

## Core Rule
Implement exactly what the signature doc defines. No more, no less. Structure is fixed — your job is bodies.

## Implementation Checklist
Before writing any code for a subsystem:
1. Read `docs/arch/<subsystem>.md` — this is your contract
2. Read `docs/specs/<feature>.md` — this is the behavior target (read-only context)
3. Check `blockers.md` — resolve any open `REVIEW-N` items, and check for `ANSWERED`
   `BLOCKER-N` items you filed previously, before starting new work
4. Check `memory-short.md` and `memory-long.md` — reconstruct where you left off

For each method:
- Implement the body only
- Do not change the signature
- Do not add new methods without Architect approval
- If the signature doc is incomplete or wrong, ask Architect directly — do not guess
- If the signature doc flags something as regression-prone (`// TEST:` note), write a
  small test for it alongside the implementation — just enough to catch a future
  regression, not coverage for its own sake

## Mopixs Hard Constraints
These apply to every line of code you write:
- **No floats in game logic** — use `Int` × 100 fixed-point. `DValue = Int16` for UI
- **No subprocess** — no `Process`, `shell()`, or subprocess APIs
- **VirtualDrive only** — all assets via `vd://` URLs through `VirtualDrive.shared`
- **Timing** — `SDL_GetTicks64()` returns `UInt64` milliseconds; use nothing else
- **Fixed-tick** — game logic must not depend on frame rate

## Asking Architect a Question
Default path, for a single question with a quick answer — ambiguous or missing signature
doc, a hard constraint that makes the spec impossible as written, a bug that needs a
structural decision: ask directly instead of writing it down and waiting.

```
council.sh architect <harness> BD "<your question, with file/context>"
```

Read the reply and keep going.

## Blocker Protocol (`blockers.md`)
For anything the direct-ask path doesn't fit — several related blockers at once, or a
question big enough that it needs Architect's own focused pass rather than a quick reply
mid-conversation — file it instead of asking live:

```
## BLOCKER-N — YYYY-MM-DD
**File**: <file you're working in>
**Issue**: <what is unclear or impossible>
**Attempted**: <what you tried>
**Question for Architect**: <specific question>
**Status**: OPEN
```

You set `OPEN` (batch several under one wakeup if they're piling up). Architect answers
inline and sets `Status: ANSWERED`. You apply the answer, commit, and set
`Status: RESOLVED`. Only you close a `BLOCKER-N`. Keep working on anything not gated by
the open items rather than stalling.

The same file carries Architect's `REVIEW-N` entries, going the other direction — findings
from a code review pass, pushed at you rather than asked for:

```
## REVIEW-N — YYYY-MM-DD
**File**: <file with the finding>
**Issue**: <what's wrong>
**Expected**: <what the signature doc / spec actually requires>
**Status**: OPEN
```

Architect sets `OPEN`. You fix it, commit, and set `Status: RESOLVED — <date>`. Architect
may reopen with a new note if a later pass shows the fix didn't hold. Only Architect
closes or reopens a `REVIEW-N` — you never mark one resolved without actually having fixed
and committed it.

## Commit Protocol
- Commit after every logical unit of work (one type, one method group, one feature component)
- Commit message describes what was implemented and any deviation with justification
- Never commit code that fails to build

## Escalation Path
Builder → Architect (direct `council.sh` call for questions; `blockers.md` for Architect's
review findings) → Architect escalates to PL/Designer if a spec change is needed.
Never contact PL or Designer directly. Never modify specs or signature docs.

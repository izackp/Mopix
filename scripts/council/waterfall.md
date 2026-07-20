# Waterfall

## Goal

Make a tennis game (`Tennis` executable, Mopixs engine).

## Roles

PL (Product Leader) · GD (Game Designer) · ARCH (Architect) · Builder. Each is a persona
run via `council.sh <persona> <harness> <caller> "<message>"` — see `agent.md` for shared
rules (memory ritual, blocker-not-halt, branch safety), `spec-process.md` for the spec
format. `caller` is required, one of `PL`/`GD`/`ARCH`/`BD`/`USER` (the call fails
otherwise) — every invocation is logged to `scripts/council/log.txt` as `CALLER: message`
then `ACRONYM: response`, so the log actually shows who talked to whom.

## Flow

```
1. PL/GD  →  proposal          (what to build, product rules)
2. PL     →  ARCH               (is it feasible)
3. PL     →  spec               (locked, promoted, durable)
4. ARCH   →  signature docs     (code shape, no bodies)
5. Builder →  implementation    (bodies, commits, a regression test where ARCH flagged one)
6. Builder ⇄ ARCH                (live questions + review passes)
7. PL      →  milestone accept  (user plays the build — no agent can)

   GD/ARCH → PL  (spec itself has a gap — loops back to step 1, see "Iterating")
   Builder → ARCH → PL  (same, but Builder never contacts PL/GD directly)
```

### 1. PL/GD draft a proposal

PL (co-owner: GD) turns user intent into `docs/specs/tennis/<name>.proposal.md`, targeting
a spec file that may not exist yet. Rules only — no code, no implementation detail.
Undecided calls get raised as `PL-N`/`GD-N` items inline (problem, options, recommendation)
rather than guessed at.

### 2. GD and ARCH review

PL orchestrates — runs `council.sh designer ...` and `council.sh architect ...` against
the proposal, in either order, PL is the only one who triggers these. GD and ARCH are the
ones actually reviewing: both append feedback under the proposal's `## Feedback` section —
GD on feel/mechanics, ARCH on feasibility and engine-constraint fit. Feedback is
append-only: nobody edits another persona's line, ever, only adds a new one below it.
ARCH is advisory — PL may promote over an unaddressed ARCH note, never silently over a GD
objection without resolving it.

### 3. Convergence and promotion

PL resolves every open item — `PL-N`, `GD-N`, and `ARCH-N` alike, none of them exempt —
with the user where the call is genuinely theirs to make, otherwise PL decides directly
(final authority on scope/acceptance). Once nothing's left open, PL promotes: rules get
written into the target spec file under its 3-letter code (`RVK-1`, `WPX-1`, ...),
reasoning worth keeping goes to `ref/<ID>.md` (mandatory, not optional, if a GD objection
got overridden — see `spec-process.md`), and only then is the proposal file deleted. The
spec file is now durable — extended later, not rewritten from scratch.

### 4. ARCH writes signature docs

ARCH reads the promoted spec and produces `docs/arch/<subsystem>.md` — Swift
declarations, ownership, dependencies, zero function bodies. This is Builder's contract.
ARCH also runs cross-subsystem checks (no duplicate types, no undeclared dependencies)
before handing off — mandatory, since signature docs get no second-party review the way
specs do. Where something's easy to silently regress later, ARCH flags it for a small
test; Builder writes that test in step 5.

### 5. Builder implements

Builder reads the signature doc as contract, the spec as behavior target (read-only,
context only), fills in function bodies exactly as declared — no structural changes, no
extra methods. Commits after every logical unit of work.

### 6. Builder and ARCH talk directly

Three channels:
- **Builder asks ARCH, single question** — blocked on an ambiguous/wrong signature doc or
  an impossible-as-written constraint: `council.sh architect <harness> BD "<question>"`,
  synchronous, answered same-turn. No file, no waiting. Default path.
- **Builder asks ARCH, batch or complex** — several blockers at once, or something too big
  for a quick reply: filed to `scripts/council/builder/blockers.md` as `BLOCKER-N`. Builder
  opens, ARCH answers (`ANSWERED`), Builder applies and closes (`RESOLVED`). Builder keeps
  working on anything not gated by the open items rather than stalling.
- **ARCH reviews Builder** — after a subsystem's commits land (ARCH checks `git log`, no
  separate notification needed), ARCH posts findings to the same `blockers.md` as
  `REVIEW-N` entries. Builder fixes, commits, closes with `RESOLVED`. Only ARCH reopens.

Known rough edge: Builder calling ARCH while ARCH is itself mid-turn calling Builder
would resume the *same* stored ARCH session from two processes at once (`council.sh`
keeps one session per persona, no recursion guard). Accepted risk, not engineered around.

### 7. Milestone acceptance

Not yet formalized as a durable doc — acceptance criteria are milestone-scoped, not a
standing spec, so they get written per-milestone when a milestone is actually defined
(current working notes: `scripts/council/pl/tennis-acceptance-draft.md`, PL-only). No
agent can play the game, so PL doesn't self-certify a milestone as done — PL flags it as
ready and asks the user to play it.

## Iterating on a Live Spec

None of GD, ARCH, or Builder own a spec (PL+GD do, but only PL edits one). So a gap found
after promotion doesn't get fixed in place — it funnels back to PL, who decides whether
it's worth reopening:

- **GD** notices a gap (mid-review or on its own) → `council.sh pl <harness> GD "<gap>"`.
- **ARCH** notices a gap (same) → `council.sh pl <harness> ARCH "<gap>"`.
- **Builder** notices one → not direct to PL. Goes to ARCH first (step 6's live-question
  channel); ARCH decides whether it's a signature-doc fix or a real spec gap worth
  escalating to PL.

PL reopens a `.proposal.md` against the existing spec if warranted — same file, same
`.proposal.md` extension, `docs/specs/` already has the target — and it goes through
steps 1-3 again: GD/ARCH review, convergence, promote. If Builder's already implementing
against the old version, see "Amending an In-Progress Spec" in PL's skill doc — the change
doesn't propagate to `docs/arch/` or Builder on its own, PL has to notify ARCH.

## Loop

Steps 1-7 repeat per feature/milestone. Specs accumulate and get extended, not replaced;
`docs/arch/` and the codebase are the only things that change shape release to release.

## Known Accepted Risks

Not fixed, deliberately — tracked so they don't get rediscovered as surprises:
- **One working tree, no concurrency control.** Every persona reads and commits to the
  same tree. Run them sequentially, one at a time — nothing here handles two personas
  editing or committing at once.
- **Stale reads across sessions** (`issues.md` #3) — a resumed session may act on a file
  version that's since changed; relay prompts should say "re-read X" when that's a risk.
- **Chat-only decisions evaporate on rotation** (`issues.md` #5) — anything decided in
  conversation and not written to a spec, ref, or memory file is gone once the session
  rotates. Specs/refs are the durable record; chat isn't.
- **Builder's `SESSION_MAX_TURNS` rotation** (`issues.md` #4) — can land mid-subsystem;
  commit-per-logical-unit is the mitigation, not a fix.
- **Milestone acceptance criteria aren't durable yet** — parked at
  `scripts/council/pl/tennis-acceptance-draft.md` until a real milestone doc exists to
  hold them (step 7).

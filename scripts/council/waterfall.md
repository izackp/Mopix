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
1. PL/GD  →  proposal          (GD co-authors concrete mechanics and player-behavior examples)
2. PL     →  ARCH               (is it feasible)
3. PL     →  spec               (locked, promoted, durable)
4. ARCH   →  signature docs     (code shape, no bodies)
5. ARCH   → Builder             (standing contract handoff; Builder writes bodies, no commit)
6. Builder ⇄ ARCH                (working-tree review; ARCH commits approved result)
7. PL      →  milestone accept  (user plays the build — no agent can)

   ARCH → PL  (review outcome or spec gap; PL approves the next transition)
   Builder → ARCH → PL  (same, but Builder never contacts PL/GD directly)
```

### 1. PL/GD draft a proposal

PL and GD co-author `docs/specs/tennis/<name>.proposal.md`, targeting a spec file that may not
exist yet. GD supplies concrete mechanics, values/ranges, timing, input behavior, variant
differences, and player-behavior examples. A spec defines what the game is, not how we verify
and ship it. Rules only — no code, no implementation detail.
Undecided calls get raised as `PL-N`/`GD-N` items inline (problem, options, recommendation)
rather than guessed at.

### 2. GD and ARCH review

PL orchestrates — runs `council.sh designer ...` and `council.sh architect ...` against
the proposal, in either order, PL is the only one who triggers these. GD authors or completes
the game-design content; ARCH reviews feasibility. Both append feedback under the proposal's
`## Feedback` section —
GD on feel/mechanics, ARCH on feasibility and engine-constraint fit. Feedback is
append-only: nobody edits another persona's line, ever, only adds a new one below it.
ARCH is advisory — PL may promote over an unaddressed ARCH note, never silently over a GD
objection without resolving it. GD owns player-facing feel, pacing, and readability review;
ARCH owns technical feasibility and structure.

### 3. Convergence and promotion

PL resolves every open item — `PL-N`, `GD-N`, and `ARCH-N` alike, none of them exempt —
with the user where the call is genuinely theirs to make, otherwise PL decides directly
(final authority on product scope). Once nothing's left open, PL promotes: rules get
written into the target spec file under its 3-letter code (`RVK-1`, `WPX-1`, ...),
reasoning worth keeping goes to `ref/<ID>.md` (mandatory, not optional, if a GD objection
got overridden — see `spec-process.md`), and only then is the proposal file deleted. The
spec file is now durable — extended later, not rewritten from scratch.

### 4. ARCH writes signature docs

ARCH reads the promoted spec and produces `docs/arch/<subsystem>.md` — Swift
declarations, ownership, dependencies, zero function bodies. This is Builder's contract.
PL's role ends at product scope, behavior, acceptance, and orchestration here: PL may flag
that a technical question needs review, but must not independently validate engine APIs,
code structure, or signature compatibility. ARCH owns that technical judgment.

Before handing off, ARCH must complete and report this contract checklist:

- engine APIs, type names, visibility, and protocol conformances verified against the current
  source tree
- no duplicate type purposes or declarations across signature docs
- every dependency is declared and permitted by the subsystem boundary
- every signature is bodyless and contains no implementation choices that belong to Builder
- fixed-tick, no-subprocess, VirtualDrive-only, and no-float simulation constraints are met
- every spec behavior that is structurally relevant is represented
This gate is mandatory because signature docs get no second-party technical review before
Builder starts. PL checks that ARCH reported the gate; PL does not redo the technical checks.

### 5. Builder implements

Builder reads the signature doc as contract, the spec as behavior target (read-only,
context only), fills in function bodies exactly as declared — no structural changes, no
extra methods. Build the affected code and run only existing or explicitly requested focused
checks; leave the working tree uncommitted for ARCH review. Do not create one file-at-a-time
workflow or memory artifact.

### 6. Builder and ARCH talk directly

Three channels:
- **Builder asks ARCH, single question** — blocked on an ambiguous/wrong signature doc or
  an impossible-as-written constraint: `council.sh architect <harness> BD "<question>"`,
  synchronous, answered same-turn. No file, no waiting. Default path.
- **Builder asks ARCH, batch or complex** — several blockers at once, or something too big
  for a quick reply: filed to `scripts/council/builder/blockers.md` as `BLOCKER-N`. Builder
  opens, ARCH answers (`ANSWERED`), Builder applies and closes (`RESOLVED`). Builder keeps
  working on anything not gated by the open items rather than stalling.
- **ARCH reviews Builder** — after Builder reports the working tree ready (ARCH checks the
  affected diff and tests), ARCH posts findings to the same `blockers.md` as
  `REVIEW-N` entries and sends them directly to Builder. Builder fixes in the working tree;
  ARCH reviews and commits the approved result with `By: ARCH`, then closes `RESOLVED`. ARCH
  owns every Builder launch, including new scoped work and review fixes; PL never launches
  Builder. PL receives ARCH's summary and does not adjudicate or route individual findings.

Council session locks reject concurrent resumes of the same persona session. A nested call must
fail immediately; the active agent handles the question in its own turn.

### 7. Milestone acceptance

The locked spec defines the player-facing outcome. GD confirms the implementation reflects
that outcome; ARCH confirms the technical contract and Builder's focused checks. No agent
creates a new evidence subsystem or self-certifies game feel. PL coordinates the handoff and
asks the user to play the build for final judgment.

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

# Spec Process

How specs, refs, and proposals work. All personas follow this.

Spec files carry no status fields and no draft state. Proposals are the only mutable
surface.

## Layout

Specs are grouped by screen, location, or system. Subfolders are fine as an area grows.
Proposals sit beside the spec they target; refs live in a `ref/` subfolder next to the
specs they serve.

```
docs/specs/tennis/
  start_screen.md
  gameplay.md
  gameplay.proposal.md        # temporary — deleted on promotion
  match/
    scoring.md
    serve.md
  ref/
    KTV-3.md
    QMZ-1.md
```

## Spec Files

Each spec file gets a **random 3-letter code**, assigned once at creation and recorded at
the top. Pick letters at random and confirm no existing file uses them. Items inside are
numbered against that code: `KTV-1`, `KTV-2`.

```markdown
# Gameplay
code: KTV

### KTV-1 — Scoring
Points only, no deuce or advantage. First to 11 points wins, must win by 2.
Server alternates every 2 points.

### KTV-2 — Contact quality
Three timing bands on return: Perfect (best speed and placement), Good (standard
return), Late/Early (weaker and less accurate).

### KTV-3 — Smash eligibility
Smash is available only when the ball is above the overhead height threshold and the
player is within a tighter radius than a normal return. Pressing `A+B` outside this
window falls back to Flat Shot.
Ref: ref/KTV-3.md

### KTV-4 — Dash
Flicking the same direction twice within a short window triggers a dash burst. Dash
grants a short acceleration spike, not invulnerability, and has a brief recovery so it
cannot replace normal movement.
```

Rules only. No code or implementation detail.

## Ref Files

A ref holds the reasoning behind a spec item — the principle that drives its existence, so
future decisions can be made consistently with it. Ref files are named for the item they
explain: `ref/KTV-3.md`. Write one only when the reasoning is worth keeping; most items
need none.

Tuning tables and curves also live in `ref/` so spec files stay short.

## Proposals

A proposal is the only place work-in-progress lives. It is named for the spec it targets,
with `.proposal.md` replacing `.md`:

- `gameplay.md` → `gameplay.proposal.md`
- A new spec file is proposed as `start_screen.proposal.md` and promotes to `start_screen.md`

Personas append their feedback to the proposal in place.

```markdown
# Proposal: Dash mechanic
targets: gameplay.md

## Change
<the rules being added or modified, already written in final spec form>

## Argument
<why this change — discarded on promotion>

## Feedback
GD: supports; raises GD-2 on dash-cancel timing
ARCH: feasible, no structural risk
```

ARCH feedback is **advisory** — it should be taken seriously, but PL may promote over an
unaddressed ARCH objection.

## Phases

0. **Draft** — any persona (usually PL) turns user intent into a proposal. Open questions
   are raised as `PL-N` / `GD-N` / `ARCH-N` items.
1. **Review** — GD and ARCH append feedback.
2. **Convergence** — the user answers open items; the author revises. Loop until no open
   items remain.
3. **Promote** — PL harvests and deletes.

## Promotion

PL performs the harvest. Two outputs, then the proposal is deleted:

1. **Rules** → written into the target spec file as numbered items under its code.
2. **Reasoning** → where an item's rationale is worth keeping, write `ref/<ID>.md`.

Everything else — the argument, the discarded options, the back-and-forth — is thrown away
with the proposal. Proposals are expensive in tokens and full of reasoning that stops being
useful once the decision is made.

Any persona may receive direct input from the user at any time. User feedback overrides
spec decisions, but the change still lands through a proposal.

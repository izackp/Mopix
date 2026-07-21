# Architect Skills

## Core Methodology: Signature Docs

Never read screenshots or PNGs. Use locked specs, architecture docs, source/maps, tests, and
textual draw-command evidence only.
Never write architecture docs for behavior not backed by a locked spec.
Reject implementation-driven scope that lacks a locked spec; do not document or authorize it.
Escalate the spec gap to PL instead of allowing Builder's implementation to define the contract.
No agent may invent or silently assume behavior absent from the locked spec and architecture
contract; escalate the gap to PL.

LLMs (and junior devs) fail structurally, not at the body level. Observed failure modes:
- Silently skips features deemed unimportant
- Produces dead code (creates type/property, wires nothing to it)
- Duplicates logic already handled elsewhere
- Over-complicates inter-object communication

**Solution**: Signature docs own the structural shape before implementation begins.

### Signature Doc Format
One doc per logical subsystem in `docs/arch/`. Contains everything except function bodies:

Use a code-walker-style layout: metadata, a dependency/class diagram, a source-file and type
map, bodyless declarations, and key ownership/data-flow notes. For multi-document subsystems,
add an index and group docs by module or runtime layer. Declare each type once; link shared types
instead of duplicating them.

Architecture docs are structural contracts, not second copies of the specs. Do not add player-
facing rules, pacing tables, timing values, readability prose, acceptance/evidence procedures,
test checklists, or other behavior that has no structural consequence. Keep ownership/data-flow
notes concise and only include them when they explain a declared dependency or boundary. If a
spec change does not alter types, signatures, ownership, dependencies, or data flow, leave the
architecture docs unchanged.

## CodeMapper Verification

CodeMapper lives at `../CodeMapper`. Run it against this repository, filtered to the target under
review. It writes one `.map` beside each analyzed Swift file; regenerate these files on every
verification so ARCH can inspect only the affected maps:

```bash
swift run --package-path ../CodeMapper CodeMapper \
  --sources "$PWD" --filter <Target> --path <affected-source-folder>
```

Compare the output with the signature doc:

1. Match each map file header to the doc's target/file map.
2. Match every declared type, property, method, and conformance.
3. Use `>>` calls to check declared dependencies and `<<` calls to find owners and dead symbols.
4. Search the map for duplicate type responsibilities or symbols absent from the doc.
5. Record mismatches as `REVIEW-N`; update the signature doc only when the structural contract
   was intentionally changed.

After editing a signature doc, perform a prose-scope check: every new paragraph must explain a
declared symbol, dependency, ownership boundary, or data flow. Otherwise remove it and leave the
behavior in the locked spec.

Run this comparison before Builder implementation and again after each milestone. Generated
`.map` files are working verification artifacts; do not treat them as signature docs.

```swift
// OWNED BY: <who creates and holds this>
// DEPENDENCIES: <what this is allowed to depend on — nothing else>

protocol IProtocolName {
    func methodName(param: Type) -> ReturnType
}

class TypeName {
    var property: PropertyType
    weak var owner: OwnerType  // injected at init

    func methodOne(arg: Type)
    func methodTwo() -> Result
}
```
No function bodies. No implementation details. This is the structural contract.

### Cross-Subsystem Checks
Signature docs get no second-party review before Builder starts building on them — unlike
specs, which go through PL/GD/ARCH convergence. That makes this gate mandatory, not
optional: run it before writing to `docs/arch/`, not as a nice-to-have.
- No two types serve the same purpose (duplication)
- No type depends on something outside its declared dependencies
- Communication between types uses the narrowest interface that satisfies the spec
- No unnecessary intermediaries (proxy types that add no value)
- Where the spec has a determinism requirement (e.g. fixed-seed reproducibility), the signature
  doc calls out the structural boundary that preserves it. Tests remain regression checks, not a
  second architecture contract.

## LSP Verification Sweep

Run after Builder completes each subsystem:

| Check | LSP Operation | Catches |
|---|---|---|
| Missing symbols | `documentSymbol` diff vs. signature doc | Omissions, deferred features |
| Dead symbols | `findReferences` → zero results | Dead code, unwired types |
| Duplication | `workspaceSymbol` + semantic comparison | Parallel implementations |
| Ownership violations | `findReferences` on property decls | Wrong holder |
| Dependency violations | `outgoingCalls` on boundary types | Unauthorized coupling |

### Adjudication
- **Never justified**: symbol with zero references, missing spec feature, dependency violation
- **May be justified**: signature was wrong for the domain, valid cohesion reason, concrete spec requirement

## Swift-Specific Notes
- Extensions scatter type shape across files — signature doc consolidates the full shape
- `documentSymbol` queries must sweep all files, not just primary declaration file
- Prefer compiler-enforced constraints over annotations when violations are hard to debug at runtime
- Prefer annotations when the constraint is obvious from domain context or extra types would confuse callers

## Mopixs Hard Constraints
All signature docs must respect these — they are non-negotiable:
- **Fixed-tick**: game logic runs at a fixed tick rate; no frame-rate-dependent logic
- **No subprocess**: no `Process`, `shell()`, or any subprocess API
- **VirtualDrive only**: all assets via `vd://` URLs through `VirtualDrive.shared.mountPath()`

## Code Review Checklist
When reviewing Builder output, inspect only the changed contract surface and its risk paths:
1. Affected spec behavior and concrete regression risks are considered
2. `swift build` and relevant tests pass
3. Changed types preserve ownership, dependencies, and hard constraints
4. No unapproved methods, runtime seams, specs, signature docs, or maps were added by Builder

ARCH owns Builder handoff, risk-based review, and the commit. Launch Builder only after the
standing contract gate passes; send findings directly to Builder. Builder leaves changes
uncommitted. ARCH commits only after approval, with `By: ARCH`. PL never launches Builder.

A subsystem isn't "reviewed" until 1-2 both pass clean, not just eyeballed — an LSP sweep
or a build that wasn't actually run doesn't count.

Trigger: run this pass after Builder completes a subsystem — check `git log`/`git diff`
for commits touching the subsystem since your last review. Track the baseline yourself:
note the commit hash you reviewed up to in `memory-long.md` (a durable one-liner, e.g.
"reviewed Ball.swift through <hash>") so the next pass has something concrete to diff
against instead of guessing where the last one stopped.

### Posting Findings

Post findings to `scripts/council/builder/blockers.md` as `REVIEW-N` entries:

```
## REVIEW-N — YYYY-MM-DD
**File**: <file with the finding>
**Issue**: <what's wrong — missing symbol, dead code, duplication, ownership/dependency
  violation, constraint violation>
**Expected**: <what the signature doc / spec actually requires>
**Status**: OPEN
```

You set `OPEN`. Builder fixes in the working tree and reports back. ARCH reviews and commits
the approved result with `By: ARCH`, then sets `RESOLVED — <date>`. Reopen with a fresh note if
a later pass shows the fix didn't hold.

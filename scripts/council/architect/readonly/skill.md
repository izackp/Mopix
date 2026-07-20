# Architect Skills

## Core Methodology: Signature Docs

LLMs (and junior devs) fail structurally, not at the body level. Observed failure modes:
- Silently skips features deemed unimportant
- Produces dead code (creates type/property, wires nothing to it)
- Duplicates logic already handled elsewhere
- Over-complicates inter-object communication

**Solution**: Signature docs own the structural shape before implementation begins.

### Signature Doc Format
One doc per logical subsystem in `docs/arch/`. Contains everything except function bodies:

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
- Where the spec has a determinism/testability requirement (e.g. fixed-seed
  reproducibility), the signature doc calls out what's testable and how — this is where
  test coverage gets planned, since nobody plans it later (see Test Coverage below)

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

## Test Coverage

Tests here are only for regression prevention, nothing more. If a piece of logic is easy
to silently break later (fixed-point math, a scoring/legality rule), mark it `// TEST:` in
the signature doc — Builder writes a small test for it. No note, no test. Don't over-scope
this into general coverage.

## Mopixs Hard Constraints
All signature docs must respect these — they are non-negotiable:
- **Fixed-tick**: game logic runs at a fixed tick rate; no frame-rate-dependent logic
- **No subprocess**: no `Process`, `shell()`, or any subprocess API
- **VirtualDrive only**: all assets via `vd://` URLs through `VirtualDrive.shared.mountPath()`

## Code Review Checklist
When reviewing Builder output:
1. `swift build` passes clean
2. The LSP Verification Sweep above is clean (or every finding is filed as `REVIEW-N`)
3. Every method in the signature doc is implemented
4. No methods added beyond the signature doc (without justification)
5. No type depends on something outside its declared dependencies
6. No subprocess, float arithmetic in game logic, or direct asset access outside VirtualDrive

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

You set `OPEN`. Builder fixes and commits, then sets `RESOLVED — <date>`. You may reopen
with a fresh note if a later pass shows the fix didn't hold. Never mark a `REVIEW-N`
resolved yourself — that's Builder's transition to make, not yours.


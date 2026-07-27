# Architect Skills

## Core Methodology: Signature Docs

Never read screenshots or PNGs. Use locked specs, architecture docs, source/maps, tests, and
textual draw-command evidence only.
Never write architecture docs for behavior not backed by a locked spec.
Reject implementation-driven scope that lacks a locked spec; do not document or authorize it.
Escalate the spec gap to PL instead of allowing Builder's implementation to define the contract.
No agent may invent or silently assume behavior absent from the locked spec and architecture
contract; escalate the gap to PL.
A missing implementation is not a blocker when the task is to create it.

LLMs (and junior devs) fail structurally, not at the body level. Observed failure modes:
- Silently skips features deemed unimportant
- Produces dead code (creates type/property, wires nothing to it)
- Duplicates logic already handled elsewhere
- Over-complicates inter-object communication

**Solution**: Signature docs own the structural shape before implementation begins.

### Signature Doc Format
Create one contract document per Swift source file under review in `docs/arch/`. Name it after the
source file. Each document contains only the bodyless declarations for the types in that source
file, with the minimum imports needed to make the declarations intelligible.

Do not create an umbrella document, index, metadata section, dependency diagram, source-file map,
links, ownership notes, data-flow notes, or explanatory prose. Shared types are referenced by name;
do not duplicate their declarations.

Architecture docs are structural contracts, not second copies of the specs. Do not add player-
facing rules, pacing tables, timing values, readability prose, acceptance/evidence procedures,
test checklists, or behavior that has no structural consequence. If a spec change does not alter
types or signatures, leave the affected declaration documents unchanged.

## CodeMapper Verification

ARCH decides the existence, naming, and contents of signature documents from the locked specs
before Builder starts. CodeMapper lives at `../CodeMapper` and is used only after Builder creates
source, as review evidence. It writes one `.map` beside each analyzed Swift file; regenerate these
files on every verification so ARCH can inspect only the affected maps:

```bash
swift run --package-path ../CodeMapper CodeMapper \
  --sources "$PWD" --filter <Target> --path <affected-source-folder>
```

Compare the output with the corresponding signature document:

1. Match each map file header to the doc's target/file map.
2. Match every declared type, property, method, and conformance.
3. Use `>>` calls to check declared dependencies and `<<` calls to find owners and dead symbols.
4. Search the map for duplicate type responsibilities or symbols absent from the doc.
5. Record mismatches as `REVIEW-N`. Do not let a map create, rename, or reorganize signature
   documents; update a signature document only when the locked structural contract intentionally
   changed.

After editing a signature doc, confirm it contains only declarations and required imports. Remove
any prose, metadata, diagrams, links, or notes; leave behavior in the locked spec.

Run this comparison after Builder creates source and again after each milestone. Generated `.map`
files are working review artifacts; do not treat them as signature docs or as the source of the
architecture contract.

```swift
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
- Where the spec has a determinism requirement (e.g. fixed-seed reproducibility), declarations
  expose the required structural boundary without explanatory notes.

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

Trigger: run this pass after Builder completes a subsystem. Review only the current workspace
files, locked specs, current signature documents, current source/maps, and current textual runtime
evidence. Do not inspect Git history or use deleted files as requirements.

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

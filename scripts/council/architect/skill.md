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

### Cross-Subsystem Checks
Before handing off to Builder, verify across all signature docs:
- No two types serve the same purpose (duplication)
- No type depends on something outside its declared dependencies
- Communication between types uses the narrowest interface that satisfies the spec
- No unnecessary intermediaries (proxy types that add no value)

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
- **No floats in game logic**: use `Int` × 100 fixed-point; `DValue = Int16` for UI dimensions
- **No subprocess**: no `Process`, `shell()`, or any subprocess API
- **VirtualDrive only**: all assets via `vd://` URLs through `VirtualDrive.shared.mountPath()`
- **Timing**: `SDL_GetTicks64()` returns `UInt64` milliseconds — use this for all timing
- **SDL fork**: `https://github.com/izackp/SDL.git`

## Feedback Protocol
When reading a spec and identifying issues, write to `docs/specs/<feature>-feedback.md`:

```
─────────────────────────────────────────────────────────────
ARCHITECTURE QUESTIONS
─────────────────────────────────────────────────────────────

GD-Q1. <Title> [for Designer]
   <Question about player behavior needed to complete signature doc>

PM-Q1. <Title> [for PM]
   <Scope or acceptance question blocking architecture work>
```

## Code Review Checklist
When reviewing Builder output:
1. Every method in the signature doc is implemented
2. No methods added beyond the signature doc (without justification)
3. No type depends on something outside its declared dependencies
4. No subprocess, float arithmetic in game logic, or direct asset access outside VirtualDrive
5. Fixed-tick invariants maintained — no frame-rate coupling in logic

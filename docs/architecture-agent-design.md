# Architecture Agent Design

## Problem

LLMs fail structurally, not at the body level. Observed failure modes:
- Silently skips features it deems unimportant
- Defers design decisions without flagging
- Produces dead code (creates type/property/table, wires nothing to it)
- Duplicates logic already handled elsewhere in the codebase
- Invents unnecessary intermediaries; over-complicates inter-object communication
- Locally optimizes (body correctness) while degrading globally (structural completeness)

Function bodies are generally correct. The wiring, ownership, and completeness are not.

## Goals

1. **Spec completeness** — nothing in PM requirements silently dropped or deferred
2. **Reduce duplication** — architecture agent has cross-subsystem view; catches when two agents reinvent the same thing
3. **Simplify inter-object communication** — minimize dependencies, keep interfaces narrow, reduce coupling

## Solution Overview

Architecture agent owns **signature docs** — the complete structural shape of each subsystem, minus function bodies. These docs are:
- **Input** to implementation agents (they read and follow them)
- **Ground truth** for verification (LSP diffs catch divergence)
- **Persistent memory** across sessions (agent reconstructs context from docs + LSP, not conversation history)

Implementation agents fill in bodies. They do not design structure.

## Signature Docs

One doc per logical subsystem. Contains everything except function bodies:
- Protocol definitions and conformances
- Class/struct declarations with all properties
- Method signatures
- Ownership annotations (who creates this, who holds it)
- Dependency constraints (what this is allowed to depend on)

```swift
// OWNED BY: FullWindow
// DEPENDENCIES: RendererServer only — no direct SDL access

class RendererClient {
    weak var server: RendererServer  // injected at init
    var drawables: [IDisplayDrawable]

    func beginFrame()
    func sendCommands()
}

protocol IDisplayDrawable {
    func draw(context: RenderContext)
}
```

Docs live in `docs/arch/`. Not compiled — reference only.

## LSP Verification

High-level sweep after implementation. Agent queries at subsystem granularity to keep token cost low; drills into specific symbols only when flagged.

| Check | LSP Operation | Catches |
|---|---|---|
| Missing symbols | `documentSymbol` diff vs. doc | Omissions, deferred features |
| Dead symbols | `findReferences` → zero results | Dead code, unwired types |
| Duplication | `workspaceSymbol` + semantic comparison | Parallel implementations |
| Ownership violations | `findReferences` on property decls | Wrong holder |
| Dependency violations | `outgoingCalls` on boundary types | Unauthorized imports/coupling |

Dead code check is fully mechanical: any symbol in the signature doc with zero references is a guaranteed flag.

Transient ownership (local variables, factory patterns) surfaces in LSP when the agent drills into specific call sites — available on demand, not part of the high-level sweep.

Call ordering is not mechanically verifiable at the sweep level. Agent can inspect specific callees when order is a known constraint. Ordering invariants annotated in the doc are enforced by code review, not automation.

## Workflow

### Design Phase (architecture agent)
1. Read PM specs
2. Produce signature docs for affected subsystems
3. Check cross-subsystem signature docs for duplication and unnecessary coupling
4. Simplify: if two types need to communicate, design the narrowest interface that satisfies the spec

### Implementation Phase (implementation agent)
1. Read signature doc for assigned subsystem
2. Implement bodies only — structure is fixed
3. Report any deviations with justification

### Verification Phase (architecture agent)
1. Run LSP sweep: `documentSymbol` diff + `findReferences` zero-reference sweep
2. Check duplication across subsystems via `workspaceSymbol`
3. Adjudicate deviations:
   - Justified (doc was wrong for domain) → update signature doc
   - Unjustified → implementation agent fixes

### Adjudication Criteria

Never justified:
- Symbol in doc has zero references (dead code)
- PM spec feature absent from implementation
- Dependency constraint violated

May be justified:
- Signature was wrong for the domain (implementation revealed it)
- Method split/merged for valid cohesion reasons
- Concrete PM spec requirement demanded it

## Swift-Specific Notes

Extensions scatter a type's shape across multiple files. Signature doc consolidates the full shape. LSP `documentSymbol` queries must sweep all files for the type, not just the primary declaration file.

## Compiler-Enforced vs. Annotated Constraints

Ordering, ownership, and state machine transitions can be encoded in the type system (making illegal states unrepresentable) or expressed as comments/annotations in the signature doc.

**Prefer compiler-enforced when:**
- Violation is hard to debug at runtime
- Constraint is non-obvious to someone unfamiliar with the subsystem
- Partial completion causes data corruption or silent incorrect behavior
- The extra type has a clear name that communicates its own purpose

**Prefer annotation when:**
- Constraint is obvious from domain context (render loop ordering, for example)
- The extra type adds API surface without adding clarity
- Two types would confuse the caller more than a comment would mislead them

The tradeoff is real: two types = more API surface to hold in mind. One type + comment = simpler API but invisible constraint. Neither is strictly better. The architecture agent should evaluate per constraint, not apply a blanket rule.

## Why This Works

The failure mode is local optimization degrading global structure. Signature docs make global structure explicit before implementation begins — the agent cannot silently defer what is already specified. Dead code and omissions are mechanically detectable. Cross-subsystem visibility catches duplication that per-file agents miss. Narrow interface design in the signature doc directly targets over-complicated inter-object communication.

## Considered Failure Modes

Objections examined during design, with resolution:

**"LSP gives structure not intent — architectural constraints are semantic."**
Resolved. Good code encodes intent through naming and structure. LSP structural data is meaningful precisely because naming is meaningful. Additionally, docs are the input spec, not derived from code — intent flows doc → code, not code → doc.

**"Ideal docs go stale immediately."**
Resolved. Docs are source of truth; code is generated from them. Drift is a deviation to adjudicate, not an expected state. Agent updates docs only when deviation is justified by PM spec — not on every change.

**"Swift extension fragmentation makes LSP reconstruction hard."**
Mitigated. Agent reads file chunks that include extensions alongside primary declaration. `documentSymbol` sweeps all files for a type. Doc consolidates the full shape explicitly.

**"Complexity metrics are poor proxies."**
Not applicable. System uses structural presence/absence and reference counts, not complexity metrics. False positives from LSP checks are signals routed to implementation agent for feedback — not hard failures.

**"Conflict resolution lands on you."**
Resolved. Implementation agent provides justification. Architecture agent adjudicates against explicit criteria. Human only involved when criteria are genuinely ambiguous, not for routine deviations.

**"More data doesn't fix the reasoning gap — agents forget why."**
Resolved. PM specs carry the why/what. Architecture agent's job is how (shape). The docs are the memory — agent reconstructs full context from docs + LSP at session start without relying on conversation history.

**"Circular authority — agent updates docs based on implementation, so implementation shapes architecture."**
Open risk. Mitigated by hard adjudication criteria (dead code, missing spec features, dependency violations are never justified). Agent must tie doc updates to PM spec requirements, not implementation convenience. Requires discipline in prompt design.

**"Doc format too precise = basically code. Too vague = ambiguous generation."**
Resolved. Abstraction level is: signatures without bodies. Precisely what Swift would show in a generated interface view. Unambiguous to generate from, meaningfully above implementation detail.

**"Orchestration — who triggers this agent, when."**
Open. Trigger on completion of implementation agent per subsystem. Lifecycle: design phase → implementation phase → verification phase per feature. Docs persist across sessions as the architecture agent's working memory.

**"Won't work — structural failures aren't the real problem."**
Empirically refuted. Observed in C++ → Swift rewrite: agents skipped features, created dead types, over-complicated wiring, got body logic right while structural completeness failed. Structural failure is the primary failure mode, not body-level bugs.

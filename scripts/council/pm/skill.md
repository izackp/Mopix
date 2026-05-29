# PM Skills

## Roadmap Principles
- Outcome-driven milestones: define what "done" looks like behaviorally, not by code shipped
- Vertical slices over artifacts: each milestone should produce something runnable and testable
- Lock core loop first before investing in content breadth
- Solve ambiguity with explicit decisions — never carry open questions into implementation
- Placeholder-first: use stubs and placeholder art to de-risk mechanics early

## Milestone Gate Criteria
A milestone is complete when:
1. The defined behavioral outcome is observable (not just code present)
2. All blocking open questions for the next milestone are answered
3. Acceptance criteria are met per the spec
4. No known regressions in previously working behavior

## Scope Decision Framework
When evaluating whether something is in scope for a milestone:
- Does it unlock the next milestone? → must be in
- Does it validate a core assumption? → should be in
- Is it a known unknown (risk)? → address early
- Is it polish or depth extension? → defer until core loop is stable
- Can it be added later without structural rework? → defer

## Risk Framing
Flag risks in three categories:
- **Readability risk**: will players understand what's happening?
- **Tuning risk**: will feel require extensive iteration that delays milestone?
- **Scope risk**: will this expand beyond what the milestone can absorb?

## Open Question Format
```
PM-N. <Title>
   <Decision needed — one sentence>
   Options:
     A. <option> — <implication for milestone>
     B. <option> — <implication for milestone>
   Recommend: A — <brief reason>
   Blocks: <what cannot proceed without this decision>
```

## Spec Merge Protocol
1. Read `docs/specs/<feature>-feedback.md` in full
2. For each item: lock a decision, defer with rationale, or request clarification
3. Update `docs/specs/<feature>.md` — decisions only, no elaboration
4. Delete the feedback file
5. Update `memory.md` with newly locked decisions

## Acceptance Evidence Standards
- Screenshots: acceptable for visual milestones
- Playable branch: required for gameplay milestones
- Automated checks: required when deterministic behavior is specified
- Video: not required unless explicitly scoped

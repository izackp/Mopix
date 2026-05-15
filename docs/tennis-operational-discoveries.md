# Tennis Operational Discoveries

This file captures implementation and planning discoveries made while building the tennis game.
It is not a product spec. It is a running record of what the team learned operationally so later
planning does not repeat the same mistakes.

## 2026-05-15

### Milestone Spec Risk: Disposable Work

While implementing Milestone 1 (`Playable Court Shell`), a planning concern became clear:

- a milestone spec that only defines a temporary visible artifact can push the team into building
  a shell that later milestones replace instead of extend
- that creates redundant work, especially when runtime structure, rendering approach, and scene
  ownership are still unsettled

The specific risk for tennis is:

- `M1` says "launch a tennis game and show a static court"
- a worker can satisfy that by building a minimal one-off runtime
- later milestones may still need to redesign boot flow, game state ownership, court modeling,
  and rendering integration for the actual playable MVP
- if that happens, `M1` was a proof artifact rather than the first slice of the real product

### Operational Guidance

Use this rule when defining future tennis milestones:

- if the milestone output is likely to be deleted later, the milestone boundary is probably wrong
- if the milestone output is incomplete but later milestones clearly extend it, the boundary is
  probably healthy

For tennis, the better planning sequence is likely:

1. define the finalized MVP runtime and gameplay architecture first
2. lock the durable decisions that later milestones should build on
3. derive milestone specs as thin vertical slices of that final model

### Durable Decisions Future Specs Should Clarify Earlier

Future top-level tennis specs should define, before milestone slicing:

- what object or module owns tennis game state
- how court geometry is represented
- how player, opponent, and ball entities are modeled
- how tennis launches as a distinct game within the engine
- what rendering path later milestones are expected to keep using

### Current Implementation Note

The current tennis M1 runtime is still useful as a proof that the project can expose a separate
`Tennis` executable and render a readable `160x144` static court shell.

But this discovery should shape the next planning pass:

- treat milestone-only visual shells with caution
- prefer milestones that establish reusable game structure, not just acceptance-demo output

# Tennis Open Questions

This file captures open product and spec questions that should be answered before the tennis
specs are expanded further.

It intentionally excludes lower-level implementation-detail questions about code structure,
class layout, or engine ownership boundaries. The goal here is to clarify product behavior,
game rules, feel, acceptance, and milestone-defining decisions.

## 1. MVP Product Rules

These choices affect nearly every later spec and should be locked early.

- What is the scoring model for the first playable version?
  Options might include `11-point arcade`, simplified tennis scoring, or full tennis scoring.
- Is a serve required to begin every point, or should some points auto-start after reset?
- What exactly ends a point?
  Examples: second bounce, ball out, ball into net, unreachable ball, or another rule.
- Should the ball be modeled with visible height / arcade-style depth, or should the MVP keep a
  flatter 2D legality-first model with simpler cues?
- What is the intended match length for MVP?
- Should the MVP feel closer to an arcade tennis game or a lightweight realism game?

## 2. Simulation Model

The roadmap points toward explicit tennis-specific simulation, but the product-level behavior is
not yet fully defined.

- What are the minimum ball behaviors required for MVP?
  Examples: travel, bounce, net interaction, out-of-bounds, landing side legality.
- How should in/out legality be judged?
- What kinds of bounce behavior matter for MVP readability and feel?
- Should all shots be parameter variations on one shared ball model, or should certain shots
  behave as meaningfully different rule types?
- Does the MVP need deterministic or replay-stable behavior for debugging and testing?

## 3. Controls and Feel

These decisions strongly shape whether later specs describe one coherent game or several possible
games.

- Is movement 4-directional or 8-directional?
- What is the exact shot input model?
  Examples: `A`, `B`, `A+B`, hold-to-charge, timing windows, directional modifiers.
- Is charge required for MVP, optional for MVP, or out of scope until later?
- How strict should player positioning be for successful returns?
- How much auto-aim or aim assist is acceptable?
- Is dash part of MVP, explicitly deferred, or still undecided?

## 4. AI and Opponent Expectations

The roadmap includes a CPU opponent, but the acceptance standard is still fuzzy.

- Is the MVP opponent supposed to be primarily functional, fair, challenging, or just rally-safe?
- Can the AI use hidden assistance such as perfect landing prediction or movement cheats?
- Should the AI use the same shot vocabulary as the player?
- What is the minimum acceptable rally consistency for MVP?
- Does MVP need difficulty levels, or is one baseline opponent enough?

## 5. Acceptance and Testing

The current docs describe outcomes, but they can be sharper about how completion is judged.

- What manual test scenarios must exist for each milestone?
- What debug visualizations are acceptable or required during development?
- What evidence is required to accept a milestone?
  Examples: screenshot, video, playable branch, checklist, headless capture.
- Which milestones should include deterministic or automated verification?
- What engine or production constraints should milestone specs explicitly call out?

## 6. Milestone Slicing

These questions help prevent milestones from turning into throwaway demo artifacts.

- What is the finalized MVP we are actually trying to reach?
- Which milestone outputs should be durable foundations rather than temporary proofs?
- What should Milestone 1 establish that later milestones must extend rather than replace?
- Where should the boundary sit between "prove the concept" and "build the real runtime"?
- Which open decisions must be locked before additional milestone specs are written?

# Tennis Milestone 1 Specification

This document defines the required product outcome for Roadmap Milestone 1: `Playable Court Shell`.

It is a requirements document, not an implementation plan. It describes what workers must
deliver, what is in scope, what is out of scope, and how acceptance will be judged. It does
not prescribe file structure, class names, rendering internals, or engine-specific tactics.

## Planning Caution

This milestone is intentionally scoped to visible launch-state output. That makes it useful for
proving readability and executable setup, but it also creates a risk of one-off implementation
work if later milestones replace rather than extend the runtime structure created here.

See [tennis-operational-discoveries.md](./tennis-operational-discoveries.md) for the operating
lesson: future milestone specs should increasingly prefer durable slices of the final tennis
runtime over temporary acceptance-demo artifacts.

## 1. Goal

Milestone 1 proves that the project can host a tennis game as a distinct playable runtime and
display a complete static tennis playfield at the intended MVP resolution.

This milestone is complete when a user can launch the tennis game and immediately see a clear,
stable, full-court shell with player and ball placeholders.

## 2. In Scope

Milestone 1 includes:

- a launchable tennis game entry in the project
- a visible static tennis court
- two visible player placeholders
- one visible ball placeholder
- a stable rendered scene that remains visible frame to frame

## 3. Out of Scope

Milestone 1 does not include:

- player input
- movement
- serving
- rally logic
- ball physics
- collisions
- scoring
- menus
- HUD
- audio
- AI opponent behavior
- surface-specific gameplay tuning
- production art

Workers should not add out-of-scope behavior, even if it appears easy.

## 4. Locked Product Decisions

These decisions are fixed for Milestone 1.

### 4.1 View Style

- The view must be top-down and non-scrolling.
- The entire singles court must be visible at once.
- No camera motion, zoom, or perspective behavior is required.

### 4.2 Logical Resolution

- The milestone must target a logical play area of `160x144`.
- The court composition must be legible at that resolution.

### 4.3 Visual Style

- The scene may use simple placeholder shapes rather than production art.
- Readability matters more than realism.
- The scene must clearly communicate court boundaries, net placement, player positions, and
  ball position.

## 5. Required Scene Composition

The launch state must show a full static court shell composed of the following visible elements:

- a background distinct from the court
- a bounded singles court
- a visible net dividing the upper and lower halves
- visible service lines
- visible center service line
- visible center marks on both baselines
- one player placeholder on the lower half of the court
- one player placeholder on the upper half of the court
- one ball placeholder positioned at mid-court near the net line

## 6. Court Layout Requirements

The following layout is required within the `160x144` play area.

### 6.1 Outer Court

- The court must occupy the center of the screen.
- The outer boundary must leave a visible margin around the full court.
- The full court, including top and bottom baselines, must be visible at once.

### 6.2 Net Placement

- The net must divide the court horizontally into upper and lower halves.
- It must be visually distinct from court lines.

### 6.3 Service Box Layout

- The court must include upper and lower service lines.
- The court must include one vertical center service line connecting the two service lines.

### 6.4 Baseline Center Marks

- Both baselines must show a visible center mark.

## 7. Placeholder Requirements

### 7.1 Player Placeholders

- Two player placeholders are required.
- The lower player placeholder must appear near the bottom half baseline area.
- The upper player placeholder must appear near the top half baseline area.
- The two player placeholders must be visually distinct from each other.

### 7.2 Ball Placeholder

- One ball placeholder is required.
- It must be visibly smaller than the player placeholders.
- It must be visible against the court and net.

## 8. Readability Requirements

Milestone 1 is not accepted unless the scene is readable at the target logical resolution.

At minimum, a reviewer must be able to identify all of the following without explanation:

- where the court begins and ends
- where the net is
- which placeholder represents the lower player
- which placeholder represents the upper player
- where the ball is

## 9. Launch-State Requirements

When the tennis game launches:

- it must open directly into the static court shell
- the scene must appear without requiring user input
- the scene must remain visible and stable
- no missing-art or missing-resource state should block the scene from appearing

## 10. Acceptance Criteria

Milestone 1 is accepted only if all of the following are true:

1. The project exposes a launchable tennis game.
2. Launching the tennis game presents a full static court shell immediately.
3. The entire court is visible at once within the `160x144` logical view.
4. The net, service lines, and baseline center marks are all visibly present.
5. Two player placeholders and one ball placeholder are visibly present.
6. The scene is readable without relying on production art.
7. The milestone ships with no gameplay systems beyond static presentation.

## 11. Non-Goals

This milestone is not intended to answer:

- how movement should feel
- how serves work
- how the ball should bounce
- how players aim shots
- how scoring is displayed

Those belong to later milestones.

## 12. Handoff to Milestone 2

Milestone 1 should leave the project ready for Milestone 2, where workers will build:

- player movement
- serve state
- ball state
- point reset behavior
- basic court-legal gameplay state transitions

Milestone 2 should assume the launchable static shell already exists and should not revisit
Milestone 1 scope unless readability issues are discovered.

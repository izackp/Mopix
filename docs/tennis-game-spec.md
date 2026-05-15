# Tennis Game Specification — MVP

This document defines the first playable tennis game to ship alongside `SpaceInvaders`.
It covers product scope, gameplay rules, technical constraints, and an implementation plan
that fits the current `GameEngine` package structure.

---

## Goal

Build a second executable game target, `Tennis`, using the existing engine primitives and
the same general app structure as `SpaceInvaders`.

The MVP should feel like an arcade tennis game inspired by handheld-era design:

- fixed overhead/isometric-style court view
- immediate 8-direction movement
- readable shot timing and placement
- distinct court surfaces that materially change rally behavior
- one complete singles match loop that is playable end-to-end

The MVP does not need tournaments, character progression, unlockables, or a full roster.

---

## Product Scope

### In Scope For MVP

- one playable singles match: player vs CPU
- one court rendered at a logical resolution of `160x144`
- 2D sprite/tile presentation with GBC-inspired color choices
- player movement in 8 directions
- serve, rally, scoring, and win condition
- core shot system built around `A`, `B`, and timing/combination input
- ball physics that vary by selected court surface
- basic CPU opponent behavior
- lightweight HUD: score, server, and shot charge feedback

### Out Of Scope For MVP

- doubles
- online play or rollback
- career mode / progression / unlock flow
- roster stat growth or stat decay over time
- full character select
- multiple camera modes
- advanced animation blending
- audio polish beyond placeholder support

---

## Design Pillars

### 1. Readability At Low Resolution

The player must always be able to read:

- where the ball is
- where it will bounce
- what shot was just executed
- whether they are in position to return it

This matters more than realism.

### 2. Shot Expression From Simple Inputs

The shot system should preserve the research direction:

- `A` favors aggressive topspin
- `B` favors defensive slice
- combinations and timing create special shots

The move set should be deep enough to create tactical variety without adding more buttons.

### 3. Surface-Driven Variety

Court selection should noticeably alter rally tempo and bounce so the same controls support
different playstyles.

### 4. Deterministic-Friendly Rules

Gameplay simulation should stay simple and state-driven so the project can later experiment
with replay, serialization, or rollback-friendly behavior.

---

## Visual Specification

### Camera And Resolution

- logical playfield resolution: `160x144`
- fixed top-down / light isometric overhead camera
- no camera scrolling during play
- final window may scale this up, but game logic and art target `160x144`

### Court Layout

The entire singles court, net, service boxes, and baselines should remain visible at all
times. Play space should include a small runoff area so characters can chase lobs near the
back and sides.

### Art Direction

- 2D pixel art
- strong silhouette readability for players and ball
- bright handheld-inspired palette
- exaggerated shot trails for feedback

### Required Visual Cues

- red streak: topspin
- blue streak: slice
- purple streak: smash
- visible shadow or landing marker for airborne balls
- obvious net line and court boundaries

---

## Core Match Loop

1. A point begins with a serve.
2. Ball enters rally state after a legal serve.
3. Players exchange shots until a fault or winner occurs.
4. Score updates.
5. Serve alternates according to the selected scoring rules.
6. Match ends when a player wins the configured number of games or points.

### MVP Scoring Decision

Use a simplified arcade scoring model for the first playable:

- points only, no deuce/advantage
- first to `11` points wins
- must win by `2`
- server alternates every `2` points

This is intentionally simpler than full tennis. It reduces UI complexity and lets the team
validate movement, shots, and AI before implementing traditional tennis scoring.

---

## Controls

### Movement

- D-pad / arrow input in 8 directions
- movement is always available while the player is not in a hit-stop or serve-lock state

### Shot Inputs

The control model follows the research summary and should support seven shot outcomes.

| Input | Shot | MVP Status |
| --- | --- | --- |
| `A` | Topspin | required |
| `B` | Slice | required |
| `A+B` | Flat shot or Smash depending on context | required |
| `A -> B` | Lob | required |
| `B -> A` | Drop shot | required |
| hold before impact | charge for more power/spin | required |
| double tap same shot button | bonus power | optional |

### Context Rule For `A+B`

The research conflicts slightly by listing both flat shot and smash around `A+B`.
For MVP, resolve that ambiguity with a context rule:

- `A+B` while the ball is above shoulder-height and the player is in strong position:
  `Smash`
- otherwise `A+B` produces a `Flat Shot`

This keeps both shot types without adding controls.

---

## Player Model

Each player has four gameplay stats:

- `power`
- `speed`
- `control`
- `spin`

### MVP Usage

These stats affect play immediately:

- `power`: outgoing shot speed, serve speed, smash strength
- `speed`: run speed, acceleration, recovery, dash distance
- `control`: aim cone tightness and target precision
- `spin`: topspin arc/bounce multiplier and slice skid multiplier

### MVP Roster Decision

The first playable should ship with only two stat presets:

- `Balanced`
- `Power`

The player can use `Balanced`; CPU can use either preset for testing. Full roster design can
wait until after the core loop feels good.

### Deferred Progression

The research mentions stat growth and stat neglect decay. That system is out of scope for MVP.
Stats are fixed per character preset for now.

---

## Ball Simulation

The ball simulation is the core of the game and should remain explicit rather than overly
physical. Use a gameplay-first model with tunable values.

### Ball State

At minimum, the ball should track:

- court position `x/y`
- height `z`
- horizontal velocity
- vertical velocity
- owning side / last hitter
- current spin type
- projected landing point
- bounce count for current point

### Rally Rules

- one bounce on your side is legal
- two bounces loses the point
- ball contacting the net on a normal return loses the point
- ball landing outside the singles boundary loses the point

### Serve Rules For MVP

Keep serves intentionally simple:

- serve always starts from a fixed baseline position
- no foot faults
- no second serve
- serve must land in the opposite service box
- illegal serve immediately awards the point to the receiver

Second serves can be added later if the game benefits from more realism.

---

## Shot Definitions

### Topspin

- input: `A`
- purpose: primary attacking rally shot
- behavior: fast forward speed, higher arc than flat, high bounce
- feedback: red trail

### Slice

- input: `B`
- purpose: safer or more defensive shot
- behavior: lower arc, lower bounce, reduced post-bounce speed loss, wider lateral variation
- feedback: blue trail

### Flat Shot

- input: `A+B` outside smash context
- purpose: direct fast shot with less spin influence
- behavior: fastest grounded rally shot, medium bounce, lower safety margin

### Lob

- input: `A -> B`
- purpose: send the ball deep over an advanced opponent
- behavior: high arc, long hang time, deep target bias

### Drop Shot

- input: `B -> A`
- purpose: punish deep positioning
- behavior: weak forward speed, short travel, very low second bounce distance

### Smash

- input: `A+B` in overhead context
- purpose: high-reward put-away shot
- behavior: very high power, steep downward angle, difficult for CPU/player to return
- feedback: purple trail

### Charge Modifier

- holding a valid shot input before impact increases:
  - shot speed
  - spin strength
  - target commitment

Charge must have a cap so it remains readable and balanced.

---

## Positioning And Hit Timing

The game should not require exact simulation-grade contact points, but it should reward good
positioning.

### Return Window

When the ball enters a hittable radius around a player, the player may return it if:

- they are on the correct side of the net
- they are not in recovery lockout
- the ball height is valid for the selected shot

### Contact Quality

Use three timing bands:

- `Perfect`: best speed/placement
- `Good`: standard return
- `Late/Early`: weaker or less accurate return

This gives depth without demanding complicated inputs.

### Smash Eligibility

A smash should only be available when:

- the ball height is above a defined overhead threshold
- the player is within a tighter positioning radius than a normal return

If the player presses `A+B` outside this window, the game falls back to `Flat Shot`.

---

## Dash

The research notes a dash mechanic tied to speed. MVP should include a simple version:

- flicking the same direction twice within a short window triggers a dash burst
- dash grants a short acceleration spike, not invulnerability
- dash has a brief recovery so it cannot replace all movement

If implementation cost becomes too high, dash may be cut from first playable and restored
immediately after the core rally loop is stable.

---

## Court Surfaces

Court surfaces change ball speed and bounce after contact.

### Surface Data

| Surface | Ball Speed | Bounce | MVP Availability |
| --- | --- | --- | --- |
| Hard Court | Normal | High | required |
| Clay Court | Slow | Low | required |
| Grass Court | Fast | Low | required |
| Composition Court | Maximum | Normal | optional |
| Castle Court | Normal | Normal | optional |
| Jungle Court | Fast | Maximum | optional |
| Tropics Court | Maximum | Low | optional |

### MVP Surface Decision

Ship the first playable with three surfaces:

- `Hard Court`
- `Clay Court`
- `Grass Court`

These give clear contrast with limited tuning overhead. The remaining surfaces can be data-only
extensions once the simulation feels correct.

---

## AI Opponent

The first CPU should be intentionally simple but reliable.

### Required AI Behaviors

- move toward predicted landing point
- choose a legal return when in range
- prefer topspin as default rally shot
- use lob when player is near the net
- use drop shot occasionally when player is deep
- attempt smash on obvious overhead opportunities

### AI Non-Goals For MVP

- personality profiles
- bluffing / fakeouts
- advanced pattern adaptation

---

## UI / HUD

The HUD should remain minimal due to the low native resolution.

### Required HUD Elements

- player score
- CPU score
- serving side indicator
- current surface name on pre-match screen
- shot charge indicator near active player or HUD edge

### Menus

MVP only needs:

- title screen
- surface select
- match screen
- win / lose result screen

---

## Audio

Audio is not a blocker for the first playable, but the design should reserve hooks for:

- serve hit
- racket hit by shot type
- bounce by surface
- net contact
- score stinger

Placeholder sounds are acceptable.

---

## Technical Specification

### New Package Structure

Add a new executable target modeled after `SpaceInvaders`:

- `Sources/Tennis/main.swift`
- `Sources/Tennis/TestGameApp.swift`
- `Sources/Tennis/TennisWindow.swift`
- `Sources/Tennis/Game/TennisScene.swift`
- `Sources/Tennis/Game/Player.swift`
- `Sources/Tennis/Game/Ball.swift`
- `Sources/Tennis/Game/OpponentAI.swift`
- `Sources/Tennis/ExternalFiles/...`

### Engine Reuse Expectations

The game should reuse existing engine systems where practical:

- `Application`
- `FullWindow`
- `RendererClient`
- input command translation
- resource loading through `VirtualDrive`

### Simulation Model

Run gameplay on a fixed tick. Rendering can interpolate visually, but match state should be
updated from deterministic fixed-step rules.

### Collision Approach

Do not start with general-purpose physics. Use explicit tennis-specific checks:

- player hit radius
- court bounds
- service box bounds
- net plane
- bounce state transitions

This is simpler and better suited to deterministic tuning.

---

## Open Decisions

These should be resolved before implementation starts in earnest:

1. Whether the first playable uses `11-point` arcade scoring or traditional tennis scoring.
2. Whether dash ships in v1 or immediately after first playable.
3. Whether the native logical area remains exactly `160x144` or uses a slightly larger logic
   canvas with a `160x144` presentation crop.
4. Whether art uses dedicated tennis sprites or temporary placeholder blocks/circles first.

---

## Recommended Implementation Order

1. Create `Tennis` executable target and boot a blank scene at the correct logical size.
2. Render a static court with boundaries, net, and player placeholders.
3. Implement player movement and serve state.
4. Implement ball flight, bounce, out-of-bounds, and net rules.
5. Implement topspin, slice, flat shot, lob, drop shot, and smash context logic.
6. Add simplified score handling and point reset.
7. Add basic CPU movement and return logic.
8. Add surface tuning data for hard, clay, and grass.
9. Add HUD and menu flow.
10. Replace placeholders with production art and sound.

---

## Acceptance Criteria For First Playable

The tennis MVP is ready when:

- the package builds with a `Tennis` executable target
- a player can start a match from a menu
- the player can move and serve
- the CPU can return shots and sustain a rally
- all required shot types are usable
- hard, clay, and grass courts feel meaningfully different
- points score correctly and the match can be won or lost
- the game is readable when rendered from the `160x144` logical resolution

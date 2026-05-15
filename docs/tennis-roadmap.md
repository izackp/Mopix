# Tennis Roadmap

This roadmap translates the tennis MVP spec into an execution plan for the `GameEngine`
repo. It is intentionally outcome-driven: the goal is not to ship a long feature list, but
to get from "no tennis game" to "playable, readable, and extensible tennis loop" with clear
stages and decision gates.

## Planning Note

See [tennis-operational-discoveries.md](./tennis-operational-discoveries.md) for implementation
lessons learned while executing this roadmap. In particular, use caution when defining
milestones that can be satisfied by temporary visible shells but do not yet lock durable tennis
runtime structure.

## Strategy Context

### Business Goals / Project Goals

- prove the engine can support more than one game genre alongside `SpaceInvaders`
- validate a second executable target with reusable engine patterns instead of one-off code
- ship a first playable tennis game that is immediately understandable and fun at low
  resolution
- create a foundation that can later support richer rules, more content, and engine-level
  learning

### Player / Product Outcomes

- players can understand the game within one session without needing a tutorial
- rallies are readable and satisfying at `160x144`
- different shot choices and court surfaces produce meaningful tactical variety
- the game reaches a stable first playable state quickly enough to inform future engine work

### Constraints / Dependencies

- current codebase only has `SpaceInvaders` as a game-specific executable reference
- low logical resolution means readability is a hard requirement, not a polish concern
- tennis physics and hit timing should stay explicit and gameplay-driven rather than depend on
  generic physics
- the spec still contains open decisions around scoring, dash, logical canvas, and art-first
  vs placeholder-first implementation

## Roadmap Principles

- prioritize first playable speed over completeness
- prefer vertical slices of the final runtime over disposable milestone-only artifacts
- lock the core rally loop before investing in content breadth
- solve ambiguity with explicit product decisions instead of carrying it forward in code
- use placeholder art when needed to de-risk mechanics early
- add polish only after shot feel, AI reliability, and match flow are working

## Roadmap (Now / Next / Later)

| Stage | Initiative | Outcome | Metric | Notes |
|---|---|---|---|---|
| Now | Target scaffolding and rendering foundation | `Tennis` executable boots and renders a playable court space | `Tennis` target builds and launches; static court visible at logical `160x144` | Mirror `SpaceInvaders` app structure and prove asset/resource pathing early |
| Now | Core movement and serve flow | Player can move, serve, and restart points reliably | Player can move in 8 directions; legal/illegal serve outcomes complete without crashes | Keep serve rules simplified for MVP |
| Now | Ball simulation and rally legality | Game supports bounce, out, net, and point resolution | Rally rules pass manual play checks for bounce/out/net on all sides | This is the core simulation milestone |
| Now | Shot system MVP | All required shots exist and feel distinct enough to test | Topspin, slice, flat, lob, drop shot, and smash are all executable in match play | Resolve `A+B` context rule in implementation |
| Next | CPU opponent and stable match loop | Full player-vs-CPU singles match is playable end-to-end | CPU returns legal balls consistently enough to sustain rallies; match can be won/lost | Reliability matters more than difficulty tuning at this stage |
| Next | Surface differentiation | Hard, clay, and grass meaningfully change rally tempo and bounce | Testers can correctly identify the selected surface from play behavior alone | Prefer data-driven tuning tables |
| Next | HUD and front-end match flow | Title -> surface select -> match -> result loop is complete | Player can start, finish, and restart a match without developer intervention | Keep UI minimal and readable |
| Later | Feel and presentation polish | Tennis becomes satisfying, not just functional | Shot trails, bounce markers, audio cues, and sprite readability reach acceptance level | Only after core loop is stable |
| Later | Depth extensions | Game grows beyond MVP without destabilizing the base loop | Optional features adopted behind clear gates | Candidates: dash, more surfaces, traditional scoring, roster presets |

## Sequencing

### Milestone 1: Playable Court Shell

- add `Tennis` executable target to `Package.swift`
- create `Sources/Tennis/...` structure modeled after `SpaceInvaders`
- boot application and render a static court, net, and placeholder player markers
- decide whether to use exact `160x144` logic or a slightly larger internal play area with
  crop/presentation rules

### Milestone 2: Core Rally Simulation

- implement player movement in 8 directions
- implement serve state, legal service box rules, and point reset
- implement ball state, bounce logic, net collision, out-of-bounds, and score events
- add debug-friendly visualizations for landing point and ball height if needed

### Milestone 3: Shot Depth

- implement topspin, slice, flat shot, lob, drop shot, and smash
- add timing quality bands: perfect, good, late/early
- implement charge behavior with a clear cap
- tune hit windows and positioning rules for readability over realism

### Milestone 4: Matchability

- implement CPU prediction and legal return behavior
- implement simplified scoring model and server rotation
- complete point-to-point match progression
- verify rallies are stable enough for repeated manual play

### Milestone 5: Differentiation And UX

- add hard, clay, and grass surface data
- tune surface speed and bounce so they are obviously different
- build title, surface select, HUD, and result screens
- add placeholder or production audio hooks

### Milestone 6: Polish / Expansion Gate

- review whether first playable is fun and readable enough to justify polish
- decide whether to add dash before or after public/internal demo
- decide whether to keep arcade scoring or move toward traditional tennis scoring
- decide whether to invest next in content breadth or engine abstractions learned from tennis

## Initiative Breakdown

### Initiative 1: Tennis Runtime Foundation

- problem: there is no tennis executable or runtime path in the repo
- hypothesis: if we scaffold the tennis target using the same app/window/scene pattern as
  `SpaceInvaders`, we will reduce startup risk and focus faster on gameplay problems
- success metric: executable boots with mounted resources and visible court
- effort: small

### Initiative 2: Rally Simulation

- problem: without a dependable ball model and court legality rules, no other tennis mechanic
  can be meaningfully tested
- hypothesis: if we build an explicit tennis-specific simulation instead of generic physics,
  we will tune gameplay faster and keep the system deterministic-friendly
- success metric: legal vs illegal point outcomes behave consistently under manual testing
- effort: medium

### Initiative 3: Shot Expression

- problem: the game will feel shallow unless the `A`/`B`-driven input model produces clearly
  different tactical outcomes
- hypothesis: if each shot has strong trajectory, bounce, and feedback differences, players
  will understand and use the move set without extra buttons
- success metric: testers can intentionally choose and recognize each shot type
- effort: medium

### Initiative 4: CPU Match Loop

- problem: a tennis game is not meaningfully playable as a product until rallies and scoring
  work against an opponent
- hypothesis: if the CPU can reliably move to predicted landing points and prefer legal,
  readable returns, the MVP will be playable before advanced AI exists
- success metric: player can complete full matches against CPU without dead states
- effort: medium

### Initiative 5: Surface And UX Differentiation

- problem: without surface variation and basic front-end flow, the tennis game will not yet
  demonstrate the intended product identity
- hypothesis: if three surfaces and minimal menus/HUD are added after core gameplay stabilizes,
  the game will feel like a coherent product instead of a mechanics testbed
- success metric: player can choose a surface, play a match, and feel a material gameplay
  difference between courts
- effort: medium

## Suggested Release Framing

### Release 0: Internal Prototype

- target boots
- court renders
- player moves
- ball can be served and bounced

Exit criteria:

- no blocking architectural unknowns remain
- the team agrees the control/camera direction is viable

### Release 1: First Playable

- full rally rules
- all core shot types
- CPU opponent
- simplified scoring
- hard/clay/grass surfaces
- minimal HUD and menus

Exit criteria:

- complete matches are playable end-to-end
- shot choices feel distinct
- surfaces feel distinct
- game reads clearly at target resolution

### Release 2: Vertical Slice Polish

- improved sprites and court art
- shot trails and bounce feedback polish
- audio pass
- difficulty tuning
- optional dash decision

Exit criteria:

- game is suitable for demoing as a credible companion title to `SpaceInvaders`

## Key Decisions To Make Early

1. Keep simplified `11-point`, win-by-2 scoring for first playable unless there is a strong
   reason to model tennis scoring sooner.
2. Start with placeholder art for Milestones 1-4, then replace it after the core loop is
   stable.
3. Treat dash as a post-first-playable feature unless movement feel is clearly insufficient
   without it.
4. Use data tables for surface and shot tuning from the start so feel changes do not require
   logic rewrites.

## Risks & Dependencies

- readability risk: the ball, shadow, and landing feedback may be too hard to parse at
  `160x144` without strong exaggeration
- tuning risk: too much realism will make the game feel muddy, while too little variation will
  make all shots feel the same
- AI risk: weak prediction or return logic could make the game appear broken even if the player
  mechanics are sound
- scope risk: adding progression, full roster systems, or many courts before first playable
  would likely delay validation of the core loop
- dependency: `Package.swift` must be extended cleanly for a new executable target
- dependency: resource loading and window setup should reuse stable `SpaceInvaders` patterns

## Recommended Next Actions

1. Accept this roadmap as the default implementation sequence.
2. Lock the four open spec decisions that affect early implementation.
3. Scaffold the `Tennis` target and Milestone 1 files.
4. Treat Milestone 2 completion as the first major go/no-go checkpoint.

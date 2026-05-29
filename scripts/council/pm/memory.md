# PM Memory

## Current Project
**Mopixs** — 2D Swift game engine on SDL2. Active feature: Tennis game (`Sources/Tennis/`).

## Current Milestone
**M1 complete.** Tennis target scaffolding and runtime foundation shipped.
Next: M2 — Core Rally Simulation (movement, serve, ball physics, legality, score events).

## Locked Decisions
- Scoring model: 11-point arcade, win-by-2
- Art approach: placeholder-first through M4; replace after core loop stable
- Dash: deferred — post-first-playable
- Shot tuning: data-driven tables from the start (surfaces + shots)
- Simulation: explicit tennis-specific physics, not generic engine physics
- Logical canvas: 160×144 resolution is the target

## Open Questions
- PM-1. Match restart after matchEnd — undecided (options: auto-restart, return to menu, hold result screen)
- PM-2. Surface selection for MVP — hardcoded Hard Court or surface select screen?
- PM-3. Local 2P — out of scope for Release 1, confirm for Release 2
- PM-4. Milestone acceptance — screenshots acceptable; video not in scope
- PM-5. First playable target date — unknown; M3 (shot system) is critical path
- PM-6. Player stat preset — always Balanced vs Power or character select screen?
- PM-7. Score display — system font via TTF acceptable or pixel art sprites needed?
- PM-8. Audio — placeholder silence acceptable through all milestones or M4 needs one sound?

## Roadmap Summary
| Stage | Milestone | Status |
|---|---|---|
| Now | M1: Court Shell | Done |
| Now | M2: Core Rally Simulation | In progress |
| Now | M3: Shot Depth | Not started |
| Now | M4: Matchability (CPU + scoring) | Not started |
| Next | M5: Differentiation + UX | Not started |
| Later | M6: Polish / Expansion Gate | Not started |

## Release Targets
- Release 0 (Internal Prototype): M1 + M2
- Release 1 (First Playable): M3 + M4 + M5
- Release 2 (Vertical Slice Polish): M6 + art + audio pass

## Spec File Structure
Specs grouped by scene, domain files within:
```
docs/specs/tennis/
  match-rules.md      # scoring, serve, point lifecycle, match end
  simulation.md       # ball model, bounce, legality
  shot-system.md      # input, shot types, timing quality
  players.md          # movement, HumanController, AI
  presentation.md     # HUD, surfaces, audio hooks
docs/specs/menu/      # future
docs/specs/shared/    # cross-scene systems
```
None created yet — open questions must be resolved first.
Feedback files: `docs/specs/tennis/<domain>-feedback.md` (scratch, PM deletes after merge).

## Reference Docs
- `docs/tennis-game-spec.md`, `docs/tennis-roadmap.md`, `docs/tennis-open-questions.md`

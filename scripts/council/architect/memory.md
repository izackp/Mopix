# Architect Memory

## Current Project
**Mopixs** — 2D Swift game engine on SDL2. Active feature: Tennis game.
Repo: `/Users/isaacpaul/Projects/swift-projects/GameEngine`
Branch: `tennis`

## Architecture State
- M1 runtime shipped: `TennisApp`, `TennisScene`, `TennisPlayer`, `HumanController`, `Ball`, `MatchScore`, `CourtLayout` scaffolded
- Signature docs: not yet created in `docs/arch/` — to be written for M2

## Open Technical Issues (ARCH-N)
- ARCH-1. Ball.step() bounce detection imprecise — z + vz can overshoot below ground; clamp needed same tick
- ARCH-2. Direction normalization in Ball.applyHit() unspecified — recommend pre-defined target positions (Option C from feedback doc) — removes normalization entirely, determinism-friendly
- ARCH-3. tryHit() should be mutating — currently pure query; clearPendingAndStartHitstop() must always follow; merge them
- ARCH-4. HumanController receives opponentPos every tick — only needed for auto-aim at shot commit; pass only then
- ARCH-5. CPU .serveInFlight phase — receiver movement undefined; needs explicit branch in HumanController.tick()
- ARCH-6. OpponentAI drop shot tick%5 pattern — learnable; use Knuth multiplicative hash: (tick * 2654435761) >> 28
- ARCH-7. scoreFlashTimer ticks in draw() not logic() — headless mode issue; low priority but note it
- ARCH-8. Ball.trailHistory stores screen coords (already /100) — inconsistency needs comment
- ARCH-9. No matchEnd restart path — TennisScene idles; needs restart() method or delegate callback
- ARCH-10. ResourceIds covers only 3 assets — MVP needs up to 32 URLs for animated player sprites
- ARCH-11. Serve diagonal rule unspecified — always center or model deuce/ad sides?
- ARCH-12. Ball.applyHit() spin stat affects topspin and slice same way — counterintuitive; need separate derivations
- ARCH-13. Simultaneous hit at net — last hitter wins is implicit; should be explicit in design

## Questions Pending for PM/Designer
- GD-Q: See `docs/tennis-architecture-feedback.txt` for full list of GD-N open questions
- PM-Q: See `docs/tennis-architecture-feedback.txt` for full list of PM-N open questions

## ADRs (Architecture Decision Records)
- ADR-1. Rendering: client/server split (RendererClient + RendererServer) for determinism and future rollback
- ADR-2. Ball direction: will use pre-defined target positions (no normalization) — pending Designer confirmation
- ADR-3. VirtualDrive singleton for all assets — `vd://` URLs only
- ADR-4. Fixed-point arithmetic: Int × 100 scale for all game logic coordinates

## Signature Doc Status
| Subsystem | File | Status |
|---|---|---|
| TennisApp | docs/arch/tennis-app.md | Not created |
| Ball | docs/arch/tennis-ball.md | Not created |
| TennisPlayer | docs/arch/tennis-player.md | Not created |
| HumanController | docs/arch/tennis-human-controller.md | Not created |
| OpponentAI | docs/arch/tennis-opponent-ai.md | Not created |
| TennisScene | docs/arch/tennis-scene.md | Not created |
| MatchScore | docs/arch/tennis-match-score.md | Not created |

## Reference Docs
- `docs/tennis-architecture.txt` — existing architecture spec (authoritative until signature docs created)
- `docs/architecture-agent-design.md` — methodology reference

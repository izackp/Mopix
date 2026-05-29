# Designer Memory

## Current Project
**Mopixs** — 2D Swift game engine on SDL2. Active feature: Tennis game.

## Locked Design Decisions
- Movement: 8-directional
- Shot model: A (topspin), B (slice), A+B (flat), hold A (lob), hold B (drop), smash when ball is high
- Charge: hold to charge, capped; charge increases shot power but not speed beyond cap
- Auto-aim: moderate — player aim direction biased toward legal landing zones, not locked
- Hit radius: quality-band system (perfect/good/late) — not hard fail on positioning
- AI hidden info: permitted (landing prediction OK, physics cheats not OK)
- AI shot vocabulary: same as player
- Determinism: required — fixed-tick, no floats
- Feel target: arcade over realism; 11-point scoring; no full tennis scoring in MVP

## Open Design Questions
- GD-1. Failed sequential input fallback — second A after window expires: immediate topspin or lockout?
- GD-2. Charge visual feedback — sprite pose change during charge or charge bar only?
- GD-3. Post-sequence misfire — A→B with late B: slice fires or nothing?
- GD-4. Lob return eligibility — always smash opportunity or normal groundstroke eligible if positioned?
- GD-5. Drop shot bounce — does it visually bounce at all or die near net? Readability concern.
- GD-6. Simultaneous net exchange — player priority rule or special interaction?
- GD-7. Hitstop scope — both players freeze or only hitter?
- GD-8. Ball z scale — arcHeight=6000 may push ball off-screen at 160×144; needs visual validation
- GD-9. Trail persistence — clear on bounce or linger N ticks? Don't draw trail when z ≤ threshold?
- GD-10. Service box fault visualization — flash or "FAULT" text?

## Design Risks
- Ball height and shadow must be exaggerated to read at 160×144 — realism will fail
- Drop shot readability: if it dies near the net, players may think game froze
- Hitstop on CPU smash may frustrate player if ball travels past them while frozen

## Reference Docs
- `docs/tennis-game-spec.md` — detailed feature spec (existing, not yet migrated to docs/specs/)
- `docs/tennis-qa.md` — locked design Q&A
- `docs/game_design_skill.md` — design principles reference

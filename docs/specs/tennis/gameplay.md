# Tennis — Gameplay
code: RVK

Player vs CPU singles match. Arcade feel over realism, readable at
`160x144`.

### RVK-1 — Scoring
Points only, no deuce or advantage. First to 11 points wins, must win by 2.
Server alternates every 2 points.

### RVK-2 — Match structure
One singles match, one surface, player vs CPU. No doubles, no
tournaments, no progression. Match ends when a player wins per RVK-1.

### RVK-3 — Serve
Every point starts with a serve. Server fixed at baseline center; no foot
fault, no second serve. Serve must land in the diagonally-opposite service
box. Illegal serve awards the point to the receiver immediately.

### RVK-4 — Point end conditions
A point ends on exactly one of: second bounce on a side, ball into the net,
ball landing outside the singles boundary. Legality is judged at the
ball's landing point, not its position mid-flight. Lines are generous — a
landing point touching a line counts as in. No "unreachable ball" timeout.

### RVK-5 — Movement and hitstop
Movement is 8-directional, locked during serve wind-up. Hitstop (a brief
freeze on contact) is scoped to high-impact hits only — Smash and
fully-charged shots — not every hit. Routine rally contact stays fluid;
hitstop is reserved for moments that deserve the emphasis.

### RVK-6 — Shot inputs
- `A` — Topspin: fast, high arc, high bounce. Red trail.
- `B` — Slice: low arc, low bounce, skids after bounce. Blue trail.
- `A+B` — Flat Shot, or Smash if ball is above overhead height and player
  is within smash range (see RVK-8). Purple trail on Smash.
- `A -> B` — Lob: high arc, long hang, deep target bias.
- `B -> A` — Drop Shot: short travel, dies near the net.
- Hold before contact — charges the shot: more speed, more spin, capped.
  Reaching the cap gives the player a clear cue (visual and/or audio) so
  holding longer reads as "maxed," not "broken."

If a sequential input (`A->B` or `B->A`) times out before the second
press, the first press's standalone shot fires instead — e.g. a stalled
`A -> B` resolves as Slice, not nothing.

### RVK-7 — Contact quality
Three bands, purely by player-to-ball distance at the moment of the swing:
Perfect, Good, Poor. This is a positioning skill test, not a timing one —
there is no separate timing window or rhythm input. No hard positioning
gate; being out of position degrades a return, it never blocks it, as
long as the player is within return range.

### RVK-8 — Smash eligibility
Smash requires both: ball height above the overhead threshold, and the
player within a tighter radius than a normal return. `A+B` outside that
window falls back to Flat Shot. A lob may still be returned as a normal
groundstroke if the receiver isn't in smash position — smash is never
forced.

### RVK-9 — Simultaneous contact
If both players are in range of the ball on the same tick, resolution is
by a fixed, deterministic priority (not processing order), so replay from
a fixed seed stays reproducible: the human player's hit wins. The losing
side's swing still plays — the input isn't silently eaten — but does not
touch the ball.

### RVK-10 — Court surfaces
Three surfaces ship in MVP, each with a distinct speed/bounce profile:
Hard Court (normal speed, high bounce), Clay Court (slow, low bounce),
Grass Court (fast, low bounce). Surfaces must be distinguishable from play
behavior alone, and must also carry a distinct visual and audio tell each
(see front_end.md) — physics differences alone are too subtle to read
reliably at `160x144`.

### RVK-11 — Dash
Cut from MVP. Movement must feel complete on its own. Revisit only if
playtesting shows movement is sluggish without it.

### RVK-12 — Player stats
Two fixed presets: `Balanced` and `Power`. Human player always uses
`Balanced`; CPU always uses `Power`. No character select in MVP. Stats
(`power`, `speed`, `control`, `spin`) affect shot speed, move speed, aim
precision, and spin/bounce strength respectively. No stat growth or decay.

### RVK-13 — CPU opponent
CPU must be rally-safe before it is challenging: its job is to sustain a
rally, not to win. Baseline target is 6-8 shots before an unforced error
(see RVK-14). Uses the same shot vocabulary and rules as the player — no
shot the player can't also throw. May use hidden information (e.g.
perfect landing prediction) but must apply a minimum reaction delay
between ball contact and its own decision-commit, so it reads as reacting
rather than omniscient. May never cheat physically — no teleporting,
movement is regular move-speed only. One difficulty tier for MVP — no
difficulty select. If the `Power` preset (RVK-12) can't hit the rally
floor in practice, the preset — not the floor — is what gets retuned.

### RVK-14 — Unforced error
An unforced error is a point ending in a net fault or out-of-bounds fault
where the hitter's own contact quality (RVK-7) was Perfect or Good — a
clean look at the ball, missed anyway. A fault following Poor-quality
contact is a forced error and does not count against the CPU's rally
floor (RVK-13). A point ending by double bounce is a positioning failure,
not a shot error, and falls into neither category.

### RVK-15 — Local multiplayer
Out of scope for MVP and the release after. Single-player (vs CPU) only.

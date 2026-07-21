# Tennis — Gameplay
code: RVK

Player vs CPU singles match. Arcade feel over realism and readable play.

All timed thresholds use elapsed gameplay time. When a threshold falls between game updates, the
state change occurs at the first update after that threshold; minimum durations are never shortened.
This applies to hitstop, sequential-input timeout, charge cap, and CPU choice delay.

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
Movement is 8-directional, locked during serve wind-up. When a Smash or fully charged shot
contacts the ball, play visibly pauses for at least `0.10 s`, then resumes automatically. This is
an impact emphasis, not a reaction window; Topspin, Slice, Flat, Lob, and Drop contacts do not
pause. Input during the pause does not create a new swing or alter the committed hit. A button held
through the pause must be released and pressed again after the pause before it can begin another
transaction; the first eligible press after the pause is consumed normally.

### RVK-6 — Shot inputs
The first press of `A` or `B` starts one shot transaction. A second required button press must
arrive within `0.35 s` of the first press. Pressing both buttons before either is released is the
simultaneous `A+B` chord and starts a Flat Shot/Smash transaction. Releasing the first button before
pressing the second makes the input sequential: `A` followed by `B` within `0.35 s` commits a Lob;
`B` followed by `A` within `0.35 s` commits a Drop Shot. If the second press has not arrived when
`0.35 s` elapses, the first press resolves its standalone shot type: a stalled `A -> B` becomes
Topspin, and a stalled `B -> A` becomes Slice. If the initiating button is still held, the
standalone shot enters charge at `0.00 s`; if it has been released, the shot commits at `0.00 s`.

After the shot type is selected, holding the button that completes a sequential transaction charges
the shot. For simultaneous `A+B`, holding either button charges Flat Shot or Smash. Charge begins
at `0.00 s`, reaches its cap at `0.60 s` of held charge, and then remains capped. The cap cue appears
at `0.60 s` and remains until commit. Releasing the held button commits the shot; if the ball
reaches the player's return range first, it commits at that contact opportunity. A fully charged
shot receives the `0.10 s` hitstop described in RVK-5.

After a transaction commits, every button involved in it must be released before another shot
transaction can begin. The charge amount and cap cue clear on commit, at point end, or when the
next serve wind-up begins.

### RVK-7 — Contact quality
Measure distance at the instant of the swing using player-width units from the player center to the
ball. The canonical standing avatar reference is `8 px` wide from its leftmost to rightmost visible
body edge and `12 px` high from feet to head. One player-width is `8 px` and one player-height is
`12 px`; visual scaling does not change these references. A normal return is possible within `2.00`
player widths; outside that range produces no contact. Within range: Perfect is `0.00–0.50`, Good
is greater than `0.50` through `1.25`, and Poor is greater than `1.25` through `2.00` player widths.
A Poor contact still returns the ball.

### RVK-8 — Smash eligibility
The ball is overhead when its visible center is at least `1.00` player-height unit (`12 px`) above
its landing shadow. A Smash also requires the player to be within `0.75` player widths (`6 px`) of
the ball at the instant of the swing. When both conditions are true, `A+B` produces Smash;
otherwise `A+B` produces Flat Shot. A lob remains returnable as a normal groundstroke when either
condition is false.

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
behavior alone and reinforced by distinct visual cues. Optional audio may
also distinguish them under TZL-5.

Rally flight uses these player-perceivable windows, measured from outgoing contact:

| Ball type | Hard | Clay | Grass |
|---|---:|---:|---:|
| Serve — contact to first bounce | 0.50–0.70 s | 0.60–0.85 s | 0.42–0.58 s |
| Ordinary shot: topspin, slice, drop — contact to bounce | 0.50–0.70 s | 0.60–0.85 s | 0.42–0.58 s |
| Ordinary shot — bounce to next contact opportunity | 0.30–0.40 s | 0.34–0.46 s | 0.24–0.34 s |
| Fast shot: flat, smash, smash fallback — contact to bounce | 0.42–0.56 s | 0.50–0.66 s | 0.36–0.48 s |
| Fast shot — bounce to next contact opportunity | 0.26–0.32 s | 0.28–0.36 s | 0.24–0.30 s |
| Lob — contact to bounce | 0.75–1.05 s | 0.85–1.20 s | 0.65–0.90 s |
| Lob — bounce to next contact opportunity | 0.35–0.48 s | 0.40–0.55 s | 0.28–0.40 s |

Each bounce-to-return range begins at the first bounce and ends at the first playable contact
opportunity after that bounce. A playable contact opportunity is a legal swing from within the
`2.00` player-width return range under RVK-7; being in range before the bounce does not end the
post-bounce response window early. The response window is the player's opportunity to move and
swing, not a separate input-timing test. The minimum ordinary-shot response is `0.24 s`. The
landing location becomes clear at least `0.30 s` before bounce. Full charge may shorten the relevant
flight window by at most `0.10 s`, never below the stated minimum. Serve response after first bounce
is at least `0.30 s` on every surface.

Hard is middle-speed with the higher bounce; Clay is slowest with the longest response; Grass is
fastest with a low bounce and shorter response supported by stronger pre-bounce anticipation.
Surface identity must be readable from play behavior and reinforced by distinct cues.

### RVK-11 — Dash
Cut from MVP. Movement must feel complete on its own. Revisit only if
playtesting shows movement is sluggish without it.

### RVK-12 — Player stats
Two fixed presets: `Balanced` and `Power`. Human player always uses
`Balanced`; CPU always uses `Power`. No character select in MVP. Stats
(`power`, `speed`, `control`, `spin`) affect shot speed, move speed, aim
precision, and spin/bounce strength respectively. No stat growth or decay.

### RVK-13 — CPU opponent
CPU must be rally-safe before it is challenging: its job is to sustain a rally, not to win. Baseline
target is 6–8 shots before an unforced error (see RVK-14). After the opponent's contact, the CPU
waits at least `0.35 s` before choosing its next shot. During that delay, the player can see the
ball's direction, shot identity, and landing marker and can begin moving toward the marked landing
spot; the CPU may also move toward that spot, but cannot choose a shot before the delay. If the ball
becomes returnable before the delay ends, the CPU waits and may miss; it does not teleport or extend
the return range.

The CPU uses the same shot vocabulary and `0.60 s` charge cap as the player. After choosing a shot,
it chooses a charge duration from `0.00–0.60 s` and the shot commits automatically when that duration
elapses; if the ball reaches its return range first, it commits at that contact opportunity. One
rally shot is one successful return contact after the serve; the serve does not count toward the
`6–8` target. One difficulty tier ships in MVP; no difficulty select.

### RVK-14 — Unforced error
An unforced error is a point ending in a net fault or out-of-bounds fault
where the hitter's own contact quality (RVK-7) was Perfect or Good — a
clean look at the ball, missed anyway. A fault following Poor-quality
contact is a forced error and does not count against the CPU's rally
floor (RVK-13). A point ending by double bounce is a positioning failure,
not a shot error, and falls into neither category.

### RVK-15 — Local multiplayer
Out of scope for MVP and the release after. Single-player (vs CPU) only.

### RVK-16 — Serve wind-up
Every point begins in a visible serve-wind-up state. The server remains at baseline center and
cannot move until the serve is launched. The serve input produces one serve; holding the input
must not launch repeated serves. The wind-up and launch are fixed-tick gameplay transitions.

### RVK-17 — Shot input lifecycle
A shot is one input transaction: press, optional hold to charge, and release/commit. After a
transaction commits, every shot button involved in it must be released before another shot
transaction can arm. A charge-cap cue must be visible before commit when the cap is reached. The
charge amount and cap cue clear on commit, at point end, or when the next serve wind-up begins.

### RVK-18 — Serve anticipation
The `0.192 s` serve wind-up is an anticipation window signaled before the player chooses to serve,
not a reaction test. No player decision is judged inside that window. After it ends, the first valid
serve input launches one serve; holding that input does not launch another. The serve anticipation
cue clears when the serve launches or when the point ends.

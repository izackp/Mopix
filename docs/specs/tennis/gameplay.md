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
One singles match, one surface, player vs CPU. No doubles, no tournaments, no progression. Match
ends when a player wins per RVK-1. The default singles court occupies a `128x96 px` rectangle:
left and right boundaries are `x=16` and `x=144`, baselines are `y=24` and `y=120`, the net is
`y=72` from `x=16` through `x=144`, service lines are `y=56` and `y=88`, and the center service
line is `x=80`. Each service box is `64x16 px`; the baseline center is `x=80` and a legal serve
lands in the diagonally opposite box.

Player centers move inclusively from `x=20` through `x=140`; the near-side center moves from `y=24`
through `y=66` and the far-side center from `y=78` through `y=120`. A player cannot cross a
boundary or the net. At the net plane (`y=72`), a ball clears when its ground shadow crosses within
`x=16…144` and its visible center is at least `1.00` player-height above that shadow; exactly `1.00`
counts. Outside the net span, RVK-4 landing judgment applies. Cardinal movement uses full speed;
diagonal movement uses `0.707` speed on each axis.

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

D-pad or left stick provides eight-direction movement. Each stick axis is neutral at absolute value
`0.25` or below; above that threshold it selects negative or positive movement. Keyboard `WASD` and
arrow keys map to the same directions. Diagonal movement uses `0.707` speed on each axis. `A` is
the south face button and `B` the east face button; serve-wind-up presses are ignored and not
buffered. Other devices and unmapped buttons produce no tennis action.

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
Three surfaces ship in MVP, each with a distinct speed/bounce profile: Hard Court (normal speed,
high bounce), Clay Court (slow, low bounce), and Grass Court (fast, low bounce). Surfaces must be
distinguishable from play behavior and reinforced by distinct visual cues; optional audio may also
distinguish them under TZL-5.

The authoritative uncharged contact-to-bounce timings are: ordinary shots (Serve, Topspin, Slice,
Drop) Hard `0.70 s`, Clay `0.85 s`, Grass `0.58 s`; fast shots (Flat, Smash) Hard `0.56 s`, Clay
`0.66 s`, Grass `0.48 s`; and Lob Hard `1.05 s`, Clay `1.20 s`, Grass `0.90 s`. These values are
inside the locked RVK-10 windows. Bounce heights are measured from landing shadow to peak: Hard,
Clay, Grass Topspin are `1.50`, `1.15`, `1.00` player-heights; Slice `0.70`, `0.50`, `0.45`; Flat
`0.90`, `0.70`, `0.60`; Lob `1.70`, `1.35`, `1.20`; Drop `0.55`, `0.40`, `0.35`; Smash `1.00`,
`0.80`, `0.70`. Surface skid distances are Hard `1.00`, Clay `0.50`, Grass `1.50` player-widths;
Slice adds `0.50` and Drop adds `0.25` player-width.

Bounce-to-next-contact windows begin at the first bounce: ordinary shots Hard `0.35 s`, Clay
`0.40 s`, Grass `0.29 s`; fast shots `0.29 s`, `0.32 s`, `0.27 s`; Lob `0.42 s`, `0.47 s`,
`0.34 s`; Serve `0.35 s`, `0.40 s`, `0.30 s`. Charge changes only contact-to-bounce time, not
post-bounce response. During Serve response the server cannot launch another serve, but the receiver
can move and use ordinary shot inputs.

For rally shots, contact-to-bounce time is the uncharged value minus `0.10 s × (held charge / 0.60
s)`, never below the locked RVK-10 minimum. Flat and Smash share the fast-shot timing; Flat is a
low direct attack and Smash a steep attack, with Smash not arriving earlier. The surface and shot
tables are the Balanced baseline; Power modifiers are defined in RVK-12.

### RVK-11 — Dash
Cut from MVP. Movement must feel complete on its own. Revisit only if
playtesting shows movement is sluggish without it.

### RVK-12 — Player stats
Two fixed presets: `Balanced` and `Power`. Human player always uses
`Balanced`; CPU always uses `Power`. No character select in MVP. Stats
(`power`, `speed`, `control`, `spin`) affect shot speed, move speed, aim
precision, and spin/bounce strength respectively. No stat growth or decay.

The RVK-10 surface and shot outcomes are the Balanced human baseline. Power CPU movement is `1.10×`
Balanced movement speed; its contact-to-bounce time is `0.04 s` earlier, clipped at the RVK-10
minimum; its landing point is within `0.50` player-width of its selected target center versus
Balanced's `1.00` player-width aim spread; and Power adds `0.10` player-height to Topspin/Lob and
`0.05` to Serve/Flat/Smash bounce heights. Slice and Drop heights, surface skid, net clearance,
eligibility, contact range, target regions, and response windows do not change.

### RVK-13 — CPU opponent
CPU must be rally-safe before it is challenging: its job is to sustain a rally, not to win. Baseline
target is 6–8 shots before an unforced error (see RVK-14). After the opponent's contact, the CPU
waits at least `0.35 s` before choosing its next shot. At the end of that delay, or at the first
legal CPU swing opportunity if it is not yet in range, it measures contact quality, ball height,
net-to-baseline depth, and lateral distance from the current positions. It then chooses the first
applicable rule: Smash (`0.60 s`) when overhead and within `0.75` widths; Lob (`0.35 s`) when the
opponent is within `3.00` widths of the net; Drop (`0.25 s`) when the opponent is more than `5.00`
widths from the net; Slice (`0.15 s`) on Poor contact or a ball no more than `0.50` heights above
its shadow; Flat (`0.45 s`) when the opponent is more than `4.00` widths away laterally with
Perfect/Good contact; otherwise Topspin (`0.20 s`).

Depth is measured from net to the opponent's center along that player's court depth axis. Lateral
distance is the absolute horizontal difference between centers divided by `8 px`. The CPU targets
the center of a region: a deep corner is within `1.00` width of a sideline and `2.00` widths of the
opponent baseline; a Drop lands within `1.00` width of the net inside the opponent's service box;
the farther side from the opponent is selected, with right side resolving a tie. If the CPU never
reaches legal return range, it does not swing and normal point-end rules apply. Charge durations are
action durations, not reaction windows. The 6–8 shot length is a tuning target, not a guarantee.

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

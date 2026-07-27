# Tennis — Match HUD & Presentation
code: TZL

Camera, HUD, and in-match feedback while a point is being played (see
menus.md for screen flow, gameplay.md for match rules).

### TZL-1 — Camera
Fixed top-down, full singles court always visible. No scrolling, no zoom,
no camera modes.

### TZL-2 — Resolution
Logical play area is `160x144`. All layout and readability is judged at
that resolution; window scaling is presentation only.

### TZL-3 — HUD
Minimal, always visible during a match: player score, CPU score, serving side indicator, and charge
meters adjacent to each player with an uncommitted shot transaction. The human meter appears on the
human's first shot-button press; the CPU meter appears when the CPU begins charging. Each fills from
empty to full over `0.60 s`, shows the cap cue at `0.60 s`, and remains full until commit. If both
players have uncommitted transactions, both meters remain visible beside their owners. Each meter
and cap cue clears when that player's transaction commits, at point end, or when the next serve
wind-up begins.

### TZL-4 — Score display
Engine TTF font is used for score digits. Must be legible unscaled; legibility is required, not
assumed by default.

### TZL-5 — Audio hooks
All audio hooks are optional. Serve-hit, shot-type-hit, per-surface-bounce, net-contact,
out-of-bounds, score, fault, and charge-cap sounds may accompany their visual events, but silence
never removes or delays the corresponding player-facing result. If a surface sound is present, it
is distinct for Hard, Clay, and Grass; one shared bounce sound does not identify the surface.

### TZL-6 — Visual cues
Visual cues are the required readable language for shot type, landing, and bounce surface. Hard's
higher-bounce ring, Clay's spreading low-bounce dust, and Grass's low, fast horizontal skid remain
visible for at least `0.30 s` after each bounce. A tell does not clear before `0.30 s`; after that it
may clear when the next bounce begins. TZL-6 owns the visual vocabulary and minimum display
lifetimes for shot, landing, and surface cues. At Smash outgoing contact, the ball flashes white and
a four-point white starburst centered on it expands to `1.00` player-width over `0.10 s`; Flat Shot
has neither Smash-specific cue. The fixed top-down camera does not move, zoom, or change mode.

### TZL-7 — Illegal serve feedback
When a serve contacts the net or lands outside the diagonally opposite service box, `FAULT` appears
immediately after the illegal-serve judgment. It remains visible for `1.0 s` or until the next
point's serve wind-up begins, whichever comes first. The visual callout is required; fault audio is
optional.

### TZL-8 — Rally readability
For the serve and every shot type listed in RVK-6, the player receives a direction and shot-identity
cue immediately at outgoing contact. The cue remains visible for at least `0.30 s` and until the
landing cue appears, whichever comes later. The landing marker or shadow identifies the landing
location at least `0.30 s` before bounce and remains until bounce. The surface tell appears at bounce
under TZL-6's lifecycle. After bounce, the player can move into the RVK-7 return range and make a
legal swing during the surface-and-shot response window owned by gameplay.md.

For a normal rally point end, a net fault shows `NET` and an out-of-bounds fault shows `OUT`. Each
appears immediately at the point-ending judgment and remains visible for `1.0 s` or until the next
point's serve wind-up begins, whichever comes first. These callouts belong to TZL-8; no audio is
required to understand any rally, fault, or point-end result.

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
Minimal, always visible during a match: player score, CPU score, serving
side indicator, and a shot charge indicator on the active player. The
charge indicator sits at or adjacent to the player's sprite, not tucked in
a HUD corner — it needs to be noticed mid-rally at this resolution. It
also shows the charge-cap-reached cue described in RVK-6.

### TZL-4 — Score display
Engine TTF font is used for score digits. Must be legible unscaled at the
native `160x144` resolution — legibility at native res is an explicit
acceptance check, not assumed by default.

### TZL-5 — Audio hooks
Reserved hooks: serve hit, shot-type hit, per-surface bounce (a distinct
sting per surface, not one shared "bounce" sound — see RVK-10), net
contact, out-of-bounds, score stinger. Placeholder or silence is
acceptable everywhere in MVP — these are reserved slots, not a
requirement to ship real audio.

### TZL-6 — Visual cues
Required regardless of art fidelity: shot-type trail color (red topspin,
blue slice, purple smash — RVK-6), a landing marker or shadow under an
airborne ball, a clearly readable net line and court boundary, a
per-surface visual tell (e.g. a distinct bounce-particle variant per
surface, RVK-10), and a distinct point-end cue for a net fault versus an
out-of-bounds fault (RVK-4) — a generic "point over" flash is not enough,
the two must read differently in the moment.

### TZL-7 — Illegal serve feedback
A text callout (e.g. "FAULT") paired with the fault audio hook (TZL-5).
Text alone is unambiguous at this resolution; pairing it with sound is
free once the hook exists.

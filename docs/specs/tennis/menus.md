# Tennis — Menus
code: NQF

Title, surface select, and result screens (see match_hud.md for in-match
presentation, gameplay.md for match rules).

### NQF-1 — Screen flow
Title -> Surface Select -> Match -> Result -> back to Surface Select.

### NQF-2 — Surface select
Player chooses the court surface before each match from the three MVP
surfaces (RVK-10). Nothing is hardcoded past this screen.

### NQF-3 — Result screen
On match end, hold on the result screen (winner shown) until the player
presses a button to continue, then return to Surface Select. No
auto-restart.

### NQF-4 — Player stat presets
No preset-select screen in MVP. Human always plays `Balanced`, CPU always
plays `Power` (RVK-12).

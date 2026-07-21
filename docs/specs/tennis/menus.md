# Tennis — Menus
code: NQF

Title, surface select, and result screens (see match_hud.md for in-match
presentation, gameplay.md for match rules).

### NQF-1 — Screen flow
The player moves through Title → Surface Select → Match → Result. Pressing `A` on Title opens
Surface Select. After the player leaves Result, the game returns to Surface Select. No screen
advances without menu input except the immediate transition into Match after surface confirmation
and the automatic transition from Match to Result when the match ends.

### NQF-2 — Surface select
Surface Select shows exactly three choices: Hard, Clay, and Grass. On every entry, Hard is
highlighted initially. Left and right input moves the highlight one choice and wraps from the last
choice to the first; the new highlight appears immediately. Pressing `A` confirms the highlighted
surface and opens Match using that surface's speed, bounce, and visual identity. The selection
remains chosen for that match and is not changed automatically.

### NQF-3 — Result screen
When the match ends, Result shows exactly one outcome — `YOU WIN` or `CPU WINS` — and remains visible
until the player presses `A`. The press clears the result and returns to Surface Select; there is no
automatic restart or timeout.

### NQF-4 — Player stat presets
No preset-select screen in MVP. Human always plays `Balanced`, CPU always
plays `Power` (RVK-12).

# Tennis Open Questions — Designer Opinions

Answers from a game design perspective. These are opinions, not final decisions.
Lock answers you agree with; override any you don't.

---

## 1. MVP Product Rules

**What is the scoring model for the first playable?**
Lock `11-point arcade`. Full tennis scoring (15/30/40/deuce/advantage) adds UI complexity and extends match length without adding fun at this stage. The core loop needs validation first — scoring is a wrapper, not the game. Arcade points let you iterate fast. Add traditional scoring in Release 2 if it earns its complexity.

**Is a serve required to begin every point?**
Yes, always. Serves establish rhythm and give the player a moment of agency before each point. Auto-starting points removes intentionality and makes the game feel passive. Even a simplified serve (no second serve, fixed position) is worth the friction.

**What exactly ends a point?**
Second bounce, ball into net, ball out of bounds. These three cover all natural tennis outcomes and are unambiguous — no judgment calls. "Unreachable ball" as a loss condition should be avoided: it punishes slow reaction more than poor play, and at `160x144` the ball can be hard to read. Let the ball bounce twice instead.

**Should the ball have visible height / arcade depth, or flat 2D?**
Visible height with a shadow/landing marker. This is the most important readability decision in the game. Without depth cues, lobs and smashes are indistinguishable from groundstrokes, and positioning for returns becomes guesswork. A simple projected shadow (even a dot) solves this. The game spec already calls for this — commit to it early, not as polish.

**What is the intended match length for MVP?**
5–7 minutes per match. `11-point, win by 2` lands there naturally. Short enough to replay, long enough to feel like a match. If playtests feel too short, raise the target to 15 points before adding full tennis scoring.

**Should MVP feel arcade or lightweight realism?**
Arcade. The spec already commits to this (GBC aesthetic, `160x144`, simple inputs). Realism at this resolution and input vocabulary creates mud, not depth. Exaggerate everything: shot arcs, ball speed differences, bounce height. Players should *feel* the difference between topspin and slice immediately.

---

## 2. Simulation Model

**Minimum ball behaviors required for MVP?**
Travel, bounce (once legal, twice loses point), net collision, out-of-bounds, landing-side legality, and a projected landing marker. That's it. Height tracking is needed for smash eligibility but can be implicit. Don't add spin physics until the basic ball feels good.

**How should in/out legality be judged?**
Landing point of the bounce, not ball center during flight. This matches player intuition — you judge where it *lands*, not where it *was*. Generous margins on the lines (call it in if the landing point touches the line). Tight legality at `160x144` will frustrate players who can't read pixel-level positions.

**What kinds of bounce behavior matter for MVP readability?**
Two things only: bounce height and post-bounce speed. Topspin = high bounce, fast. Slice = low bounce, slow, skids. Everything else (lateral drift, kick angle) is post-MVP tuning. Surface multipliers layer on top of shot base values — this is why data tables matter from day one.

**Should all shots share one ball model or be distinct rule types?**
One shared ball model with per-shot parameter overrides (speed, arc, spin, bounce multiplier). Distinct rule types create maintenance cost and inconsistent edge cases. The shot identity comes from the parameters, not from separate codepaths.

**Does MVP need deterministic behavior?**
Yes, from day one. The spec already calls this out and the roadmap lists it as a pillar. Determinism costs almost nothing if designed in early and is extremely painful to retrofit. Fixed-tick simulation, no floating-point-dependent branching. This also makes debugging playable: you can reproduce exact rally sequences.

---

## 3. Controls and Feel

**4-directional or 8-directional movement?**
8-directional. The spec already locks this. 4-directional on a tennis court creates constant diagonal awkwardness when chasing wide balls. 8-direction is the right call — don't reopen it.

**Exact shot input model?**
The spec's model (`A`, `B`, `A+B`, `A→B`, `B→A`, hold-to-charge) is well-designed. The sequential inputs (`A→B` for lob, `B→A` for drop) are the highest risk — they require precise timing and can misfire into the wrong shot. Recommendation: add a generous input window (200–300ms) for sequential inputs during playtesting and tighten only if abuse cases emerge. The charge mechanic is essential; it gives players something to do while waiting and rewards reading the ball early.

**Is charge required for MVP?**
Yes. Charge is what separates skilled play from button-mashing. Without it, all returns at the same shot type feel identical. It's also the primary expression of "I read the ball early and I'm rewarded for it" — which is the core skill loop.

**How strict should positioning be for returns?**
Generous hit radius with quality penalty for being off-center, not a hard fail. Hard position gates ("you must be within X pixels") punish the readability problem, not the player's skill. Use the three-band timing/quality system (`Perfect`, `Good`, `Late`) — that's the right answer already in the spec.

**How much auto-aim is acceptable?**
Moderate. Auto-aim toward the most dangerous return target as default, with directional input overriding it. Players who want precision can aim; players who don't still get readable returns. Zero auto-aim at `160x144` with 8-direction input will feel broken for casual players.

**Is dash in MVP?**
Soft no. Include the input detection (double-tap direction) but make it a cut candidate. Implement movement first; if it feels sluggish without dash, ship it. If rallies read fine without, defer to Release 2. Don't architect around its presence, but don't block the input either.

---

## 4. AI and Opponent Expectations

**What should the MVP opponent be: functional, fair, challenging, or rally-safe?**
Rally-safe first, then fair. The CPU's primary job in MVP is to *not break the game* — it should keep rallies going long enough for the player to experience all shot types and court surfaces. Challenge is Release 2 tuning. A broken CPU that misses returns constantly makes everything else impossible to evaluate.

**Can AI use hidden assistance?**
Yes, but sparingly. Perfect landing prediction is fine — players can't tell. Movement cheats (teleporting to position) are not fine — players notice rubber-banding. The distinction: hidden *information* advantages are okay; hidden *physics* advantages are not.

**Should AI use the same shot vocabulary as the player?**
Yes. Same shot types, same rules. Asymmetric AI (CPU has shots the player doesn't) creates unfair feel and is harder to design around. The AI should be a fair opponent that makes intelligible decisions, not a scripted pattern machine.

**Minimum rally consistency for MVP?**
CPU should sustain rallies to 6–8 shots reliably before making errors. Below that, players can't learn shot feel. Above that is fine — tune down if CPU is too hard.

**Does MVP need difficulty levels?**
No. One baseline opponent. Difficulty tuning requires knowing what "correct" feels like first. Build that, then layer difficulty.

---

## 5. Acceptance and Testing

**What manual test scenarios must exist per milestone?**
At minimum: serve legal, serve illegal, topspin rally, slice rally, lob over CPU, drop shot winner, smash, point end by bounce, point end by net, point end by out. These cover all termination states and all shot types. Each scenario should be reproducible from a fixed seed.

**What debug visualizations are acceptable?**
Landing marker (always on in debug), hit radius ring, bounce count display, ball height numeric, CPU target position. These should be toggled with a flag, not compiled out — you'll want them during tuning.

**What evidence is required to accept a milestone?**
Short screen recording showing each acceptance criterion in action. Not a screenshot — too easy to stage. Video captures real behavior. Headless capture is acceptable if the game supports it.

**Which milestones need deterministic/automated verification?**
M2 (rally simulation) and M3 (shot system) are the priority candidates. Ball physics and shot parameters are tuned values — automated regression tests catch when a parameter change accidentally breaks legality rules. M1 (static court) and M5 (UX) don't need it.

**What engine constraints should milestone specs call out?**
Fixed-tick simulation, no Process/subprocess calls, VirtualDrive for all assets, no floating-point-dependent branching in game state. These should appear explicitly in every milestone spec so workers don't make incompatible choices.

---

## 6. Milestone Slicing

**What is the finalized MVP?**
Player vs CPU singles match on hard/clay/grass courts. 11-point arcade scoring. All 6 shot types usable. Match can be started, played, won or lost, and restarted from menus. Readable at `160x144`. Everything in the spec's acceptance criteria section.

**Which milestone outputs should be durable, not throwaway?**
M2 (ball simulation + rally rules) and M3 (shot system) must be durable. These are the game. M1 (court shell) is explicitly a proof artifact — accept that some of it may be restructured in M2. Build M1 knowing M2 will extend it, not replace it.

**What should M1 establish that later milestones extend rather than replace?**
The executable target, window setup, resource loading path, and scene entry point. The rendering path and court geometry representation should also be locked in M1 — these are the things most likely to get redesigned if left open.

**Where should the boundary sit between "prove the concept" and "build the real runtime"?**
M1 = prove the concept (does the executable launch, does the court render?). M2 onward = real runtime. The operational discoveries doc makes this clear. Don't let M2 scope creep into M1, but don't let M1 masquerade as M2 either.

**Which open decisions must be locked before writing more specs?**
In order of urgency:
1. Logical canvas size — `160x144` exact or slightly larger with crop? This affects court geometry in M1.
2. Scoring model — already locked as `11-point` in the spec; confirm and close the question.
3. Dash — in or out for first playable? Affects M2 movement scope.
4. Art-first or placeholder-first — placeholder is the right call; confirm so workers don't block on art.

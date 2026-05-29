# Game Designer Skills

## Core Philosophy
- **Fun = Mastery Through Problem-Solving** — mechanics pose problems within constraints; satisfaction comes from solving them
- **Toy-First** — before goals/points/win state, ask: is the core interaction fun alone? If the basic verb isn't engaging, nothing fixes it
- **Depth over Complexity** — players say they want complexity but mean depth. Complexity is currency; spend wisely
- **Don't simulate everything** — create the illusion of simulation. Saves dev time, preserves sense of living world
- **Bushnell's Law** — easy to learn, hard to master. Low entry barrier + progressively revealed depth

## Readability at Low Resolution
At 160×144, readability is a hard constraint, not a polish concern:
- Ball height, shadow, and trajectory must be exaggerated enough to read clearly
- Trail and landing feedback are mandatory, not optional polish
- Text must use pixel-legible fonts or sprite numbers — TTF at small sizes may be unreadable
- Every state change (fault, score, serve) needs a visual signal readable in one frame

## Mechanics & Systems
- **3-5 Rule** — limit any decision point to 3–5 options. Prevents cognitive overload
- **Teach Implicitly** — design so mechanics are learned through play, not text boxes
- **Overlapping Events** — multiple things can happen simultaneously; don't design events in isolated sequential silos
- **Immediate Input → Output** — all inputs must have immediate feedback. Disconnect builds frustration
- **Anticipation** — give the player time and cues before something happens (charge-up before attack, serve wind-up)

## Game Feel ("Juice") — Six Levers
| Lever | Meaning |
|---|---|
| Input | Natural mapping between control and on-screen action |
| Response | Low latency + high sensitivity = responsive feel |
| Context | How abilities interact with world — meaningless without context |
| Polish | Screen shake, particles, squash & stretch — make actions satisfying |
| Metaphor | Conceptual link between real-world action and in-game action |
| Rules | Underlying systems defining what is possible |

## MDA Framework
- **Mechanics** → **Dynamics** → **Aesthetics**
- Designer view: design mechanics, observe dynamics, target aesthetics
- Player view: feels aesthetics, interprets dynamics, discovers mechanics
- When evaluating a design decision, ask: what aesthetic does this produce?

## Tennis-Specific Design Principles
- Shot differentiation must be readable from trajectory and bounce alone — no HUD labels needed
- CPU opponent should feel fair before feeling challenging — priority is readable returns, not perfect AI
- Hitstop should freeze both players equally unless there's a strong design reason to differentiate
- Serve rules should be as simple as possible while preserving the tactical serve/return dynamic
- Surface differences must be observable in bounce and tempo without being explained

## Open Question Format
```
GD-N. <Title>
   <Player experience question — one sentence>
   Options:
     A. <option> — <how player experiences it>
     B. <option> — <how player experiences it>
   Recommend: B — <design rationale referencing a principle if relevant>
```

## Balance & Feel Tuning
- Define the target experience first ("rally lasts 8–12 hits before a winner")
- Tune toward the target, not toward realism
- High-variance outcomes (rare drops, crits) create excitement but risk frustration — use pseudo-random distributions if frustration is a concern
- Reward the Victor, Don't Punish the Loser — in conflicts, buff the winner rather than nerf the loser

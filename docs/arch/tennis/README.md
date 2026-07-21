# Tennis Architecture

This directory is the signature-doc map for the Tennis runtime. Signatures are
declaration-only contracts; implementations belong in the target/module named below.

## Module graph

```text
Tennis executable (Tennis)
├──► GameEngine
├──► TennisCore ──► Foundation
└──► TennisInput ──► GameEngine
                 └─► TennisCore
```

- `TennisCore` is dependency-free. It owns fixed-tick simulation, gameplay value types,
  shared action-intent contracts, deterministic rules, and seeded randomness.
- `TennisInput` depends on `GameEngine` and `TennisCore`. It owns command translation,
  sequence resolution, human input, and CPU controllers. It has no presentation dependency.
- `Tennis` is the executable integration module. It depends on `GameEngine`, `TennisCore`,
  and `TennisInput`; it owns match flow and presentation.

Dependencies point toward lower-level contracts: Core never imports engine/input APIs; Input
imports Core plus engine input APIs; runtime integration consumes both. Presentation reads
snapshots/events and never mutates simulation state.

## Signature map

| Area | Target/module owner | Signature |
| --- | --- | --- |
| Simulation and shared gameplay contracts | `TennisCore` | [core/simulation.md](core/simulation.md) |
| Input and controllers | `TennisInput` | [input/controllers.md](input/controllers.md) |
| Match flow | `Tennis` executable | [runtime/match-flow.md](runtime/match-flow.md) |
| Rendering and presentation | `Tennis` executable | [runtime/presentation.md](runtime/presentation.md) |

## Canonical type ownership

Declared once in [core/simulation.md](core/simulation.md): `TennisFixed`, geometry, sides,
surfaces, stats, presets, shot/contact types, `TennisDirection`, `TennisSwingSequence`,
`TennisActionIntent`, `TennisTickInput`, simulation state/events, point-end reasons,
`TennisRandomSource`, `TennisRuleBook`, and `TennisSimulation`.

Declared once in [input/controllers.md](input/controllers.md): `TennisActionButton`,
`TennisInputFrame`, input/controller protocols, routers, and controllers.

Declared once in [runtime/match-flow.md](runtime/match-flow.md): match screen/score/state/events
and presentation snapshot types.

Declared once in [runtime/presentation.md](runtime/presentation.md): viewport/assets and
presentation, draw-sink, and audio-hook contracts.

Cross-module references use those canonical declarations; no signature document redeclares a
type owned by another document.

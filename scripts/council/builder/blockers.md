# Builder Blockers

No active blockers.

## BLOCKER-1 — 2026-07-20
**File**: `Sources/GameEngine/TennisSimulation.swift`
**Issue**: The locked `TennisActionIntent.swing(buttons:charge:)` carries no sequence/kind information. The simulation therefore cannot distinguish `A -> B` Lob from standalone `A` Topspin, or `B -> A` Drop from standalone `B` Slice; `ShotCommand` is not accepted by `TennisSimulation.step`.
**Attempted**: Asked ARCH directly twice through `council.sh`; no answer was returned. Implemented the unambiguous standalone, flat, serve, and smash-fallback paths and left sequential mapping unresolved.
**Question for Architect**: Specify the intended mapping/state owner without silently changing the locked contract, or approve the smallest contract addition needed to carry resolved shot kind.
**Status**: OPEN

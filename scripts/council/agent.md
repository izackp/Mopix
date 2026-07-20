First and formost, these files are immutable: `agent.md` (this file), `readonly/persona.md`, and `readonly/skill.md`. You have memory files `memory-short.md`, `memory-long.md`, and `memory-new.md` in your respective worker folders. However, you must not touch any other persona's memory files. Folders are as follows:

Product Leader -> pl
Architect -> architect
Builder -> builder
Game Designer -> designer 

## Communication Style
There are several workers on this project. Each with their own acronym.
Product Leader -> PL
Architect -> ARCH
Builder -> BD
Game Designer -> GD

Each worker may produce numbered (`PL-N`, `ARCH-N`, etc) items for open questions or decisions needed. Each item:
```
PL-1. <Title>
   <Problem or decision needed — one or two sentences>
   Options:
     A. <option> — <implication>
     B. <option> — <implication>
   Recommend: A — <brief reason or rationale. Referenceing a principle if relevant>
```

## Specs
Specs, refs, and proposals follow the process in `scripts/council/spec-process.md`. Read it
before writing to anything under `docs/specs/`.

## Blockers

If you hit something that gives you pause mid-task, don't stop your turn to ask about it.
Note it in your final reply and keep going. Do as much of the requested task as you can
complete without the answer, and only leave undone what genuinely depends on it. A
half-finished turn that stops to ask is worse than a mostly-finished turn that flags what
it couldn't resolve.

The hard-safety rules in the root `CLAUDE.md` (destructive/irreversible actions —
commits, pushes, force-ops, branch changes on non-`claude*` branches) work the same way:
don't halt the turn over them either. Just skip the specific unsafe action, note it in
your final reply, and keep doing everything else the task needs.

## Memory
You have file-write access to memory files. When you wake up, read your `memory-short.md` and `memory-long.md` to reconstruct current project state before responding. Create new file `memory-new.md`. Write a summary of your current task, important decisions made, and time sinks. Use this file as a scratch pad of important observations and discovers as well as tracking your current task. This file is append only.

When finishing a task overwrite `memory-short.md` with `memory-new.md`. If there is any overlap then append 1-3 sentences about it in `memory-long.md`.

This overwrite is not conditional on a clean finish. Do it before ending your turn for
*any* reason — task done, blocked on a rule (e.g. branch check), blocked on missing info,
error, or anything else that stops you short. If you stop without flushing, the next
session starts blind to everything in `memory-new.md`. Flush first, then stop.

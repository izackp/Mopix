`agent.md`, `readonly/persona.md`, `readonly/skill.md` are immutable. Memory files
(`memory-short.md`, `memory-long.md`, `memory-new.md`) live per-worker; never touch another
persona's. Folders: Product Leader -> `pl`, Architect -> `architect`, Builder -> `builder`,
Game Designer -> `designer`.

Before acting, read the repository root `CLAUDE.md` and follow its instructions.

## Communication Style
Acronyms: PL, ARCH, BD, GD. Raise open questions/decisions as numbered items:
```
PL-1. <Title>
   <Problem or decision needed — one or two sentences>
   Options:
     A. <option> — <implication>
     B. <option> — <implication>
   Recommend: A — <brief reason or rationale>
```

## Commit Attribution
Every commit must end with a matching trailer: `By: PL`, `By: GD`, `By: ARCH`, or `By: BD`.

## Specs
Follow `scripts/council/spec-process.md` before writing to anything under `docs/specs/`.

## Blockers
Don't stop your turn to ask about something — note it in your final reply and keep going
on everything not gated by the answer. Same for the hard-safety rules in root `CLAUDE.md`
(commits, pushes, force-ops, branch changes off `claude*`): skip the specific unsafe
action, note it, keep going. Never halt the whole turn over one blocked thing.

If a council call reports that the target session is already active, do not retry it.
If the needed information is a question for that active caller, end your turn early
with the question clearly stated so the caller can answer it.

## Memory
`memory-new.md`: your scratchpad, append-only, write freely; do not read it at wakeup. Read
`memory-short.md` and `memory-long.md` instead. Never write `memory-short.md` — `council.sh` flushes
`memory-new.md` into it after every call, mechanically. Write to `memory-long.md` only rarely, for
generic principles that save time across future tasks; do not store task-specific state or history.

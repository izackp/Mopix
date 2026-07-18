First and formost, these files are immutable: `agent.md` (this file), `readonly/persona.md`, and `readonly/skill.md`. You have memory files `memory-short.md`, `memory-long.md`, and `memory-new.md` in your respective worker folders. However, you must not touch any other persona's memory files. Folders are as follows:

Product Leader -> pm
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

## Memory
You have file-write access to memory files. When you wake up, read your `memory-short.md` and `memory-long.md` to reconstruct current project state before responding. Create new file `memory-new.md`. Write a summary of your current task, important decisions made, and time sinks. Use this file as a scratch pad of important observations and discovers as well as tracking your current task. This file is append only.

When finishing a task overwrite `memory-short.md` with `memory-new.md`. If there is any overlap then append 1-3 sentences about it in `memory-long.md`. 

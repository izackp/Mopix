# Council — Known Issues

Identified 2026-07-18 while reviewing the kickoff plan for the tennis game. Ranked by impact.

## 1. Feedback files have no addressee — routing ambiguity
`*-feedback.md` files under `docs/specs/` are injected into **every** persona's prompt.
- A persona sees its own authored feedback listed as "pending" until renamed.
- Unclear who acts: is `m1-plan-feedback.md` for PM (revise plan) or Builder (heed while implementing)? Both may act — PM rewrites plan while Builder builds against v1.
- Unclear who renames to `-feedback-done.md`; Builder can't declare Architect's plan-critique satisfied.

**Fix options:** filename convention with addressee (e.g. `m1-plan-feedback-pm.md`, only addressee renames), or treat injection as FYI-only and route manually.

## 2. No git discipline between runs
Builder writes code, PM writes docs, everyone churns memory files — all uncommitted on the same working tree. One bad run can't be unwound cleanly.

**Fix:** commit after each persona run (orchestrator does it, or add "commit your changes before finishing" to `agent.md`).

## 3. Resumed sessions hold stale file views
A resumed session "remembers" the version of a file it last read. If another persona revised the file since, the resuming persona may act on stale content without re-reading.

**Mitigation:** every relay prompt must explicitly say "re-read <file> — it changed."

## 4. Session rotation can land mid-task (Builder especially)
Rotation at `SESSION_MAX_TURNS` (default 8) may hit mid-implementation; `memory-short.md` must carry in-flight state across the reset — quality dip likely.

**Mitigation:** bump budget for Builder (`SESSION_MAX_TURNS=16 council.sh builder ...`) or rotate manually at task boundaries (delete `session_id_<harness>` after a milestone completes).

## 5. Decisions evaporate into sessions
Answers to `PL-N`/`ARCH-N` items given in chat live only in session context + maybe memory — both rotate/compact eventually.

**Fix:** instruct personas to record every answered decision item in the relevant spec/plan doc. Docs are the durable ledger; sessions are cache.

## 6. Rotation warning contradicts agent.md memory ritual
`agent.md` ritual: append to `memory-new.md`, then on task end overwrite `memory-short.md` with it. The rotation warning injected by `council.sh` says "overwrite memory-short.md directly." Two rituals; models may reconcile inconsistently.

**Fix:** pick one ritual and align `agent.md` + the rotation warning text.

## 7. Single-prompt milestones are optimistic
"Implement M1" as one codex exec run risks long silent stalls (e.g. repeated swift builds).

**Mitigation:** wrap builder runs in `idle-timeout.sh`, and split milestones into 2–4 builder prompts.

## Accepted / smaller
- Switching harness mid-persona forks state (per-harness session + turn files, shared memory files). Pick one harness per persona and stick with it.
- Full permissions (`--dangerously-skip-permissions`, `-s danger-full-access`) mean personas *can* modify `readonly/` files and other personas' memory. Honor system; external plugins are the guard.
- `last_prompt.txt` / `last_response.txt` are shared across harnesses — overwritten per run.

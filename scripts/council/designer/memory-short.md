# GD scratch — tennis proposals review (2026-07-20, round 2)

Task: review docs/specs/tennis/{gameplay,front_end,acceptance}.proposal.md, append GD:
feedback under each ## Feedback section, weigh in on PL-N items. Round 2 = deeper pass +
respond to PL's reply on PL-10 + find missing game-feel items. Append-only, never edit
prior GD/PL lines.

Round 1 (done): supported PL-1,2,3,4,9,5,6,7,11,12,10. Raised GD-1 (hitstop scope, limit
to smash/charged only) and GD-2 (add charged-shot test scenario).

Round 2 (done):
- acceptance.proposal.md: accepted PL's correction on PL-10 (reviewer is AI-only, no
  video path at all — B/log-assertions is right, not a compromise). Raised GD-3: log
  schema must carry "unforced error" definition (once gameplay defines it) and charge-cap
  state as loggable fields, or PL-4's floor and GD-5's cap can't be asserted against logs.
- gameplay.proposal.md: harder look at PL-2 (dropped-hit must be physically dropped, not
  just cosmetic — state explicitly, net play makes this common not rare) and PL-4
  ("unforced error" is undefined, floor isn't testable without it). New items:
  GD-4 contact quality distance-vs-timing ambiguity (Late label implies timing, item 7
  text says distance-driven, Early quietly dropped — recommend pick spatial axis, rename
  bands to avoid timing implication since there's no timing-window input mechanic).
  GD-5 charge-cap has no feedback cue when max reached (silent cap reads as broken).
  GD-6 CPU hidden-info (item 11) has no reaction-delay bound — instant use of landing
  prediction reads as omniscient/robotic even without physical cheating; recommend min
  reaction delay, separate concern from PL-4 difficulty tuning.
- front_end.proposal.md: harder look at PL-6 (score legibility at 160x144 unscaled is
  itself a feel question, not just cost — recommend acceptance check) and PL-7 (Power CPU
  preset may conflict with PL-4's 6-8 shot rally-consistency floor if power trades off
  control/spin — flag for joint check once "unforced error" is defined). New items:
  GD-7 surfaces have gameplay-behavior distinction but no committed visual/audio tell
  (only one generic surface-bounce hook) — recommend per-surface bounce sting.
  GD-8 point-end causes (net/out/double-bounce) have no distinct feedback, player has to
  infer cause after the fact — recommend distinct net vs out cues.

Cross-file dependency chain now open: gameplay needs to define "unforced error" →
acceptance log schema (GD-3) and front_end PL-7 preset check both depend on that
definition landing first. Flag this dependency if asked what's blocking convergence.

State: still Review/Convergence phase. Next: user/PL responds to round-2 items, loop
until no open items, then PL promotes and deletes proposals.

No spec code letters assigned yet by me (specs not promoted).

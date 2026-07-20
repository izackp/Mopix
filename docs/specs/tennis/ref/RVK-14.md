## Why unforced error is defined off contact quality

RVK-13's rally-consistency floor ("6-8 shots before an unforced error")
was unusable as written — no operational definition, so nothing for CPU
logic to branch on and nothing for JBH-4's log schema to record. Contact
quality (RVK-7) was already a loggable, spatial-only signal per point, so
defining unforced error against it (Perfect/Good contact that still
faults = unforced; Poor contact that faults = forced, doesn't count) reuses
existing state instead of inventing a new one. Double bounce is excluded
entirely — it's a failure to reach the ball, not a failure during a shot,
so it isn't a "hitting" error of either kind.

# Tennis Acceptance — Working Draft (PL scratch, not a spec)

Pulled out of `docs/specs/tennis/` because acceptance criteria are milestone-scoped, not
durable product rules — they don't fit the RVK/WPX-style spec system. This is PL's own
holding area until a milestone doc exists to receive this content properly. Not read by
other personas.

## Why this got pulled

Acceptance was drafted around "how does an AI reviewer cheaply verify this," which
answers the wrong question. A client accepts a milestone by playing the real build — an
automated test suite proves logic didn't regress, it proves nothing about whether the
game is good. The two got conflated. See conversation history for the full argument.

## Content worth keeping for the eventual milestone doc

### Required scenarios (from former JBH-1)
Must be reproducible from a fixed seed, one scenario per termination/shot state: legal
serve, illegal serve, topspin rally, slice rally, lob over the CPU, drop shot winner,
smash, fully-charged shot vs uncharged shot, point end by double bounce, point end by
net, point end by out.

### Debug visualizations (from former JBH-2)
Available behind a runtime toggle, not compiled out: ball landing marker, hit radius
ring, bounce count, ball height value, CPU target position.

### Log schema, if an automated regression layer gets built (from former JBH-4)
Per-point logged state should include: contact quality (RVK-7), point-end reason
(RVK-4), the unforced-error/forced-error classification (RVK-14), and whether the charge
cap was reached during that point (RVK-6). This is for catching logic regressions
cheaply — it is not a substitute for a human playing the build, see below.

### Determinism note (from former JBH-5)
Fixed-seed reproducibility requires a single seeded random source for all gameplay
randomness — CPU decisions, aim spread, anything probabilistic. No ambient/system
randomness in the simulation path. Still true and still useful if automated tests get
built, independent of how acceptance itself gets judged.

### Evidence standard — needs rethinking, not carried forward as-is (former JBH-3 / ref)
Original framing: acceptance review is AI-only, no video path, so evidence should be
per-tick log assertions with screenshots reserved for inherently-visual criteria. This
optimized for the wrong reviewer. Real acceptance is a human (the client) playing the
actual build and judging feel/readability/fun — logs and screenshots don't substitute
for that. When this gets rewritten into a milestone doc, lead with "someone plays it,"
and treat automated log assertions as a separate, lower-stakes regression-safety layer
underneath that, not the acceptance mechanism itself.

## Why hitstop is scoped to high-impact hits, not every hit

Original draft froze both players briefly on any contact. Designer
objected: in a fast rally with routine topspin/slice exchanges, freezing
on every single hit kills flow — hitstop is a juice tool for emphasizing
impact, not a universal response to input. Architect agreed independently
on implementation grounds: a smash-only/charged-only trigger is a local,
opt-in check, versus a global freeze state every hit path has to know
about. Both the feel argument and the cost argument point the same way,
so this was an easy lock. Revisit only if playtesting shows routine hits
need more weight than they currently read with.

# ADR-0031: The pet is chosen by its egg, and stays a surprise until the hatch

- **Status:** Accepted
- **Date:** 2026-10-18
- **Decided in:** [#114 Choose your pet by its egg, so the pet is a surprise at the hatch](https://github.com/heichan2000/Tomo/issues/114)
- **Amends:** [ADR-0012](0012-earned-hatch.md) — "the species is chosen and known from this point" becomes *chosen, but hidden until the hatch*.

## Context

ADR-0012 put the pick on onboarding's first screen and the hatch at the end of
the first finished block. The pick showed the three hatched pets by name, and
the chosen pet introduced itself, so by the hatch the user already knew what
was coming. The hatch only added the name.

The user wanted the hatch to be a real reveal: the species, its look and its
name arriving together, at the moment the user has earned it.

## Decision

**The user chooses an egg, not a pet.** *Choose your egg* shows the three
eggs, each with a name that describes it (*Stone egg*, *Paper egg*, *Spotted
egg*), and under the tiles the chosen egg's one-line hint, in the plain voice.
The species is still chosen and stored at setup; only the telling waits.

**Until the hatch, nothing names the pet or speaks in its voice.** Every line
the user meets before the hatch is in the plain voice and names only the egg:
the line under the egg on Home, the egg's screen-reader label, and the first
block's notification (title and body), along with the rare break notification
before the hatch is seen.

**The hatch says what hatched.** The name field's label is *Name your Geode*
(*Joe*, *Lily*), since the pre-filled name alone would read as a suggestion.

The eggs keep their own colours and their different numbers of crack steps.
The egg already looks like its pet, so neither tells the user anything the
picture doesn't.

## Consequences

- Before the hatch, the pet has no voice. ADR-0012's "the pet has a voice
  before it has a name" no longer holds: the first thing the pet ever says is
  its hatch line.
- The egg's names are part of the copy, one per species, and are written to
  describe the egg, not hint at the pet's kind. The hints hint at its
  character.
- The species name can now be first seen at the hatch, which is why the name
  field's label carries it.

## Alternatives rejected

**Show the eggs with no names.** The eggs would be harder to tell apart and
to talk about, for sighted users and screen-reader users alike.

**Name the eggs by pattern only** (*Plain*, *Zigzag*, *Spotted*). They give
less away, but the user preferred names that say what the egg is made of.

**Let the pet speak from inside the egg.** It's warmer, but each pet's voice
is distinct enough to give it away.

**Choose at the crack, with no pick at setup.** Already rejected by ADR-0012:
it leaves the first session characterless and loads the payoff screen.

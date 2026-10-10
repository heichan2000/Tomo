# ADR-0005: Reduce motion is graded — the pet keeps breathing, and stillness is its own control

- **Status:** Accepted
- **Date:** 2026-08-27
- **Decided in:** [#8 Accessibility & localization baseline](https://github.com/heichan2000/Tomo/issues/8)
- **Amended by:** the pixel look ([#32](https://github.com/heichan2000/Tomo/issues/32)).
  The rule stands; its examples are out of date. There are no coins
  ([ADR-0007](0007-no-currency-no-cosmetics.md)). Evolution is a flicker, not a
  morph ([ADR-0018](0018-pixel-pets-slide-whole-pixels-flicker-evolution.md)),
  and the hatch breaks the egg's shell; under the flag both still cross-fade.
  The reduced list adds
  **sparkles held still**, and the pet's reduced idle is **nothing moves more
  than one pixel, breath at half speed**
  ([ADR-0019](0019-reward-ladder-twinkle-in-pet-pixels.md), ADR-0018). The pet
  is painted pixel art moved by Flutter, not Rive, so "Rive input" and
  "riggable" read as *part of the pet look*

## Context

Tomo's commitment device is an animated creature. The PRD's positioning rests on
"a relationship with one pet", #5 put that pet on **Home** — the landing tab, so
it is the first and most persistent thing a returning user sees — and the
architecture doc buys Rive specifically to make it reactive rather than static.

The OS reduce-motion flag, surfaced to Flutter as `MediaQuery.disableAnimations`,
therefore points straight at the product's emotional core. Read literally it says
"turn the animation off", and there is exactly one animation in Tomo that matters.

The literal reading is also a misreading. Reduce-motion is a **vestibular**
control. It exists for content that travels, scales, spins, or parallaxes —
motion that moves the viewer's sense of the world. A character blinking and
breathing in place is not the thing the flag was written to suppress. Honouring
it as a global off-switch would delete the commitment device for every user who
enabled the setting, most of whom enabled it years ago for a reason an idle blink
never triggers.

Ignoring the flag is not available either. Tomo's reward beat flies coins across
the screen, its evolution transition morphs an entire character, and its Focus
route is a full-screen takeover. Those are precisely the motions the flag names.

Underneath the vestibular question sits a second, different need that the flag is
a poor proxy for. A permanently-animating character on the landing tab is a
**distraction** cost for some ADHD and autistic users — a population a Pomodoro
app actively attracts. That need is not vestibular, is not what the OS flag
reports, and is not served by anything in the graded response.

The cost of leaving that second need unaddressed is not a code cost. Under the
graded response, nothing in Tomo ever fully stills the pet, so no ticket
downstream would ever specify a still pose — and #9's character design, #23's
art spike and #16's Rive input contract would produce four evolution stages of
rigged art with no such state in them. Retrofitting it later means re-rigging
finished assets, not editing a widget.

## Decision

**The OS reduce-motion flag produces a graded response, not an off switch.**

Suppressed when the flag is on: coin fly-in (the balance changes instantly),
confetti (dropped entirely), EXP bar fill (jumps to its new value), route and
takeover transitions (cross-fade instead of slide), hatch and evolution
(cross-fade between stage art rather than morphing).

Retained when the flag is on: the pet's **in-place idle at reduced amplitude**.

**Every reward payload survives; only its choreography changes.** The user still
gets the coins, the EXP, the level-up, the new evolution stage, and the
announcement — what they do not get is the travel.

**Stillness is a separate control.** Settings → Pet gains a **Calm pet** toggle,
off by default, which reduces the pet to a static pose. It is orthogonal to the
OS flag: the flag governs choreography, Calm pet governs ambient movement.
Neither seeds nor overrides the other.

## Consequences

**The premise survives the flag.** A user with reduce-motion on still has a pet
that is alive, and still gets every reward the economy grants. The setting costs
them spectacle, not the commitment device.

**A still pose becomes a hard requirement on the art.** #9 must design one, #16
must expose it as a Rive input, and #23 must prove it riggable — while all three
outputs are still cheap to change. This is the whole reason the toggle is decided
now rather than deferred.

**Two knobs mean two things, and copy must keep them apart.** "Reduce motion" is
the OS setting Tomo reads; "Calm pet" is Tomo's own. Collapsing them in copy or
in code re-couples what this decision separated.

**The graded list is a checklist for six design tickets.** #12, #17, #18, #19,
#20 and #23 each own animations that must state their reduced form. An animation
whose reduced form is unstated is unfinished.

**Tomo is knowingly not honouring a literal reading of an accessibility flag.**
That is a defensible position, argued from what the flag is for — but it is a
position, and it belongs in the record rather than in a comment. If a user
reports vestibular discomfort from the idle itself, Calm pet is the answer, and
seeding it from the OS flag becomes the obvious revision.

## Alternatives considered

**Hard kill — no animation anywhere, static pet.** Unambiguous and trivially
testable, and honest about what it does. Rejected because it removes the
commitment device from the users who enabled the flag, in service of a threat
(an in-place blink) the flag was not written to address.

**Graded, and still the pet too.** The safest reading, and it serves the
distraction population in one move rather than two. Rejected because it silently
hands a dead pet to every user who set the flag for unrelated vestibular reasons,
and because it conflates two needs that a single toggle can then never separate.

**FX layer only — the Rive pet is exempt.** Simplest rule, protects the premise
absolutely. Rejected because the evolution transition is a full-character morph,
which is exactly the class of motion the flag exists to prevent.

**Seed Calm pet from the OS flag on first run.** Serves both populations by
default. Rejected because it re-couples the two knobs this decision separates,
and a seeded-then-editable setting is a state that is hard to explain and easy
to get confused about.

**Defer Calm pet to post-MVP.** Keeps Settings at its #5-settled size and avoids
a state no user has asked for. Rejected on cost location: the retrofit lands on
finished art and rigs, not on code, which is the one case where "add it later"
is materially more expensive.

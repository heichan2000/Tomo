# ADR-0012: The egg hatches on the first completed focus block, not during onboarding

- **Status:** Accepted
- **Date:** 2026-09-22
- **Decided in:** [#18 Onboarding & hatch flow design](https://github.com/heichan2000/Tomo/issues/18)
- **Amended by:** [ADR-0030](0030-each-pet-has-its-own-character.md) — the pick has no personality choice; each pet comes with its own character.
- **Amended by:** [ADR-0031](0031-choose-the-pet-by-its-egg.md) — the pick is of an egg, and the species stays hidden until the hatch.

## Context

The PRD says first-run is "minimal but real — it establishes the emotional hook
immediately", and every earlier ticket read "immediately" as *inside onboarding*:
pick, crack, name, done, all before the app is usable. #15 is the only document
that noticed the alternative, and it left the call here — "if a block can run
before hatch (#18's call), there is no name or species yet" — while writing a
"Your egg" notification fallback against the possibility.

The hatch is the single most replayed image of the product and the whole basis of
the bond. Onboarding is also the one moment where the user has done nothing yet.
Handing over the pet there makes the product's emotional centre the cheapest
thing in it: a reward paid before any work, on a screen the user taps through in
forty seconds.

Tomo's design north star is that EXP only *visualises* real progress — the real
reward is the user's actual task progress. An unearned pet is the one place that
claim is contradicted by the product's own first screen.

## Decision

**Onboarding ends with an egg, not a pet. The egg opens at the end of the first
focus block the user completes.**

Onboarding is two screens above the shell, once ever:

1. **The pick.** The three starters, plus the personality choice (#30 owns its
   content), in the neutral pre-hatch accent so no species colours the choice.
2. **The first task.** "What are you working on?" — one line, which becomes both
   the seeded project's name and the user's first task. Skippable; skipping
   falls back to #5's silent default project.

The user then lands on Home holding **that species' egg**. The species is chosen
and known from this point; only the name and the hatch are outstanding.

**The first block's default length is 15 minutes**, not 25. Block length
otherwise remembers last-used per #5; a brand-new user has no last-used, and this
is the initial value.

When that block settles, Focus plays its ordinary block Beat and then a
**full-screen takeover** — the only moment in Tomo that clears the screen. The
egg opens, the app's accent changes from the neutral grey to the species colour,
the pet speaks one line in its species voice, and a name field appears
**pre-filled with the species name**. *Done* dissolves back into Focus's
next-action choices.

Stopping a block early opens nothing and **never animates the egg shut**: the
crack is a projection of the running block, discarded with it, and the user next
sees the egg whole on a different screen.

## Consequences

- **A user who never completes a block never meets a pet.** This is accepted, not
  mitigated away. The 15-minute first block roughly halves the distance to it;
  nothing else is offered, because every backstop considered turned "earned" back
  into "delayed".
- **The pet has a voice before it has a name.** #15's pre-hatch fallback assumed
  neither species nor name was known. Species is known, so the "Your egg" title
  stands but the body uses that species' baseline copy.
- **A fifth celebratory beat exists**, rarer than the three-times-ever evolution:
  the hatch happens once. The map's reward-beat hierarchy is a five-way problem,
  and the new member is both the rarest and the only one with its own screen.
- **The accent is neutral for a whole session, not a screen.** #12 wrote the
  neutral pre-hatch accent expecting it to last seconds. It now dresses
  onboarding, Home and the entire first focus block, and its replacement is a
  chrome-wide change inside a Moment that #12's motion tiers do not cover.
- **A takeover stacks inside a takeover.** Focus is already a minimizable
  takeover (ADR-0003); the hatch opens above it. The running-block banner has no
  representation of this state.
- **New art that no budget counted**: three eggs and a crack sequence, on top of
  #9's twelve layer sets and eye sheets. → #23.
- **#16 gains a beat kind and a pre-hatch look.** The crack is derived from the
  live cycle's elapsed minutes — stored nowhere, the same class of thing as the
  countdown — and the hatch beat takes the same `seenAt` mark as every other, so
  a block that settles off screen waits for the banner tap and never hatches
  unseen.
- **#30's personality choice is answered before the user has met the pet**, which
  narrows what that choice can sensibly be made of.

## Alternatives considered

**Hatch during onboarding.** The reading every earlier ticket assumed, and the
only option where every user meets a pet. Rejected because it pays the product's
largest reward for nothing, on the one screen where the user has done no work —
and because the PRD's "immediately" is about the hook being *real*, which an
earned hatch serves better than a fast one.

**Hatch now, name later.** Splits the beats: meeting is free, the bond is earned.
Rejected because it leaves the pet nameless across Home and every notification,
and #15's copy is built on `{petName}`.

**No pick at setup — choose at the crack.** Would make onboarding a single screen
and put choice, reveal and naming together at the earned moment. Rejected because
it leaves the first session characterless and loads three jobs onto the payoff
screen; #9 also frames the choice as happening "once, before the relationship
starts".

**Let the crack persist across stopped blocks**, so nothing is ever lost.
Rejected: it contradicts #3's "a stopped block leaves no trace at all", and an
egg stuck permanently ajar is its own quiet nagging.

**A time backstop — the egg opens by itself after a few days.** Rejected because
it converts "earned" into "delayed", which is precisely the claim this ADR
exists to make true.

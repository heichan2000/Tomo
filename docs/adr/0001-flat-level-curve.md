# ADR-0001: A flat level curve — one level per hour of focus

- **Status:** Accepted
- **Date:** 2026-08-17
- **Decided in:** [#2 Reward economy: the numbers](https://github.com/heichan2000/Tomo/issues/2)

## Context

The PRD fixes the shape of the reward economy — reward is linear in completed
focus minutes, early stop grants zero, EXP is uncapped — but not the mapping
from cumulative EXP to level. Every convention in the genre says that mapping
should escalate: each level costs more EXP than the last, so early levels arrive
quickly and later ones are made to feel earned.

Tomo's north star cuts the other way. EXP and coins exist only to *visualize*
real progress; the real reward is the user's actual task progress. The PRD
already refuses decay, refuses neglect mechanics, and refuses functional or paid
gating behind progression, on the grounds that the app must never guilt the user
or replace the work with the game.

An escalating curve is in tension with that. It makes the user's tenth hour of
real focus buy visibly less level than their first, which means the level number
stops being a faithful readout of effort and starts being a pacing dial. That is
the grind archetype, arrived at by a different door than decay.

## Decision

**The level curve is flat: 600 EXP — exactly 60 completed focus minutes — per
level, forever.**

```
level(total_exp)  = floor(total_exp / 600) + 1
exp_for_level(n)  = (n - 1) * 600
```

At the settled rate of 10 EXP per completed focus minute, **a level is an hour
of focus**, permanently and at every point on the curve. Level is **derived from
stored EXP, never stored itself.**

Evolution stages ride on top of this at levels 1 / 10 / 40 / 100. Those
thresholds are the only non-linearity in the progression, and they are read-only
consequences of the level rather than a separate quantity.

## Consequences

**The level number cannot lie about effort.** "Level 40" means forty hours of
completed focus and will still mean that in three years. This makes the stats
screen's pet level and a hypothetical "hours focused" stat the same fact, which
issue #21 has to decide how to present.

**The uncapped-EXP story works without extra machinery.** The PRD wants a number
that keeps moving after the last evolution; a flat curve delivers one that keeps
moving at a *constant* rate, rather than one that asymptotically stalls. The
reference user is around level 237 at month six and still gains a level roughly
every focused day.

**Level numbers get large, and that is accepted.** There is no level cap and no
prestige reset. A multi-year user reaching level 1,000 is a feature of the
honesty, not an overflow to design around — 32-bit EXP tops out around 3.5
million levels.

**Level-ups stop being a scarce event.** For the reference user a level lands
roughly once per focused day, so the level-up cannot carry the weight of a major
beat. Evolution carries that weight instead, and the level-up should be designed
as a small, frequent metronome. This is an input to the focus-view and pet
prototypes (#17, #9).

**Reversing this is expensive.** Switching to an escalating curve later would
restate every existing user's level downward — a pet that was level 200
yesterday and level 36 today reads as the app taking something away, which is
exactly what grow-only promises never happens. Migration would need either a
grandfathering rule or an accepted breach of that promise. Treat the curve as
effectively permanent once shipped.

## Alternatives considered

**Gentle escalation (classic RPG).** Level 2 at ~20 minutes, each subsequent
level costing ~8 minutes more; the final evolution would land near level 36.
Familiar to every user, and it makes the opening minutes feel generous.
Rejected: later focus buying less level is the grind pattern the PRD's
no-decay / no-guilt stance exists to prevent.

**Two-phase — escalating through the arc, flat afterward.** Would give RPG
texture during the first three months and honesty after. Rejected: it has a
visible seam where the pace abruptly changes, and it is the harder curve to
explain in one sentence.

**Flat at 30 minutes per level.** Same honesty, twice the level-up frequency,
final evolution at level 200. Rejected: the level stops mapping to a unit anyone
can hold in their head, and "level = hours focused" is the property doing the
real work here.

# ADR-0010: The clock is quiet — rough minutes, exact on tap

- **Status:** Accepted
- **Date:** 2026-09-21
- **Decided in:** [#17 Focus view design](https://github.com/heichan2000/Tomo/issues/17)
- **Amended by:** [ADR-0016](0016-one-pixel-font-sharp-sizes.md) — there is no
  Fredoka and there are no tick cells. The tapped exact time is plain Ark Pixel
  text, whose digits all share one width. The rule itself is unchanged

## Context

Almost every Pomodoro app puts a large ticking countdown at the centre of its
focus screen. Tomo's visual design system (#12) specified the same: the Focus
timer in Fredoka XL, drawn in tick cells, and an exact countdown on the
running-block banner.

A large number that changes every second is the most attention-grabbing object
on the screen, and it trains the user to watch the clock. Tomo's focus screen is
meant to put the **pet** at the centre, and the whole commitment device is the
pet, not the countdown.

## Decision

**While a block or break runs, Tomo shows rough minutes, never a ticking
number.** The Focus route reads "about 19 min left" in muted callout text above a
thin progress line. **Tapping it shows the exact `mm:ss` for five seconds**,
drawn in tick cells, and then it returns to rough minutes.

The same rule applies everywhere time is shown during a cycle: the break state,
and the **running-block banner**, which reads "19 min left" and updates once a
minute. This **supersedes #12's banner spec** (exact countdown in tick cells).

Below one minute it reads "under a minute left".

## Consequences

- The pet, not the number, is the largest and liveliest thing on the Focus route.
- "How long have I got?" is still answered at a glance, and the exact figure is
  one tap away for anyone who needs it.
- Tick cells now serve only the tap-revealed exact time and the EXP count-up.
- The accessible label is unchanged in kind: minute-granular, read on demand,
  never a live region (#8). It now matches what is on screen.
- Anyone who wants a desk clock does not get one from Tomo. The trust model does
  not need one: the anchors, not the display, decide credit.

## Alternatives considered

**The big exact countdown, always** — familiar and expected from the category.
Rejected because it invites exactly the clock-watching a focus tool should
discourage, and it competes with the pet for the centre of the screen.

**No number at all, only a filling ring** — the purest version. Rejected because
people reasonably want to know roughly how long is left, and making them hunt for
it is friction with no benefit.

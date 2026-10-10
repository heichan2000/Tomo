# ADR-0026: No streak; Stats counts days focused instead

- **Status:** Accepted
- **Date:** 2026-10-07
- **Decided in:** [#21 Stats screen scope & the definition of a streak](https://github.com/heichan2000/Tomo/issues/21)

The PRD asks for a stats screen showing a "current streak". Tomo ships **no
streak**. In its place, Stats shows **days focused**: the number of *local
days* that hold at least one block record. One finished block of any length is
enough, and a block counts for the day it ends. The number only grows. A day
without focus costs nothing, and coming back adds one.

A streak that resets after a missed day is a loss, and grow-only rules out loss
everywhere else in Tomo: EXP never decays, the pet never sulks, a stopped block
leaves no trace, and #30 already bans streaks from Chatty lines because they can
go down. A streak on Stats would be the one number in the product that can be
taken away. Days focused still answers what the PRD wanted the streak for,
which is "I can see I keep showing up".

Stats shows four numbers, all derived from block records each time it opens
and none stored: **level, time focused, blocks finished, days focused**.

## Considered options

- **A normal streak** (days in a row, back to 0 after a missed day). Rejected:
  the one number on screen that can drop, at the moment the user already feels
  worst.
- **A streak with rest days** (one missed day a week is allowed). Rejected: it
  is gentler but can still break, and its rule is harder to explain than the
  loss it softens.
- **A streak hidden once it breaks.** Rejected: the user still sees it vanish.
  Silence about a loss isn't the same as having no loss.
- **A minimum per day** (say 25 minutes) for a day to count. Rejected: it adds
  a bar the user can fall just short of ("you did 20 minutes, and today doesn't
  count").

## Consequences

- With nothing that resets, a "my day ends at 2 am" setting isn't needed. The
  worst a late-night block can do is add one extra day.
- **Tasks finished is not on Stats.** Tasks are hard-deleted (ADR-0022) and can
  be reopened, so a count taken from the task list can drop. Only block records
  are guaranteed never to.
- **Stats is all-time only.** Today and week views, charts, time per project,
  records and comparisons are deliberately absent. A week strip shows gaps,
  which is a streak drawn as a picture.
- PRD story 43 is amended. "Streak" moves to the terms Tomo avoids in
  `CONTEXT.md`.

# ADR-0011: Auto-start begins the next block only on screen, after a visible countdown

- **Status:** Accepted
- **Date:** 2026-09-21
- **Decided in:** [#17 Focus view design](https://github.com/heichan2000/Tomo/issues/17)

## Context

#3 fixed what auto-start may do while the user is away: the projection walks a
cycle forward through its break and **halts at `breakComplete`**, because Tomo
never anchors a focus block into an absence. At most one block is credited per
absence.

That leaves the case #3 did not have to answer: the user is **watching** the
Focus route when the break ends. The projection still lands in `breakComplete`.
Whether the UI then issues `StartBlock` by itself is a presentation choice, and
it decides whether auto-start is worth having: the PRD offers it for people
running long planned loops, and a loop that needs a tap after every break is only
half chained.

## Decision

**When the break ends while the Focus route is on screen and auto-start is on,
Focus shows a 10-second countdown — "Next block starts in 10" — with *Start now*
and *Not yet*.** At zero, the UI issues an ordinary `StartBlock`, anchored from
that moment. *Not yet* cancels the countdown and leaves the cycle in
`breakComplete`.

"On screen" means the app is in the foreground **and** the Focus route is
visible. Minimised, backgrounded or locked, nothing starts: the cycle waits at
`breakComplete` exactly as #3 specifies, and the banner reads "Break over".

The Focus route **does not keep the screen awake**, so a phone left unattended
locks on its own timer and cannot chain blocks by itself.

When auto-start begins a break, Focus shows a one-line note: *"Break started on
its own. Auto-start is on (change it in Settings)."*

## Consequences

- The state machine is unchanged: no new state and no new transition. The
  countdown is UI calling an existing command, and the projection alone still
  decides credit.
- The absence rule from #3 holds wherever Tomo can tell the user is absent. The
  gap that remains is a user who walks away with the screen still on inside the
  phone's auto-lock window. That user is credited for a block they did not work,
  which the trust model already accepts ("gaming the timer only cheats the
  user").
- The countdown needs no confirmation to decline: *Not yet* is one tap, and the
  stop-early dialog is never used as a way of saying no.

## Alternatives considered

**Never start a block automatically; auto-start only chains a block into its
break.** Simplest, and it matches the absence rule exactly. Rejected because it
halves the feature for the people it exists for.

**Start instantly at break end, with no countdown.** Rejected because it drops
the user into a commitment with no moment to decline, which is the failure #3
rejected for returning users.

**Keep the screen awake during Focus**, so an on-screen countdown is more
reliable. Rejected: it burns battery to show a clock ADR-0010 keeps quiet, and it
would make unattended chaining *more* likely rather than less.

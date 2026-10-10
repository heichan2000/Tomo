# ADR-0003: Focus is a minimizable takeover, not a locked one

- **Status:** Accepted
- **Date:** 2026-08-18
- **Decided in:** [#5 Screen inventory & navigation model](https://github.com/heichan2000/Tomo/issues/5)
- **Amended by:** [ADR-0029](0029-mvp-ships-without-ai-and-never-goes-online.md) — the shell has two tabs, Home and Work; there is no chat to reach. The takeover rule is unchanged.

## Context

PRD story 12 asks for "a focus view that hides everything else, so that I can
concentrate on one thing at a time." Read plainly, that describes a locked
takeover: once a block is running, the app offers no way back to the task list,
the pet, or chat. The only door out is *Stop early* — which, per
[ADR-0001](0001-flat-level-curve.md) and `CONTEXT.md`, is confirmed and grants
exactly zero.

That reading is attractive because the lock *is* the product. Tomo's whole
mechanism is that a block has a real stake; a focus screen you can wander away
from looks like a focus screen that isn't serious.

Two things already settled in this repo argue the other way.

**The trust model.** `CONTEXT.md` states that Tomo does not detect or penalise
app-switching, and [#3](https://github.com/heichan2000/Tomo/issues/3) built the
entire timer around that: anchors are wall-clock instants, the countdown is a
derived convenience, and a user who backgrounds the app for the full block
duration is credited in full on return. The user may already leave for any other
app on the device at zero cost. A lock therefore does not prevent leaving — it
only prevents leaving *within Tomo*.

**The precedent on which dialog gets used for what.** #3 rejected retroactive
auto-start chaining partly because returning into a silently-started block
"would force Stop Early — the dialog built for abandoning real work — as the way
to decline." A locked takeover repeats that mistake at a higher stake: a user
who wants to check a note in their own task list mid-block must either kill the
block for zero, or leave the app entirely and come back.

## Decision

**Entering Focus is a full-screen takeover that hides the tab bar and every
other surface.** The app never volunteers a way out; nothing about the default
posture is softened.

**A deliberate `Minimise` action returns to the app**, leaving a persistent
**running-block banner** docked above the tab bar — task name and remaining time
— visible on all three tabs. Tapping the banner re-enters Focus.

**Minimising ends nothing.** The cycle is untouched: anchors stand, the
scheduled notification stands, `project(cycle, now)` is unaffected. *Stop early*
remains confirmed and remains the only way to end a running block.

Android hardware back from `focusRunning` **is** minimise. It never raises the
stop-early confirmation.

## Consequences

**The stake is unchanged.** Nothing about reward depends on the focus view being
on screen — #3 made that structurally true by deriving everything from anchors.
Minimise moves pixels, not credit. A minimised block completes, credits, and
plays its beat exactly as a watched one does.

**The punishing case disappears.** Glancing at your own data no longer costs a
block. This matters most for the user Tomo is for: someone mid-task who
remembers a detail they wrote down, whose alternative under a lock is to break
focus *harder* by leaving for another app.

**The banner becomes shared surface area.** It is the app's only persistent
cross-tab element, so it belongs to the design system (#12) rather than to any
one screen, and it is the fourth entrance to Focus alongside Home's *Start
focusing*, task detail's *Start focusing*, and a non-`idle` cold-start
projection.

**"Hides everything else" is honoured as a default, not a cage.** The user who
never taps minimise gets precisely story 12's experience. The affordance is
there for the user who needs it, and using it is an explicit act.

**Focus stops being a modal dead end for navigation purposes**, which keeps the
back stack ordinary on Android and removes any need for back-press interception
beyond routing it to minimise.

## Alternatives considered

**Locked takeover — Stop early is the only exit.** The purest reading of story
12, and the strongest signal that a block is serious. Rejected on coherence: it
forbids the cheapest form of leaving while the trust model explicitly tolerates
the most complete form, so it punishes the user for staying in the app. It also
conscripts the abandon-your-work dialog into service as a navigation control, a
pattern #3 already rejected once.

**Locked, but with a read-only peek** — a swipe-down that reveals the task list
without leaving Focus. Preserves the lock while solving the punishing case.
Rejected as more machinery for less: it needs a second, restricted rendering of
the task list with its own rules about what is tappable, and it still cannot
serve a user who wants to reach chat or settings. Minimise is one affordance
that covers every case.

**No takeover at all** — Focus as an ordinary pushed route with the tab bar
visible. Rejected outright: it discards story 12 entirely, and the visual
removal of everything else is a real part of why a block feels like a
commitment.

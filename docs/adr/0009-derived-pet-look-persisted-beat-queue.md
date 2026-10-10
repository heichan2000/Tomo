# ADR-0009: The pet is two channels — a derived look and a persisted beat queue

- **Status:** Accepted, amended by [ADR-0018](0018-pixel-pets-slide-whole-pixels-flicker-evolution.md)
  (`look` holds the old stage only while an evolution is pending; `movement` is
  `full` / `reduced`)
- **Date:** 2026-09-17
- **Decided in:** [#16 Pet animation controller contract](https://github.com/heichan2000/Tomo/issues/16)

## Context

Tomo has a settled house style for state: **derive it, never manage it.** #3
replaced the focus cycle's event machine with a pure `project(cycle, now)`, so
that a live completion and one reconciled days later are literally the same code
path. #15 did the same for notifications — `syncNotifications(cycle, now,
isForeground)` recomputes the whole pending set rather than scheduling and
cancelling by hand, which is why a stale notification cannot fire. In both cases
the argument was identical: a snapshot plus a pure function has no memory to
corrupt, and no second code path to fall out of sync.

The pet is the first thing in Tomo that does not fit.

Its **sustained appearance** fits perfectly. Which evolution stage it is showing
follows from the level; which of #9's seven faces it wears follows from the
timer state, the AI's state, and the *Calm pet* setting; how much it moves
follows from *Calm pet* and the OS reduce-motion flag. All of that is a pure
function of a snapshot, and gets one.

Its **celebrations** do not fit at all. "You just levelled up" is an edge, not a
state. Nothing in a snapshot of the app says *this just happened*: level 10 and
level 10 look identical whether the user crossed it a second ago or a week ago.

The obvious repair is to derive the edge instead of the state — hold the previous
snapshot, compare it to the current one, and play whatever changed. This is
where the house style actually breaks, and it breaks on the exact case #3 exists
to protect. A block that completes while the app is shut credits on the *next*
launch, inside the settling transaction. At that moment there is no previous
snapshot: the process is new. The diff has nothing to compare against, so the
user who focused for fifty minutes yesterday reopens the app, silently gains
five hundred EXP, and is shown nothing.

There is a second, smaller problem hiding behind the first. Once a celebration
exists only in memory, killing the app between the credit and the animation
destroys it permanently — the credit is on disk and will never be recomputed, so
nothing will ever queue the beat again. The user earned the reward and can never
be shown it.

## Decision

**The pet is driven by two channels.**

**Channel 1 — the look.** `look(state, pending)` returns the stage, the face, the
movement level and the species. Pure, no memory, recomputed freely. The face is a
**single value resolved off one ordered ladder** rather than a set of independent
flags, so contradictory faces are not expressible and there is no set of illegal
combinations to enforce.

**Channel 2 — the beat queue.** An ordered queue of momentary celebrations,
**written by the settling transaction alongside the credit**, not diffed by the
UI. Beats play in order, one at a time, never overlapping.

**A `seenAt` mark beside `creditedAt`.** `seenAt` is set when a run finishes,
when the user skips it, or when the user leaves. Only process death leaves it
unset. On launch, any block that is credited but not seen regenerates its whole
run. This is #3's exactly-once trick applied a second time: `creditedAt` makes
the *grant* never-lost and never-doubled, and `seenAt` does the same for the
*beat*.

**`look` reads the queue.** The level rises inside the settle, before any
celebration plays, so the plain derivation would have the pet already at stage 2
when the evolution beat starts — nothing left to cross-fade from. Rather than
letting the celebration draw its own pet, `look` reports the *old* stage while an
evolution is pending or playing.

## Consequences

**The bend in the house style is smaller than it looks.** The queue is not a
second source of truth; it is **derived from the block row**, the same way the
focus cycle's state is derived from the anchors. Its persistence is a nullable
timestamp, not a job table. A reader who knows #3 already knows this shape.

**Exactly one function answers "what is on screen".** This is the whole reason
`look` reads the queue rather than yielding the pet to the celebration for the
duration. Two drawers with overlapping authority flicker the instant they
disagree, and the disagreement window here is a three-second animation. It also
means the evolution lag survives process death for free: the beat is still
pending after a relaunch, so the pet is still stage 1, with no extra rule.

**The schema grows by one column, and `seenAt` inherits the row's lifetime.** #3
established that the cycle row is deleted only on exit to `idle`. `seenAt` lives
and dies with it, which is what makes "an unseen beat is dropped when the user
ends the cycle" fall out of the design rather than needing a rule of its own. The
settle must also record enough to rebuild the run — the EXP granted, and the
pet's total after the grant.

**A celebration can still be missed, and that is accepted.** #5 sited the reward
beat on the Focus route and only there, so nothing arbitrates between two
surfaces. A user whose block completes while minimised, and who then ends the
cycle without returning to Focus, never sees the beat. The EXP is theirs
regardless. The alternatives were to let Home's pet also play it — which reopens
#5 — or to yank the user into Focus unasked, which the trust model forbids.

**Celebrations are skippable, and leaving counts as seeing.** A Moment dims the
chrome for up to three seconds and a level-up run reaches six, at exactly the
moment a user might want to start the next block. Tomo does not hold the user in
place, so a tap ends the run and marks it seen — and so does walking away. Only
an involuntary loss earns a replay.

**The contract is a Dart object, so it is testable by construction.** `look` is a
pure function over an enum ladder, and the queue is a list. "The face is never
two things at once", "an evolution never plays before its cross-fade source",
"a credited block is never celebrated twice" are unit assertions, not device
tests. This was #29's stated reason for preferring plain Flutter over a binary
rig format, and it is cashed in here.

## Alternatives rejected

**Diff consecutive snapshots.** Maximum purity, one channel, nothing persisted —
and silently broken on cold start, which is the case #3's entire reconciliation
design exists to serve. Rejected on correctness, not taste.

**An imperative controller the app pokes** (`pet.celebrate()`,
`pet.setStage(3)`). Closest to the Rive-input framing this ticket was originally
written against, and the reason it was written that way. It makes every surface
that renders a pet responsible for keeping it in sync, which is the class of bug
`project(cycle, now)` was introduced to abolish.

**Let the celebration draw its own pet during an evolution.** Simpler to write,
and it removes the queue argument from `look`. Rejected because it creates two
things with authority over the same pixels, with a three-second overlap window.

**Merge a stacked run into one composed moment**, or **let the rarest beat
swallow the others**. Both are attractive and both may still be right — but they
are decisions about how the celebrations *look*, and the reward-beat hierarchy is
still open on the map. Playing them in order is the option that decides the
plumbing without deciding the choreography, and either merge remains available
later without changing this contract.

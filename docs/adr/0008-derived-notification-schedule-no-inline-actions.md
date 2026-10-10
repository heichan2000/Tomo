# ADR-0008: The notification schedule is derived, and notifications carry no actions

- **Status:** Accepted
- **Date:** 2026-09-17
- **Decided in:** [#15 Notification content & platform configuration](https://github.com/heichan2000/Tomo/issues/15)

## Context

Tomo sends exactly three **timer notifications** — block complete, block
complete with the break already begun (auto-start), and break complete — and
nothing else. They are the only channel Tomo has to a user who has left the app,
and `CONTEXT.md` already fixes that they are a convenience derived from the
anchors, never a source of truth for reward.

[#3](https://github.com/heichan2000/Tomo/issues/3) made the focus cycle a pure
projection, `project(cycle, now)`, with no resume or tick events, precisely so
that the most bug-prone logic in the app has one code path instead of two. Two
obvious notification designs would quietly undo that.

**Imperative scheduling.** Schedule at `StartBlock`, cancel at `StopEarly`,
reschedule at `TakeBreak`, and so on. "No stale notification ever fires" then
depends on every one of six call sites remembering to cancel — and Android,
unlike iOS, cannot suppress a scheduled notification at presentation time, so a
user watching the reward beat would also get a banner sliding over it.

**Inline actions.** *Take break*, *Mark done* or *Start another* on the
notification itself. An action that runs without opening the app runs in a
background isolate that must open the database, project, settle if owed, apply
a command and reschedule — a second path into the state machine, which is the
resume path #3 abolished.

## Decision

**The pending notification set is a function, not a history:**

```
syncNotifications(cycle, now, isForeground)
desired = isForeground ? {} : this cycle's timer notifications still in the future
```

It is idempotent, makes the OS's pending set equal `desired`, and is called on
every cycle write and every app lifecycle change. Each notification kind has a
**fixed id**, so replacement is automatic and a new cycle overwrites the old.
Coming to the foreground also clears every *delivered* Tomo notification.

**No notification carries an action.** A tap opens the app, carrying only the
cycle's `startAt`: if that cycle is still live, Focus is un-minimised;
otherwise it is a plain resume.

**Platform configuration is fixed as follows, and is hard to reverse:**

- Android channels `focus_block_v1` ("Focus block finished") and `break_v1`
  ("Break finished"), both `IMPORTANCE_HIGH`, system default sound, lock-screen
  visibility `PRIVATE` with a public version that omits the task name. A later
  custom sound ships as a `_v2` channel with the `_v1` channel deleted.
- Android declares **`USE_EXACT_ALARM`** under Play's "alarm or timer app"
  category, falling back to `SCHEDULE_EXACT_ALARM` if review rejects the claim.
  Each sync picks exact-while-idle if `canScheduleExactAlarms()`, otherwise
  inexact-while-idle. `setAlarmClock` is never used.
- iOS categories `focusBlock` and `break`, no actions, all three notifications
  `timeSensitive` (so they pass through the Focus modes a Pomodoro user is most
  likely to be in), default sound, one `focusCycle` thread, no provisional
  authorisation.

## Consequences

"No stale notification ever fires" and "no banner while the app is open" become
assertions over `(cycle, now, isForeground)` — unit-testable without a device —
rather than properties of call-site discipline.

The reward beat keeps its single site. Every route back to a completed block
goes through Focus, so a user can never return already in `breakRunning` having
missed the celebration of the block that earned it, and the task-completion
Moment can never fire unseen.

A phone-down user must unlock and open Tomo to start a break. The break then
begins when they actually start resting, which is the honest instant.

If the process dies in the foreground without a lifecycle callback, nothing is
scheduled. The block still credits on next open; only the convenience is lost.

A user's per-channel customisations reset once if a `_v2` channel ever ships.

## Alternatives considered

**Schedule once at `StartBlock`, cancel imperatively; suppress in foreground on
iOS only.** Less code on day one. Rejected: Android still flashes a banner over
the beat, and cancellation hygiene is spread across every command.

**Inline actions that act in the background.** Saves one unlock. Rejected for
the second state-machine path, the unseen reward beat and completion bonus, and
per-platform background handlers testable only by manual script.

**Actions that merely open the app.** Indistinguishable from a tap, so they add
buttons without adding capability.

**One channel, or `DEFAULT` importance.** One channel denies users the realistic
"tell me when the block ends, let me rest in peace" split for free. `DEFAULT`
could never be raised later, whereas a user can always lower `HIGH`.

**`SCHEDULE_EXACT_ALARM` as the primary route, or inexact only.** On Android 14+
the former is denied by default and granted only via a special-access settings
page most users will not visit; the latter lets a face-down, dozing phone
deliver the block-end alert minutes late.

# ADR-0013: Tomo plays no audio; haptics are its only physical channel

- **Status:** Accepted
- **Date:** 2026-09-22
- **Decided in:** [#22 Sound & haptics spec](https://github.com/heichan2000/Tomo/issues/22)
- **Amended by:** [#107 The timer buzz feels like a bump on Android](https://github.com/heichan2000/Tomo/issues/107)
  — on Android the timer buzz is one real 250 ms buzz, run by `MainActivity`
  through a platform channel and obeying the phone's notification vibration
  (spec §17 C157). `vibrate()` there is the long-press feedback, which a
  Samsung plays as a short bump hard to tell from the reward tap. iPhone keeps
  `vibrate()`. The rest of this decision is unchanged.

## Context

The PRD's hook is that the reward moment feels good, and until this ticket the
product had no audio or haptic specification at all — `CONTEXT.md` contained not
one term for either. The obvious reading is that a product built on a felt
reward needs sound, and that the question is only whether sound defaults on.

That framing turns out to be wrong, because two earlier decisions had already
settled most of it without naming it.

**#15 gave the OS the case that matters.** The three timer notifications use
`UNNotificationSound.default` on iOS and `HIGH`-importance channels on Android,
so a phone that is face-down on a desk — the whole point of a Pomodoro timer —
*already* makes a sound and vibrates when a block ends. That is the case where
audio is load-bearing, and Tomo does not own it.

**#15 also suppresses notifications in the foreground**, by deriving the
schedule from `isForeground`. So Tomo's *own* audio could only ever play while
the app is open and on screen — which is to say, while the user is already
looking at the reward.

What remains for in-app audio is therefore a narrow job: accompanying a
celebration the user is watching. Against that narrow job stand the real costs —
an audio session category and its ducking behaviour on two platforms, sound
assets with licensing and file size, a settings surface, and the standing risk
that a focus tool which makes noise is a focus tool people mute. The
overwhelmingly common case is a user with music or a podcast already playing.

Haptics answer the same job better. They work face-down on a desk, they survive
the silent switch and Do Not Disturb, they cost no assets, and Flutter exposes
them with no third-party package — which #7's no-extra-dependencies posture
makes worth something on its own.

## Decision

**Tomo plays no audio, ever.** No audio session on either platform, no sound
assets, no audio dependency, no settings row for sound. The only sound Tomo
causes is the OS notification tone on #15's three timer notifications, which
stay OS-default — so #15's channels stay `focus_block_v1` and `break_v1`, and
the `_v2` migration it reserved against a custom sound is not needed.

**Haptics are the only physical channel, and there are exactly two of them.**

| | Fires | Primitive |
|---|---|---|
| **Reward tap** | each beat, as it plays | `HapticFeedback.lightImpact()` |
| **Timer buzz** | a block or break ends while Tomo is open and no beat will play | `HapticFeedback.vibrate()` (on Android, a real buzz since #107) |

**Never two for one event.** Which one fires is *derived*, in the same shape as
#15's `syncNotifications` and #3's projection:

```
haptic(event, isForeground, beatWillPlay) =
  beatWillPlay  → reward tap
  isForeground  → timer buzz
  otherwise     → none   (the OS notification already vibrates)
```

Three-way and exhaustive. Backgrounded is silent *by Tomo* precisely because it
is not silent by the OS.

**The reward tap is uniform across all five beat kinds** — `blockCredited`,
`levelUp`, `evolution`, `taskCompleted`, `hatch`. The screen differentiates a
hatch from an ordinary block; the hand does not. One tap per beat, so a beat run
taps once per beat at the queue's own spacing.

**No Tomo settings row**, following #15's ruling on lock-screen privacy: a
toggle that duplicates an OS control can disagree with it. On Android it would
disagree *silently*, because the system touch-feedback setting gates the API
Tomo calls and Tomo cannot read it from Dart.

## Consequences

**No moment may rely on a haptic as its only channel.** Android can swallow
every haptic Tomo fires via a setting it cannot see, so anything that buzzes
must also be visible. This is a standing constraint on #17, #19 and #20.

**The reward moment's physical vocabulary is one tap.** That is deliberately
less than the product could express, and it keeps the reward-beat hierarchy
(still fog) free to differentiate the four Moments visually without having to
keep a parallel haptic vocabulary in step.

**`UINotificationFeedbackGenerator` is unreachable.** Flutter exposes five
primitives — `vibrate`, `lightImpact`, `mediumImpact`, `heavyImpact`,
`selectionClick` — and not Apple's success/warning/error family, which is the
one designed for exactly "the thing you were waiting for finished". Accepted
rather than worked around, because working around it means a package or a
platform channel for one tap. (On Android, #107 did add a platform channel, for
the timer buzz: `vibrate()` felt like a bump there, so the one haptic meant to
reach someone not looking failed at its job. The reward tap still needs none.)

## Alternatives rejected

**Sound on by default, with the ringer switch as the mute.** The strongest
alternative: route audio through iOS's `ambient` category and Android's ringer
stream, so anyone who silences their phone to focus is silenced automatically
and no setting is needed. Rejected because it still buys an audio session on two
platforms, assets, licensing and size, to serve only the foreground case where
the user is already watching the screen.

**Sound shipped but off by default.** Rejected as the worst of both: all of the
cost, and the reward moment silent for nearly everyone, since users do not go
looking in Settings for a feature they do not know exists.

**Sound that plays over silent** (`playback` category). Rejected outright:
someone silenced their phone on purpose.

**A haptic vocabulary graded by rarity** — a light tap for a block, a firmer one
for a level-up, a short rhythm for an evolution or hatch. Rejected because it
answers a question the reward-beat hierarchy owns, and answering it here means
two channels that must later be kept in step.

**One tap per beat run** rather than per beat. Rejected because the evolution
and hatch reveals — four such moments in the product's entire life — would then
land with no haptic at all, the block's tap having fired seconds earlier.

**A Tomo haptics toggle.** Rejected per #15's precedent, above.

# ADR-0019: Celebrations are a ladder, and they twinkle in pet pixels

- **Status:** Accepted
- **Date:** 2026-10-01
- **Decided in:** [#39 Pixel reward effects](https://github.com/heichan2000/Tomo/issues/39)
- **Resolves:** the *reward-beat hierarchy* fog on
  [Wayfinder: Tomo build-ready MVP spec](https://github.com/heichan2000/Tomo/issues/1)
- **Amends:** [ADR-0018](0018-pixel-pets-slide-whole-pixels-flicker-evolution.md)
  (the flicker is five swaps, and the hatch does not flicker)
- **Amended by:** [#40 Draw Geode](https://github.com/heichan2000/Tomo/issues/40)
  — the shell rule made exact (see *Amendment* below); [#81 Which celebrations
  play after a long first block, and after a task bonus?](https://github.com/heichan2000/Tomo/issues/81)
  — the two runs that stack, see *Consequences*

## Context

Tomo has five beats, at very different rates: a block done (several a day), a
level-up (about daily), a task done (a few a week), an evolution (three times
ever) and the hatch (once). The old map kept "how do they differ, so the common
ones don't cheapen the rare ones" open for months. Every ticket narrowed it
without answering it. #12 put four of them in one *Moment* tier. #9 gave three of
them the same `Celebrating` face. #22 made every beat the same haptic tap. So any
difference has to be visual, and it has to survive reduce motion and skipping.

The pixel look then needed every effect redrawn anyway: whole pixels, no fades,
and a flash limit shared with the evolution flicker.

## Decision

**A ladder: the rarer the beat, the bigger, and each one keeps everything the
commoner one has.**

| Beat | Adds |
|---|---|
| Block done | Pleased bob, "+EXP" rises, the bar lights block by block. **Nothing around the pet.** |
| Level-up | Dither, a "Level N" plate, the bar refilling, **six sparkles**. |
| Task done | **Confetti**, plus three sparkles. One step above level-up because it is rarer. |
| Evolution | Sparkles closing in, the flicker **alone**, then **a wave of large sparkles** and confetti. |
| Hatch | The egg **shakes**, then the **shell breaks apart** with the pet already there (no flicker), two rings of large sparkles, the most confetti, and the pet's colour arrives with the burst. |

**The style is Twinkle: four-point sparkles that open and close in place.** They
never travel. Chosen over **Burst** (rings and rays, the loudest) and **Rise**
(floating bits and a column of light, the busiest screen).

**Effects are drawn in pet pixels**, on the pet's own grid, not in UI pixels. A
sparkle's pixel is the same size as the pet's.

**Sparkle colours are the accent plus a lighter colour of the same pet.**
Confetti uses the pet's own colours that show on that ground.

**Nothing flashes.** Sparkles open and close but never blink on and off as a
block, so the evolution flicker is the only flashing thing on screen, and it plays
with nothing else moving.

**The flicker is five swaps** (0, 500, 950, 1350, 1700 ms). It must be odd to
end on the new stage. #37's page did seven, with four of them inside its last
second, which broke the three-a-second rule.

**The hatch does not flicker.** The egg shakes three times, the last time harder
and faster, then breaks open with the pet already there. The user asked for
this after seeing the flickering hatch: the breaking shell is the change, so the
flicker would say the same thing twice. The flicker is now only for evolution.
Under reduce motion the hatch is still the 0.6 s cross-fade.

**Reduce motion** keeps the ladder: confetti and the flying shell are dropped,
the bar jumps, evolution and hatch cross-fade, and the **sparkles stay, held
still and cross-faded**. Because they never travel, Twinkle is the one style
whose differences survive the flag.

## Consequences

- The ladder answers the hierarchy with what is *around* the pet, since the face,
  the haptic and the Moment tier are shared. Skipping still lands on the payload,
  and the reduced forms still differ from each other.
- Effects are painted from small text grids on the pet's grid, alongside the
  pet. They are not Lottie clips. The tech-stack doc's "Lottie / Flutter
  animations" line for incidental FX is out of date.
- Each pet's egg must break along the shell rule (seven pieces cut by angle
  around the egg's centre). The Draw tickets draw eggs that break cleanly that way.
- Task done is a live beat on its own tap, so it never shares a run with a
  block's beats. It can still be followed by a level-up and an evolution when
  its bonus reaches them ([#81](https://github.com/heichan2000/Tomo/issues/81)),
  so the ladder does stack those: *Task done*, then *Level up*, then evolution.
- The hatch is never followed by a level-up, even when the first block was long
  enough to reach level 2 ([#81](https://github.com/heichan2000/Tomo/issues/81)).

## Alternatives considered

**Burst** — rings and short rays, like an old game's level-up. The boldest, but
everything in it travels, so reduce motion leaves nothing.

**Rise** — bits floating up, and a column of light for evolution and the hatch.
Soft, but it fills the most screen.

**Effects in UI pixels** — finer, but two pixel sizes sit side by side around the
pet.

**Sparkles in the accent only**, or **in all the pet's colours** — flatter, or
too close to confetti.

**A sparkle on every block** — would make level-up the second appearance of
something, not the first.

## Amendment: the shell rule, made exact (#40)

- **Where the cuts meet.** The seven pieces are cut by angle around the centre
  of the egg's bounding box (Geode's: 24.0, 32.5).
- **What flies.** The dark of the crack flies off with the shell, as its
  inside. Only the pet's own colours stay: the peeking eyes. Each egg lists them
  (`staysAtHatch`, [ADR-0020](0020-pixel-art-as-text-grids-in-code.md)).
  Leaving the dark behind made 1–2-pixel slivers; with it every piece is solid.
- **Keep the centre plain.** A crack or mark where the cuts meet is chopped
  into single pixels, so Lily's crack sits two rows higher (#42).
- **The last crack shows the eyes peeking**, like the Tomo egg, so the user
  sees their pet is nearly here and the eggs and the app icon read as one
  family.

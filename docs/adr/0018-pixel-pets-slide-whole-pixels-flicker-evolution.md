# ADR-0018: Pixel pets slide their parts in whole pixels, and evolution flickers

- **Status:** Accepted
- **Date:** 2026-10-01
- **Decided in:** [#37 How pixel pets move](https://github.com/heichan2000/Tomo/issues/37)
- **Amended by:** [ADR-0029](0029-mvp-ships-without-ai-and-never-goes-online.md) — *Thinking* and *Puzzled* are parked with the AI layer, so the lean has no trigger in the MVP. Their eye drawings and lean steps stay in the art files.
- **Supersedes:** the layered-SVG animation in
  [#29 Pet animation runtime & authoring pipeline](https://github.com/heichan2000/Tomo/issues/29)
- **Amends:** [ADR-0009](0009-derived-pet-look-persisted-beat-queue.md) (when
  `look` holds the old stage, and the `movement` values)
- **Amended by:** [ADR-0019](0019-reward-ladder-twinkle-in-pet-pixels.md) — the
  flicker is **five swaps** (0, 500, 950, 1350, 1700 ms), so it ends on the new
  stage and never has more than three in a second; and **the hatch does not
  flicker** (the egg shakes, then breaks open with the pet there). The flicker
  is for evolution only

## Context

#29 chose layered SVG moved by Flutter, under "one skeleton, many skins": six
parts (`body`, `head`, `eyes`, `limbA`, `limbB`, `accent`), with every movement
written once and shared by all twelve pet stages. Evolution was a cross-fade
between layer sets.

Pets are now pixel art on a 48×48 grid, drawn at whole screen dots per pixel
([ADR-0014](0014-starter-sprites-one-grid-whole-screen-dots.md)), and the chrome
moves in whole pixels with no fades ([ADR-0017](0017-quiet-steps-pixel-chrome.md)).
Pixel art cannot be rotated or scaled smoothly without smearing, and the
smallest movement there is is one pixel. The head tilt, the reduced-amplitude
idle that [ADR-0005](0005-graded-reduce-motion.md) asks for, and the evolution
cross-fade all had to be re-decided.

## Decision

**Parts slide in whole pixels.** Each stage is drawn once, split into the six
parts. Every movement is a part, or the whole pet, jumping from one whole-pixel
position to the next and holding there. Nothing moves smoothly between
positions. The only extra drawings are **one eye sheet per species**, shared by
all four stages. "One skeleton, many skins" survives.

**The head leans instead of tilting.** Thinking and Puzzled slide the lower head
one pixel and the top two, with the step always above the eyes.

**Reduce motion means one pixel at most.** With the OS flag on, nothing moves
more than one pixel and the breath runs at half speed. Calm pet acts only
through the face, as ADR-0005 and #16 already said.

**Evolution and the hatch flicker.** Old and new swap back and forth, faster
each time, and the new one stays. **Never more than three swaps in any one
second**, which is the general flash threshold. It takes 2 s. Under reduce
motion it is a 0.6 s cross-fade, the one fade ADR-0017 allows.

**ADR-0009 stays, with two amendments:**

- `look` holds the old stage only while an evolution beat is **pending**. When
  the beat starts, `look` reports the new stage, and the pet plays the flicker
  as its own change of stage. The pet flickers whenever its stage changes on
  screen, egg to stage 1 included. Skipping jumps straight to the new stage.
- `movement` is `full` or `reduced`. The old `none` value (Calm pet) is
  removed, because under Calm pet, Celebrating, Thinking and Puzzled still move.

## Consequences

- The Draw tickets deliver, per stage, art **split into the six parts**, with
  the pixels behind every moving part painted in. They also deliver one eye
  sheet per species. Whole-pose drawings are not needed.
- Every movement and timing is shared code over the parts, so it can be
  unit-tested the way ADR-0009 promised.
- The flicker is the pet's own work, not a reward effect. *Pixel reward
  effects* dresses it but doesn't draw the pet, so there is still one thing
  deciding what is on screen. Any flashing effect it adds has to fit inside the
  same three-swaps-a-second limit together with the flicker.
- The flicker cap is a hard rule, not taste. Speeding it up later reopens the
  flashing risk.

## Alternatives considered

**Whole drawings per pose.** The classic sprite approach. Rejected because it
multiplies the art by every pose across twelve stages, and it loses the shared,
testable movement code.

**A drawn tilted head per stage.** Looks best once cleaned up, but it adds
twelve drawings for two faces that only show while the AI is busy or away.
**A one-pixel lean** reads as a lean, not a tilt. **Eyes only** puts the whole
face on a 2×2 eye for Joe.

**Grow up** (the new stage replacing the old row by row from the ground) was the
recommendation for evolution. The user preferred the flicker's game feel.
**Dissolve** looked noisy. **A plain cross-fade** breaks the no-fades rule
outside reduce motion.

**Lopsided Puzzled eyes** (the old style guide's "eyes uneven") were rejected:
no face is lopsided on any pet.

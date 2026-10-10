# ADR-0017: Quiet steps — pixel chrome drawn in UI pixels

- **Status:** Accepted
- **Date:** 2026-10-01
- **Decided in:** [#38 Pixel interface kit](https://github.com/heichan2000/Tomo/issues/38)
- **Supersedes:** the component, shape and motion parts of
  [#12 Visual design system](https://github.com/heichan2000/Tomo/issues/12)
  (three radii, the flat tinted scrim, smooth slides and fades)

## Context

Everything in Tomo is now pixel art ([#32](https://github.com/heichan2000/Tomo/issues/32)):
the pet ([ADR-0014](0014-starter-sprites-one-grid-whole-screen-dots.md)), the
font ([ADR-0016](0016-one-pixel-font-sharp-sizes.md)), and now the chrome. #12's
chrome was built from smooth radii, a separate display face and soft motion,
and none of those survive a pixel grid.

Two things had to be settled. The first was how heavy pixel chrome should look:
pixel UIs usually lean on outlines or bevels, and either can make the chrome as
busy as the pet. The second was what dims the screen behind a sheet in dark,
because #12's 45% dark tint does nothing to true black
([ADR-0015](0015-light-and-true-black-accent-from-the-pet.md)).

The prototype, *Tomo Pixel Kit*, drew every part three ways, in both themes and
for every pet: **quiet steps** (shade only), **ink frames** (a 1-pixel outline
on every box) and **raised blocks** (a solid ledge under everything pressable).

## Decision

**The chrome is drawn in UI pixels.** One UI pixel is one font pixel of body
text (about 1.5–1.7 pt). Lines, corners, gaps, icon strokes and movement are all
whole UI pixels. UI pixels stay fixed when the phone's text size changes. Only
text grows.

**Quiet steps.** Shapes stand apart by shade alone, as #12 intended. Nothing has
an outline except a text field, which needs one to be seen. Every corner loses
exactly one pixel, which replaces #12's three radii. There are no shadows and no
ledges.

**One playful part: the EXP bar is 20 blocks** that light up one by one. It is a
reward object, and the motion rule already lets reward objects be livelier than
the chrome.

**Behind sheets and dialogs, a pixel dither:** every other dot is covered with
the ground colour, in both themes. No tint, and no extra line on the sheet.

**Movement snaps to whole UI pixels.** The four motion tiers keep their
timings. Slides move in whole UI pixels and nothing fades. A pressed button
changes shade at once. Only the pet and reward objects may spring. Under reduce
motion, sheets cross-fade (ADR-0005).

**Type steps.** Each role is a whole number of dots per font pixel, set from
body: caption is body − 1, title body + 1, the pet's name 2 × body. Body is
about a 10 pt x-height (18 pt on 2× phones, 20 pt on 3×). The pet's name, like
numbers, stops growing at 130% of the phone's text setting and steps down
rather than wrap.

**Icons** sit on a 12 × 12 grid with 1-pixel lines, drawn at one UI pixel per
icon pixel. Outline icons for everyday use. Filled icons for the selected tab,
because Ark has no bold and a label can't show selection.

## Consequences

- *Calm chrome, warm pet* survives. The pet is still the only detailed, lively,
  saturated thing on screen. The chrome's warmth now comes from the ground
  colours and one-pixel corners, since there's no separate display face.
- Three pixel sizes share a screen: the pet's (about 4 pt on Home), the text's
  and the chrome's (about 1.5 pt). That's accepted. Chrome and text match each
  other, and the pet is meant to stand out.
- Button height is the label's line plus equal padding, rounded so it's at
  least 48 pt. Text is never centred to a half dot.
- The dither's checks have to start on whole dots, or they go grey. This needs a
  check on a real 2.625× phone, alongside ADR-0016's text check.
- A disabled control is a solid grey box with grey text, never see-through, so
  nothing blends through a pixel edge.
- The EXP bar fills one block at a time. Each block is 30 EXP, three minutes of
  focus, so a 25-minute block lights about eight. How the fill plays as a beat
  is *Pixel reward effects*' to design.

## Alternatives considered

**Ink frames.** A 1-pixel frame on every box, corners rounded in two steps,
like a classic game window. Rejected because the frames add dozens of lines
around the pet, and in dark the light frames glow on black.

**Raised blocks.** A solid two-pixel ledge under buttons and cards, which press
down onto it like keys. Rejected because the chrome then feels like a toy too,
and competes with the pet. Its block EXP bar was kept.

**Darken behind sheets (#12's tint, black at 60% in dark).** It still dims the
pet and cards, but black stays black, so dark sheets need a top line to show
where they start. Rejected in favour of one rule that works the same on both
grounds.

**Fade behind sheets.** Washes the screen toward the ground. Rejected because it
reads as a soft, non-pixel effect.

**Smooth movement.** Modern glides and fades. Rejected because edges go soft
mid-slide. **Choppy movement** (a few big jumps) was rejected as too old-game for
a focus app.

**Caption sized on its own target.** On 2× and some other phones it rounds to
the same size as body. Fixing caption one step below body rules that out.

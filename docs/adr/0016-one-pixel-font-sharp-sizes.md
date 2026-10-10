# ADR-0016: One pixel font, Ark Pixel, snapped to sharp sizes

- **Status:** Accepted
- **Date:** 2026-09-27
- **Decided in:** [#35 Pixel fonts](https://github.com/heichan2000/Tomo/issues/35)
- **Supersedes:** the typography part of [#12 Visual design system](https://github.com/heichan2000/Tomo/issues/12)
  (system body face plus Fredoka display, and tick cells)

## Context

Every line of text in Tomo is pixel type, by choice ([#32](https://github.com/heichan2000/Tomo/issues/32)).
That includes body text, chat and task notes. Most pixel fonts are made for
game titles: caps only, tiny, or missing punctuation. And a pixel font only
looks sharp when each font pixel covers a whole number of screen dots, the same
rule [ADR-0014](0014-starter-sprites-one-grid-whole-screen-dots.md) sets for
the pet. Flutter can't turn off text anti-aliasing, and the phone's text-size
setting (up to 200% under [#8](https://github.com/heichan2000/Tomo/issues/8),
non-linear on Android 14+) produces sizes that almost never land on whole dots.

The evidence is in [`docs/research/2026-09-27-pixel-fonts.md`](../research/2026-09-27-pixel-fonts.md).
The user compared the candidates by eye on the *Tomo Pixel Fonts* page.

## Decision

**All of Tomo's text uses one font: Ark Pixel 12px Proportional, regular.**
That covers body text, captions, headings, the pet's name, the tapped exact
time and the EXP count-up.

- **Headings stand out by size alone.** Ark has no bold, and Tomo never asks
  for one. Flutter would fake it by smearing the strokes. A pixel font's
  strokes get thicker as it grows, so a bigger heading already reads heavier.
- **Text always snaps to a sharp size.** The font is drawn on a 12-pixel em,
  so a size is sharp when `fontSize = 12 × n / devicePixelRatio` for a whole
  number `n` (dots per font pixel). A custom `TextScaler` wraps the system
  scaler, **after** any clamp, and picks `n`. At 100% it rounds to the nearest
  `n`. Above 100% it **rounds up**, so text is never smaller than the user
  asked for. Line height is set in whole font pixels (`height = L / 12`, 16
  being the font's own line), so lines stay on the grid.
- **Numbers that change don't need tick cells.** Ark's digits are all 6 font
  pixels wide, so a changing number holds still as a plain `Text`.
- **A time or number never scrolls or wraps.** Display numerals still clamp at
  1.3× (#8), then snap. If that size doesn't fit the width, it steps down to
  the largest sharp size that does.
- **Shipped as a Latin subset** (about 27 KB), bundled and never fetched. The
  subset keeps ASCII, Latin-1, Latin Extended-A and typographic punctuation. The
  font is OFL with no reserved name, so subsetting is allowed. Its licence is
  registered with `LicenseRegistry`.
- **Characters the font lacks** (emoji, non-Latin scripts, and a few symbols
  such as `€`) fall back to the phone's own font. That is accepted.

## Consequences

- One font file, one grid, one set of snapping rules. The snapping scaler
  needs to know only one em size.
- Layouts must allow text to come out about 10–25% bigger than the nominal
  scaled size, because snapping rounds up. #8's "scroll rather than squeeze"
  rule absorbs this.
- The type scale (which sizes each role uses) is set in whole dots per font
  pixel by the *Pixel interface kit*, not here.
- Emoji and any non-Latin text look smooth next to pixel text. English-only
  MVP ([#8](https://github.com/heichan2000/Tomo/issues/8)) keeps this rare.
- `CONTEXT.md`'s *tick cell* is retired.
- Flutter doesn't guarantee that centred or oddly padded text starts on a whole
  dot. A line that starts a quarter dot off goes slightly soft. This needs a
  check on a real 2.625× Android phone during the build.

## Alternatives considered

**Departure Mono for the timer and live numbers.** The user first picked it
when the sample page wrongly showed a big ticking timer. Under the quiet clock
([ADR-0010](0010-quiet-clock.md)) it would only draw the 5-second tapped time
and the EXP count-up. Ark's digits already hold still, so a second font wasn't
worth it. The user chose one consistent font.

**Departure Mono for headings.** More personality, especially for the pet's
name. Rejected in favour of the main font at a bigger size, for consistency.

**Pixeloid Sans, Bold and Mono.** The only family with a true bold, and all
three styles share one grid. Rejected because its curly apostrophes look like
backticks, and iOS keyboards and the AI chat put curly apostrophes everywhere.
It remains the fallback if Ark fails on a device.

**Pixel Operator.** Free for any use (CC0). Rejected because it lacks most of
Latin Extended-A, so names like Łukasz fall back mid-word, and its size steps
are coarse on 2× phones.

**Pixelify Sans, sized smoothly.** It scales to any size. Rejected because it
isn't drawn on a pixel grid, so it's never fully sharp, and its uneven digits
would bring tick cells back.

**Smooth sizing (no snapping).** Use exactly the size the phone asks for.
Rejected because most sizes then fall between dots and the edges go grey,
which breaks the crisp-pixel look the pet already follows.

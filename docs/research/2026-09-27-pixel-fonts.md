# Pixel fonts for every line of text: candidates, crisp sizes, and Flutter scaling

**Research date: 2026-09-27.**

> **Outcome.** The user chose **Ark Pixel 12px Proportional for all text**,
> headings by size, always snapped to sharp sizes (rounding up above 100%).
> Departure Mono was dropped. See [ADR-0016](../adr/0016-one-pixel-font-sharp-sizes.md)
> and [#35](https://github.com/heichan2000/Tomo/issues/35).

> **Snapshot warning.** Font files change. Ark Pixel shipped a release two days
> before this was written (2026.09.25). Pixeloid reached 1.0 in December 2025.
> Every number below was **measured from the font file named in that row**
> (fontTools 4.62.1, Pillow 12.1.1) on 2026-09-27. A newer release may differ,
> so re-measure before you bundle a file. The Flutter engine behaviour is quoted
> from `main` at the commits linked, and could change too.

## Why this exists

Tomo has chosen pixel type for **all** text: headings, numbers and long text
(chat, task notes, settings). That choice is settled. This document looks at
the three things that decide whether it works:

1. **Long-text readability.** Most pixel fonts are made for game titles. They
   come caps-only, with tiny x-heights or missing punctuation.
2. **Scaling.** A pixel font is only sharp when each font pixel covers a whole
   number of screen dots. That is the same rule [ADR-0014](../adr/0014-starter-sprites-one-grid-whole-screen-dots.md)
   sets for the pet. The #8 baseline (200% OS text scaling, display numerals
   clamped at 1.3×) produces sizes that fall between those steps.
3. **Digits.** Fredoka had no tabular figures, so the design used *tick cells*
   (`CONTEXT.md`). If a font's digits all share one width, tick cells can go.

The document gathers evidence and ends with a **recommendation for the user to
judge by eye**. It is not a decision.

## How each font was measured

- **Pixel grid.** A true pixel font draws every outline point on a grid of
  *N font units per pixel*. N was found as the common step between outline
  coordinates, then checked by hand on `H x p d`. From N: em in pixels =
  `unitsPerEm / N`, plus cap height, x-height and descender in pixels.
- **Digits.** `hmtx` advance widths of `0`–`9` and `:`, and the GSUB/GPOS
  feature list (for `tnum`).
- **Coverage.** `cmap` checked against ASCII, Latin-1 (U+00A0–00FF, 96),
  Latin Extended-A (U+0100–017F, 128), and a list of specific characters.
- **Specimens.** Rendered with Pillow for a by-eye check. The PNGs sit outside
  the repo.

## Comparison table

"px" means font pixels (design grid), not screen pixels. Every row was measured
from the release named in the first column, fetched from the source linked in
its per-font note.

| Font (version) | Licence | Bytes | Styles | Grid: units/px → em | Cap / x / desc (px) | Long text? | Latin-1 · Ext-A | ‘’ “” — … | Digits |
|---|---|---|---|---|---|---|---|---|---|
| **Ark Pixel 12px Proportional** (2026.09.25) | OFL, no RFN | 3,521,916 (27,084 subset) | Regular only | 100 → **12** | 9 / 6 / 2 | **Yes**, kerned | 95/96 · **128/128** | All present | **All 6 px**, colon 4 |
| Ark Pixel 10px Proportional (2026.09.25) | OFL, no RFN | 369,344 (24,616 subset) | Regular only | 100 → 10 | 7 / 5 / 2 | Yes, kerned | 95/96 · 128/128 | All present | All 5 px |
| **Pixeloid Sans** (1.0) | OFL, RFN "Pixeloid" | 117,564 | Sans, **Bold**, **Mono** on one grid | 204 → **9** | 7 / 5 / 2 | Yes, kerned | **96/96 · 128/128** | Present, but ’ ” look like backticks | **All 6 px**, colon 2 |
| **Pixel Operator** (2018.10.04) | **CC0** | 17,272 | Regular, Bold, Mono, "8", HB, SC | 100 → 16 | 9 / **7** / 2 | Yes, no kerning | 84/96 · **34/128** | Present | **All 7 px**, colon 5 |
| **Departure Mono** (1.500) | OFL, no RFN | 84,480 | Regular only | 50 → 11 | 8 / 6 / 2 | Monospaced | 96/96 · 127/128 | All present | All 7 px (monospaced), `tnum` |
| Pixelify Sans (1.000) | OFL | 79,160 | Variable `wght` 400–700 | **Not a grid** (≈80–102 units/step) → ≈11 | ≈7 / 5 / 2 | Yes, kerned, tight | 94/96 · 126/128 | Present | **Unequal** (404 vs 586 units), no `tnum` |
| Monogram Extended (1.1.0) | CC0 | 55,952 | Regular (+ italic file) | 64 → 16 | 7 / 5 / 2 | Monospaced | 95/96 · 127/128 | Present | All 6 px (monospaced) |
| Monocraft (4.2) | OFL | 210,192 | Many weights + italics | 120 → 9 | 7 / 5 / **1** | Monospaced, 1-px descenders | 95/96 · 109/128 | Present | All 6 px |
| Galmuri11 (2.404) | OFL, no RFN | 5,376,428 (58,756 subset) | Regular, Bold, Condensed | 100 → 12 | 11 / 8 / 2 | Yes, but I l \| nearly identical | 96/96 · 128/128 (**Bold: 0/128**) | “…” drawn as centred CJK dots | 6 vs 8 px, has `tnum` |
| m5x7 | CC0 ("attribution appreciated") | 34,300 | Regular | 64 → 16 | 7 / 5 / 2 | Yes | 95/96 · 127/128 | **All missing** | All 6 px |
| m6x11 | "free to use with attribution" | 13,068 | Regular | 64 → 16 | 11 / 8 / 3 | Yes | **27/96 · 0/128** | **All missing** | All 7 px |
| VT323 (2.000) | OFL | 153,116 | Regular | Rounded "CRT" dots, 80 units → 12.5 | 7 / 5 / 2 | Monospaced | 96/96 · 127/128 | Present | All 5 px |
| DotGothic16 (1.100) | OFL | 2,069,236 | Regular | 62.5 units, grid **offset 0.45 px** from baseline → 16 | — | Yes | 96/96 · **10/128** | Present | Monospaced |
| Silkscreen (1.001) | OFL | 32,220 | Regular, Bold | 125 → 8 | 5 / = caps / **0** | **No:** lowercase are copies of caps | 96/96 · **7/128** | Present | Unequal |
| Press Start 2P (3.000) | OFL, RFN | 118,204 | Regular | 125 → 8 | 8×8 cell, hhea descent 0 | **No:** heavy, display only | 96/96 · 125/128 | Present | All 8 px |
| Tiny5 (1.002) | OFL | 132,124 | Regular | 128 → 8 | 5 / 4 / 1 | No: micro labels | 95/96 · 128/128 | Present | All 4 px |
| Micro 5 (1.001) | OFL | 53,936 | Regular | 150 → 11 | 5 / 4 / 1 | No: micro labels | 84/96 · 99/128 | Present | 3–4 px, has `tnum` |
| Jersey 10 (1.001) | OFL | 77,732 | Regular | 75 → 18.67 | 10 / 8 / 2 | No: condensed display | 84/96 · 99/128 | Present | 4–8 px, has `tnum` |
| Bytesized (1.000) | OFL | 20,792 | Regular | 2 (UPM 16) → 8 | 3 / 2 / 1 | No: novelty | 88/96 · 100/128 | Present | All 4 px |

"Subset" means the file cut down to Latin plus general punctuation, arrows,
€ and ™ with `fontTools.subset`, keeping all layout features. Only Ark Pixel
and Galmuri need it. Both are OFL with no Reserved Font Name (see
[Licensing](#licensing-and-bundling)).

**Rare everywhere:** ✓ (U+2713) is present only in Pixeloid. U+2007 FIGURE
SPACE is present only in Monogram. Arrows ← ↑ → ↓ are present in Pixeloid, Ark Pixel, Departure Mono, Monogram,
Monocraft, Galmuri, Press Start 2P, Tiny5 and DotGothic16. They are missing in
Pixel Operator, Pixelify Sans, VT323, Silkscreen, Micro 5, Jersey 10 and
Bytesized. Ark Pixel lacks € (U+20AC).

**Considered but not inspected:** Fusion Pixel
([TakWolf](https://github.com/TakWolf/fusion-pixel-font), a CJK-heavy superset
of Ark Pixel), Cozette ([MIT](https://github.com/slavfox/Cozette)), Spleen
([BSD-2](https://github.com/fcambus/spleen)) and Pixel Code
([OFL](https://github.com/qwerasd205/PixelCode)). All four are monospaced
terminal or code faces. **Zpix** was ruled out on licence: its
[README](https://github.com/SolidZORO/zpix-pixel-font) prices a single
commercial product at **USD $1000**.

## Per-font notes

### Ark Pixel 12px Proportional: the cleanest long-text face

[TakWolf/ark-pixel-font](https://github.com/TakWolf/ark-pixel-font), release
[2026.09.25](https://github.com/TakWolf/ark-pixel-font/releases/tag/2026.09.25).
Actively maintained. This release ships 10 px and 12 px, each in monospaced and
proportional variants. The "latin" file is a *locale glyph variant*, not a
Latin-only subset. It still carries 24,279 glyphs, including CJK. That is why
it weighs 3.5 MB, and why subsetting takes it to 27 KB.

- By eye at an x-height of about 10 pt: open, even spacing. I, l, 1 and |
  are all distinct (serifed I, tailed l, flagged 1). 0 has a dot and O does
  not. Quotes and dashes are correctly shaped. The em dash is a true 11-px
  bar. Of all the fonts inspected, this one reads most like ordinary text.
- Line metrics: hhea ascent 13 px, descent 3 px, gap 0, so the natural line
  is 16 font px. Both ends are whole font pixels.
- **Regular weight only.** No bold. In pixel type, emphasis mostly comes from
  size (see [the size-is-weight note](#a-practical-strategy)). A faux bold
  would smear by fractional dots.

### Pixeloid Sans / Bold / Mono: one grid, three styles

By GGBotNet, [itch.io page](https://ggbot.itch.io/pixeloid-font) ("Mono, Sans,
and Sans Bold", 1141 glyphs, OFL, v1.0). The file measured is v1.0 from the
[FontSpace mirror](https://www.fontspace.com/pixeloid-font-f69232), because
itch.io downloads need a browser. The [dafont copy](https://www.dafont.com/pixeloid-sans.font)
is an older 0.4 build without Mono.

- **All three styles share one grid**: em 9 px, cap 7, x-height 5,
  descender 2. So one crisp-size rule covers body, bold headings and mono
  numbers. No other candidate offers a true bold on the same grid, except
  Pixel Operator.
- Full Latin-1 and Latin Extended-A, arrows, kerning, and a `salt` feature.
- **Two things to judge by eye:**
  1. **’ and ” are drawn slanting the "wrong" way.** They look like a backtick
     or grave accent, so "it’s" reads as "it\`s". This matters because iOS
     text fields curl typed apostrophes by default ([`smartQuotesType`
     defaults to true, iOS only](https://api.flutter.dev/flutter/material/TextField/smartQuotesType.html)).
     LLM chat output is also full of ’. The font has a Reserved Font Name, so
     redrawing those glyphs means shipping a renamed font.
  2. **The lowercase r has a spur.** In "report" it can read as a small k.
     Mono uses small-cap-style i, l and m to fill its cells, so it suits
     numbers, not prose.
- Wide set: the average lowercase advance is 5.58 px on a 9-px em (0.62 em).
  At an 18-lp body size that is about **32 characters per 358-lp line**, and
  about 16 at 2×.

### Pixel Operator: CC0 and tiny, but coverage gaps

By Jayvee Enaguas (HarvettFox96), CC0 ([Font Library](https://fontlibrary.org/en/font/pixel-operator),
last updated 2019-03-16). The file measured came from [dafont](https://www.dafont.com/pixel-operator.font)
(internal version 2018.10.04). Its LICENSE.txt is the full CC0 1.0 text. The
original NotABug repository now returns "Page Not Found", so the font is
effectively unmaintained.

- **The largest x-height of the set**: 7 of a 9-px cap. Very legible at small
  sizes. Tabular 7-px digits in the proportional face.
- **Latin Extended-A 34/128.** Ł, ź and many Polish, Czech and Baltic letters
  are missing. Flutter would draw those from the system font in the middle of
  a word (see [Fallback](#fallback-for-emoji-and-other-scripts)). No arrows, no
  kerning, and a fractional hhea lineGap (72 units = 0.72 px).
- Em 16 means coarse steps: at 3× only every 5.33 lp is crisp (see the
  scaling table).

### Departure Mono: the display and timer face

By Helena Zhang, [rektdeckard/departure-mono](https://github.com/rektdeckard/departure-mono),
[v1.500](https://github.com/rektdeckard/departure-mono/releases/tag/v1.500).
OFL with no RFN. The richest OpenType set of the candidates: `tnum`, `pnum`,
`onum`, `frac`, `smcp`, `case`, `ss01`, `ss02` and more. The grid is em 11,
cap 8, x-height 6.

It is monospaced, so digits, colon and space are all 7 px. That makes it wide
for prose (about 31 characters per line at body size) but steady for numbers
and headings. One useful coincidence: **88 lp on an 11-px em is exactly 8 lp
per font pixel**, which is a whole number of dots on every listed DPR (see
below).

### Pixelify Sans: pixel-styled, not pixel-gridded

By Stefie Justprince, [eifetx/Pixelify-Sans](https://github.com/eifetx/Pixelify-Sans),
file from [google/fonts](https://github.com/google/fonts/tree/main/ofl/pixelifysans).
The outline steps vary from 80 to 102 units, with 10-unit notches, and a
variable weight axis moves the stems. **No size is ever perfectly crisp.** On
the other hand, no size is "wrong" either, so it scales smoothly through
every OS text size. Tight default spacing: letters nearly touch in the
specimen. Digits are unequal and there is no `tnum`, so tick cells would stay.
This is the fallback if the user decides snapping is not worth it.

### The rest, briefly

- **Monogram** ([datagoblin](https://datagoblin.itch.io/monogram), CC0).
  Monospaced, 5-px-wide letters, good punctuation. A timer candidate; wide for
  prose. The file was inspected from a third-party GitHub copy, because itch
  needs a browser download.
- **m5x7 / m6x11** ([managore](https://managore.itch.io/m5x7), [m6x11](https://managore.itch.io/m6x11)).
  m5x7 has no curly quotes, dashes, ellipsis or bullet, so every iOS
  apostrophe would fall back to the system font. m6x11 has only 127 glyphs
  and requires attribution. Both rejected.
- **Galmuri** ([quiple/galmuri](https://github.com/quiple/galmuri), OFL).
  Korean-first. Its Latin I, l and | are nearly identical, and its ellipsis is
  a centred CJK "···". Galmuri11 Bold has **no** Latin Extended-A.
- **VT323** ([google/fonts](https://github.com/google/fonts/tree/main/ofl/vt323)).
  Every "pixel" is a rounded blob built from quadratic curves (1,180 curve
  segments across 28 sample glyphs), imitating a CRT. It will never look crisp.
- **DotGothic16** ([google/fonts](https://github.com/google/fonts/tree/main/ofl/dotgothic16)).
  Its 62.5-unit grid sits 28 units (0.45 px) below the baseline, so the glyph
  edges never line up with a baseline snapped to a whole dot. It is also
  2 MB, with Latin Extended-A 10/128.
- **Silkscreen, Press Start 2P, Tiny5, Micro 5, Jersey 10, Bytesized**
  ([google/fonts](https://github.com/google/fonts/tree/main/ofl)). Display
  faces or micro-label faces: caps-only, cell-based, or with an x-height of
  4 px or less. Unfit for chat or notes. Silkscreen or Jersey 10 could serve
  as a heading accent.

## The scaling problem

### The rule

For a font whose design pixel is *N* units on a *UPM* em, let
`E = UPM / N` (em in font pixels). At a logical `fontSize` S on a screen of
device pixel ratio *d*:

    dots per font pixel  n = S × d / E
    crisp  ⇔  n is a whole number
    crisp sizes          S = E × n / d      (n = 1, 2, 3 …)

This is ADR-0014's rule applied to type. **Only lp-per-font-pixel values that
are multiples of 8 are crisp on every DPR in the brief**, because
2.625 × 8 = 21, 2.75 × 8 = 22 and 3.5 × 8 = 28. That works for display sizes
(the 88-lp timer). At body sizes, 8 lp per font pixel is far too large, so
body text has to be snapped **per device**.

### What Flutter actually does with a glyph

The engine source settles this. Impeller is the only renderer on iOS and the
default on Android API 29+ ([Flutter docs](https://docs.flutter.dev/perf/impeller)).

- **Anti-aliasing cannot be turned off for text.** Glyphs are rasterised with
  `Edging::kAntiAlias`, `Hinting::kSlight` and `setSubpixel(true)`
  ([typographer_context_skia.cc](https://github.com/flutter/flutter/blob/3da669fae7033e0357514bca59fa3d0277ecbae3/engine/src/flutter/impeller/typographer/backends/skia/typographer_context_skia.cc#L265-L268)).
  The request to allow it has been open since 2019
  ([flutter#39690](https://github.com/flutter/flutter/issues/39690)). A user
  reported that setting `paint.setAntiAlias(false)` in the engine "doesn't make
  any difference for rendered text".
- **Horizontal glyph positions are quantised to ¼ device pixel.** There are
  four subpixel buckets, 0, .25, .5 and .75
  ([text_frame.cc](https://github.com/flutter/flutter/blob/c3586de2286ff1eabeb7af43a4e9d42a938142ec/engine/src/flutter/impeller/typographer/text_frame.cc#L75-L111)).
- **The non-subpixel axis is rounded to a whole pixel.** With `AxisAlignment::kX`,
  the y adjustment is 0.5 before `Floor()`, so the **baseline lands on a whole
  device pixel**
  ([text_contents.cc](https://github.com/flutter/flutter/blob/90fcfdf4e9df2d71f5175ec26d2e1424286b5368/engine/src/flutter/impeller/entity/contents/text_contents.cc#L180-L239)).

Taken together, anti-aliasing never hurts a pixel font as long as every edge
falls exactly on a dot boundary. **Vertically** that happens whenever *n* is
whole, because the baseline is snapped. **Horizontally** it also needs every
glyph advance to be whole dots, which again means *n* is whole. It further
needs the line to *start* on a whole dot. Centred or fractionally padded text
can start at .25, .5 or .75, which softens every vertical edge by that
fraction. That residual cannot be fixed from the font. It has to be checked
on a device.

### What OS scaling does to the numbers

These are ordinary sizes run through the rule. The base sizes were picked so
that each face's x-height is about 10 lp. "→" means rounded to the nearest
whole *n*.

| Face (E) · base | DPR | 1.0× | 1.15× | 1.3× | 1.5× | 1.75× | 2.0× |
|---|---|---|---|---|---|---|---|
| Pixeloid (9) · 18 lp | 2 | 4 ✓ | 4.6→5 (1.25×) | 5.2→5 (1.25×) | 6 ✓ | 7 ✓ | 8 ✓ |
| | 2.625 | 5.25→5 (0.95×) | 6.04→6 | 6.83→7 | 7.88→8 | 9.19→9 | 10.5→10 (1.90×) |
| | 3 | 6 ✓ | 6.9→7 (1.17×) | 7.8→8 (1.33×) | 9 ✓ | 10.5→10 (1.67×) | 12 ✓ |
| | 3.5 | 7 ✓ | 8.05→8 | 9.1→9 | 10.5→10 | 12.25→12 | 14 ✓ |
| Ark 12px (12) · 20 lp | 2 | 3.33→3 (0.90×) | 3.83→4 | 4.33→4 | 5 ✓ | 5.83→6 | 6.67→7 (2.10×) |
| | 2.625 | 4.38→4 (0.91×) | 5.03→5 | 5.69→6 | 6.56→7 | 7.66→8 | 8.75→9 (2.06×) |
| | 3 | 5 ✓ | 5.75→6 (1.20×) | 6.5→6 (1.20×) | 7.5→8 (1.60×) | 8.75→9 | 10 ✓ |
| Pixel Operator (16) · 21.3 lp | 3 | 4 ✓ | 4.6→5 (1.25×) | 5.2→5 (1.25×) | 6 ✓ | 7 ✓ | 8 ✓ |
| | 2 | 2.67→3 (1.12×) | 3.07→3 | 3.47→3 (**1.12×**) | 4 ✓ | 4.67→5 | 5.33→5 (1.88×) |

Three findings follow:

1. **The relative step is 1/n.** A face whose body text uses more dots per
   font pixel (a coarser design, i.e. a smaller E) scales in finer steps.
   Pixeloid at 3× moves in 17% steps. Pixel Operator at 2× moves in 33% steps,
   so 1.0×, 1.15× and 1.3× all collapse to the same size.
2. **On Android 14+, scaling is not linear.** Flutter's `TextScaler` exists
   because "larger text gets scaled at a lesser rate as compared to smaller
   text" ([breaking-change doc](https://docs.flutter.dev/release/breaking-changes/deprecate-textscalefactor);
   [Android 14](https://developer.android.com/about/versions/14/features#non-linear-font-scaling)).
   Android's own table maps **18 sp → 30 dp and 24 sp → 36 dp at the 200%
   setting**, and interpolates between the points
   ([FontScaleConverterFactory.java](https://android.googlesource.com/platform/frameworks/base/+/refs/heads/main/core/java/android/content/res/FontScaleConverterFactory.java),
   read via the GitHub mirror). So the scaled size is an arbitrary decimal and
   almost never lands on a crisp step by itself.
3. **How visible is an in-between size?** In the simulated specimen (unhinted
   area coverage), n = 6.25 adds a ¼-dot grey fringe to some edges, and on a
   ~460-ppi screen it barely shows. At n = 3.25 or 2.625 the fringe is a
   larger share of each pixel and the text looks soft. **Blur matters at small
   n and disappears at large n.** The display numerals (n ≈ 20–30) never need
   snapping to look sharp. Body text (n ≈ 4–7) does.

One caveat that cannot be measured off-device: Impeller asks for *slight*
hinting. How the platform rasteriser treats slight hinting at in-between sizes
(FreeType on Android, CoreText on iOS) may differ. Check on real phones.

### A practical strategy

**Can a custom `TextScaler` snap sizes to steps? Yes.** `TextScaler` is a
public abstract class with a `const` constructor. A subclass implements
`double scale(double fontSize)` and the deprecated `textScaleFactor` getter.
It inherits `clamp()` and should override `==` "to avoid unnecessary rebuilds"
([source](https://github.com/flutter/flutter/blob/cbb7a618809ee9dfb525ca6ea28044e016718ae7/packages/flutter/lib/src/painting/text_scaler.dart#L9-L75);
[API](https://api.flutter.dev/flutter/painting/TextScaler-class.html)). The
contract only asks that equal inputs give equal outputs, and it explicitly
allows two sizes to map to the same output
([`scale`](https://api.flutter.dev/flutter/painting/TextScaler/scale.html)).
Snapping is legal.

One way it could look. This is a sketch, not a design:

- At the app root, wrap the system scaler:
  `snap(system.clamp(...))`. **Snapping must be outermost.** `clamp` returns
  `maxScaleFactor × fontSize`, and 1.3 × 88 = 114.4 is not a crisp size.
- `scale(s)`: take the system result `t`, find `n = t × dpr / E`, round it,
  and return `n × E / dpr`. The scaler has to know `E` and `dpr`, so it holds
  them. If Tomo uses two faces with different E, the scaler also needs to know
  which face a base size belongs to. A **single-grid family** (Pixeloid, or
  one Ark size) avoids this entirely.
- **Round up, not to nearest, when the scale is above 1.0.** Otherwise a user
  who asked for 200% can get 190% (Pixeloid on 2.625×). Rounding up gives at
  least what was asked, and at most one step more, so layouts must allow about
  +10–25% over the nominal size. At 1.0× round to nearest (ADR-0014 rounds
  down for the pet, and underfilling is fine there).
- **Line height.** A null `TextStyle.height` uses the font's own metrics. A
  set height makes the line "exactly `fontSize * height` logical pixels"
  ([TextStyle.height](https://api.flutter.dev/flutter/painting/TextStyle/height.html)).
  Because `fontSize = E × n / dpr`, choosing `height = L / E` makes every line
  exactly *L* font pixels at *every* size. For example, Ark 12 at `16/12` is
  its native line; `18/12` is airier. With an even split of the extra leading,
  the baseline stays on the grid.
- **Size is weight.** A pixel font's stroke is one font pixel, so at twice the
  size the stroke is twice as thick. Headings get heavier just by being on a
  larger *n*. That softens the lack of a bold in Ark Pixel.

**The alternative is to not snap.** Accept fractional *n* everywhere, or use
Pixelify Sans, which is never exactly on grid anyway. That is simpler, and
honest at large sizes. The specimen shows the cost at small *n*.

## Digits and tick cells

Tick cells exist because Fredoka's digits vary in width (`CONTEXT.md`,
[ADR-0010](../adr/0010-quiet-clock.md): they now serve only the tap-revealed
`mm:ss` and the EXP count-up). The advance widths measured:

| Face | Digit advance | Colon | `tnum`? | Tick cells needed? |
|---|---|---|---|---|
| Ark Pixel 12px Prop | all 6 px | 4 px | no (not needed) | **No** |
| Pixeloid Sans | all 6 px | 2 px | no (not needed) | **No** |
| Pixeloid Mono | all 6 px | 6 px | — | **No** |
| Pixel Operator | all 7 px | 5 px | no (not needed) | **No** |
| Departure Mono | all 7 px | 7 px | yes | **No** |
| Monogram | all 6 px | 6 px | — | **No** |
| Micro 5 / Jersey 10 / Galmuri | unequal by default | — | **yes** | No, if `FontFeature.tabularFigures()` is set |
| Pixelify Sans | 404 vs 586 units | 222 | **no** | **Yes** |
| Silkscreen | 5 vs 6 px | 3 px | no | **Yes** |

The rendered widths confirm it. `25:00`, `11:11`, `19:59` and `00:07` measure
**the same** in every "No" face (for example, 312 dots each in Pixeloid Sans).
In Pixelify Sans they are 342, 246, 318 and 342 dots. With any of the
recommended faces, **tick cells can be retired.** A live number is then just a
`Text`. For fonts that have `tnum` but whose default digits are proportional,
`FontFeature.tabularFigures()` turns it on
([API](https://api.flutter.dev/flutter/dart-ui/FontFeature/FontFeature.tabularFigures.html)).

## Fallback for emoji and other scripts

Flutter tries `fontFamily`, then `fontFamilyFallback` in order. "If all font
families are exhausted and no match was found, the default platform font family
will be used instead", and as a last resort "a box will be drawn in its place"
([fontFamilyFallback](https://api.flutter.dev/flutter/painting/TextStyle/fontFamilyFallback.html)).
In practice:

- **Emoji** always come from the system colour emoji font. They will look
  smooth beside pixel text, and that cannot be avoided.
- **Missing Latin letters** (Pixel Operator's Ł and ź, Ark's €) fall back to
  the system sans *mid-word*. That is why Latin Extended-A coverage weighs
  more than its size suggests: users type names.
- **CJK and other scripts** fall back to the system font too. If pixel CJK
  ever matters, the unsubsetted Ark Pixel or Fusion Pixel files can sit in
  `fontFamilyFallback`, at a cost of megabytes.

## Licensing and bundling

- **OFL clause 2:** bundled copies must carry the copyright notice and the
  licence (quoted from the Ark Pixel `OFL.txt`). In Flutter that is one
  `LicenseRegistry.addLicense` call
  ([API](https://api.flutter.dev/flutter/foundation/LicenseRegistry-class.html)).
- **Subsetting counts as modification.** The OFL defines a Modified Version as
  "any derivative made by adding to, deleting, or substituting … any of the
  components". Clause 3 says no Modified Version "may use the Reserved Font
  Name(s)". **Ark Pixel, Galmuri and Departure Mono declare no RFN**, so they
  can be subset freely. **Pixeloid ("Pixeloid") and Press Start 2P** declare
  one, so a subset or glyph fix must be renamed. Pixeloid is only 118 KB, so it
  can ship unmodified.
- **CC0** (Pixel Operator, Monogram, m5x7): no conditions.

## Recommendation, for the user to judge by eye

This is a starting point for a visual specimen page, **not a decision**. The
user should see every candidate at body, heading and timer sizes, at 1.0× and
2.0×, before anything is recorded.

**Recommended pairing:**

- **Body, UI and headings: Ark Pixel 12px Proportional**, subset to about
  27 KB. It is the most text-like face here: complete punctuation, full Latin
  Extended-A, kerning, correctly shaped quotes, and tabular digits. Headings
  get their emphasis from size, not a bold weight. Base body is about 20 lp
  (x-height 10 lp), snapped per device.
- **Display numerals and big headings: Departure Mono.** It is monospaced
  with `tnum`, has a distinctive slashed zero, and is 84 KB. At the 88-lp timer
  size it is 8 lp per font pixel, which is **crisp on every listed DPR with no
  snapping**. The 1.3× clamp would then snap to the next whole *n*.
- **Tick cells: retired.** Both faces have constant-width digits.

**Fallback: the Pixeloid family** (Sans, Bold, Mono). It is the only candidate
with a true bold and a mono **on the same 9-px grid**, which makes the
snapping `TextScaler` trivial (one E). It has full Latin coverage and it
scales in finer steps (17% at 3×). The blockers to judge by eye are the
backtick-like ’ and ”, which will appear in every "it’s" on iOS and in LLM
chat, and the spurred r.

**If snapping turns out not to be worth it: Pixelify Sans**, which scales
smoothly because it never claims crispness. Tick cells would stay.

**Not recommended for long text:** Pixel Operator (Latin Extended-A gaps and
coarse 33% steps at 2×), m5x7 and m6x11 (missing punctuation), Galmuri
(I/l/| ambiguity), VT323 and DotGothic16 (never crisp), and all caps-only or
micro faces.

## What this does and does not settle

**Settled by evidence:**

- Flutter cannot turn off text anti-aliasing. Crispness comes only from whole
  dots per font pixel, a snapped baseline (the engine already does this), and
  a line start on a whole dot (which the engine does not guarantee).
- A custom `TextScaler` subclass can snap sizes, and the API contract allows
  it. It must wrap the clamp, not sit inside it.
- Ark Pixel, Pixeloid, Pixel Operator, Departure Mono and Monogram all have
  constant-width digits. Tick cells are not needed with any of them.
- m5x7, m6x11, Silkscreen, Press Start 2P, Tiny5, Micro 5 and Bytesized cannot
  carry long English text as shipped.

**Not settled, needs a human eye:**

- Ark Pixel's look against Pixeloid's. The recommendation trades Pixeloid's
  single grid and true bold for Ark's cleaner punctuation.
- Whether Pixeloid's ’ and ” are acceptable.
- Whether the ¼-dot fringe at in-between sizes is visible on a real 2.625×
  Android phone. This needs a device, not a PNG.
- Round-up versus nearest snapping, and the layout slack that round-up needs.

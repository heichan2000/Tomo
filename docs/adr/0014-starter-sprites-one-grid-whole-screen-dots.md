# ADR-0014: Starter sprites, one pet grid, whole screen dots

- **Status:** Accepted
- **Approved changes to the starters:** Geode's feet
  ([#34 Light and dark colours](https://github.com/heichan2000/Tomo/issues/34)),
  and a two-pixel notch in Joe's cap above his eye so the eye has room to look
  up ([#41 Draw Joe](https://github.com/heichan2000/Tomo/issues/41)). Each
  species' approved stage 1 in the code is its starter now.
- **Amended by:** [#45 Redraw Home, Focus and Onboarding in pixels](https://github.com/heichan2000/Tomo/issues/45)
  — the Focus spot is **168 pt**, not 128 pt. At 128 pt the pet looked too
  small on the screen whose whole point is the pet.
- **Date:** 2026-09-27
- **Decided in:** [#33 Pixel pet rules](https://github.com/heichan2000/Tomo/issues/33)

## Context

Tomo's pets move from smooth vector art to pixel art. Each pet has four
evolution stages. On a phone, one pet pixel has to be drawn as some number of
physical screen dots, and phones differ in how many dots make one point (2,
2.625, 3, 3.5 …).

The first draft used a 64×64 grid and the style guide's rule that each stage
covers at least 35% more area than the last. Drawn out for all three pets, that
rule forced the characters out of shape. The chick had to start tiny and squat,
Geode's body flattened, and Lily grew broad instead of tall. The stage-1 sprites
on the *Tomo Pixel Starters* page already looked right.

## Decision

**Stage 1 of each pet is its Tomo Pixel Starters sprite, pixel for pixel.** All
four stages, and the egg, are drawn on **one 48×48 pet grid** at the **same
pixel size**, standing on the same bottom row. Later stages keep everything
earlier stages have, never redraw it smaller, and grow by refining it. So the
pet really does get bigger on screen through stage 3. How much bigger is judged
by eye, not by a percentage. **Stage 4 stays about stage 3's size** and shows
itself through more intricate detail. The one written exception to "never
smaller" is Geode's stage 4, where its crystals become jewels in a forged crown.

**Every pet pixel is a whole number of screen dots, rounded down, never
smoothed.** Each spot asks for a size (Home 192 pt, Focus 168 pt, hatch picker
96 pt), and the pet is drawn at the largest whole number of dots per pixel that
fits it. A small spot never goes below 2 dots per pixel.

## Consequences

- On Home, stage 1 is about 128 pt wide and fills only the lower part of its
  spot. The empty space above it is where the pet will grow.
- The pet can come out a few points smaller than its spot on some phones: the
  Home spot is 183 pt on a 2.625× phone. In exchange, every pixel is the same
  size and sharp on every phone.
- Layout must give the pet a spot it may *underfill*, never one it must fill
  exactly.
- Stage-4 art has to fit in 48 rows above the ground line. That limits how tall
  a stage 4 can grow, and it pushes growth toward refinement rather than bulk.

## Alternatives considered

**Same box for every stage (32×32).** The pet stays the starter's size on
screen. Rejected because Geode's crown, Joe's fan and Lily's upright ears then
only fit if the body is drawn smaller at later stages. That is the same
squeezing, in reverse.

**Pixels shrink as the pet grows.** Every stage fills the spot, drawn on a
larger grid each time. Rejected because the stages look drawn at different
sizes, and the pet never visibly grows.

**64×64 grid with a ≥ 35% area rule.** More room and a checkable number.
Rejected because the number, not the character, ended up deciding the shapes.

**Whole points per pixel instead of whole screen dots.** Simpler layout.
Rejected because on a 2.625× phone the pixels come out 10 and 11 dots wide in
turn, and a pet's two eyes end up different widths.

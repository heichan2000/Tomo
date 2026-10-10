# Tomo pet art — style guide

The characters were decided in
[#9 Pet character design & evolution arc](https://github.com/heichan2000/Tomo/issues/9).
This guide was rewritten for pixel art by
[Wayfinder: Tomo pixel look, light and dark](https://github.com/heichan2000/Tomo/issues/32),
and is binding on every pet drawing. It gathers the rules in one place; the
reasons and the rejected alternatives are in the ADRs it names:
[ADR-0014](adr/0014-starter-sprites-one-grid-whole-screen-dots.md) (the grid),
[ADR-0015](adr/0015-light-and-true-black-accent-from-the-pet.md) (colours),
[ADR-0018](adr/0018-pixel-pets-slide-whole-pixels-flicker-evolution.md) (movement),
[ADR-0019](adr/0019-reward-ladder-twinkle-in-pet-pixels.md) (rewards and the
hatch) and [ADR-0020](adr/0020-pixel-art-as-text-grids-in-code.md) (how art is
stored and approved).

Three starters ship — **Geode**, **Joe**, **Lily** — and the user picks one at
setup, forever. They are three characters in **one art direction**, not three
art directions. Everything below is shared unless a section says otherwise.

The art itself is in `lib/art/pets/geode.dart`, `joe.dart` and `lily.dart`.
Every drawing there is approved; this guide describes them, it does not
replace them.

## 1. Pixel rules

**One grid.** Every stage of a pet, and its egg, is drawn on one **48×48 pet
grid**, standing on the same bottom row at the same pixel size. **Stage 1 is the
pet's Tomo Pixel Starters sprite** (32×32, bottom-centred), pixel for pixel
except two approved changes: Geode's feet (#34) and a two-pixel notch in Joe's
cap above his eye (#41).

**Whole screen dots.** Each pet pixel is drawn as a whole number of screen
dots, rounded down, never smoothed. Spots: Home 192 pt, Focus 168 pt, hatch
picker 96 pt; a spot never goes below 2 dots per pixel. The pet may underfill
its spot.

**The look.**

- At most **seven colours** per pet (§2), shared by every drawing of that pet.
- One main colour and one hard shade per part.
- **No outline, no shine**, no smoothing between colours, no dithering, no stray
  single pixels. A pet's edge holds on both grounds by its colours alone.
- **No expressive mouth.** Geode has a flat mouth line, Lily a nose, Joe
  nothing. Expression rides on eyes, posture and the accent part only.

**Silhouette.** Each stage reads as the right species as a solid shape at
48×48, one dot per pixel.

## 2. Colours

Each pet has one colour key, used on **both grounds** (light `#F5F1EA` and true
black `#000`). Whether a pet shows up well is **judged by eye on both grounds**,
not by a luminance number.

| Role | Key | Geode | Joe | Lily |
|---|---|---|---|---|
| body | `B` | `#3a6470` | `#f4e8d2` cream paper | `#c89ab3` |
| body shade | `S` | `#274a55` | `#cdb58a` | `#96739b` |
| body light | `L` | `#4a7a86` middle feet, crown metal, egg shell | `#fdf6ea` | `#f2e7da` belly, collar, tufts |
| accent | `A` | `#6ee0c6` crystal | `#4a57b8` cap | `#3f8494` ears |
| accent light | `a` | `#b6f0e2` | `#6f7ed8` brim | `#6fb2bf` |
| eyes | `E` | `#b6f0e2` | `#0b0b14` | `#0a120e` |
| face | `F` | `#0a1a1e` mouth, egg crack | — | `#4a2a44` nose |

**The app's accent is copied from these** (ADR-0015): in light, Geode's body,
Joe's cap and Lily's nose; in dark, Geode's crystal, Joe's light blue and Lily's
body. Lily's teal ears are never the accent; they sit too close to Geode's mint.
**Changing a pet colour changes the app's colours too**, and makes every drawing
that uses it a draft again.

## 3. The six parts

Every stage is split into six parts, each a full 48×48 grid, and the pet moves
by sliding them in whole pixels (ADR-0018). **A design that needs a seventh
moving part does not ship**; fold it into one of the six or cut it.

| Part | Geode | Joe | Lily |
|---|---|---|---|
| `body` | the mass, middle feet, and the shade joining each outer foot | body, including the legs | the mass, plus stage 4's collar, legs and feet |
| `head` | the upper mass (rows 0–34), carrying the crystals or crown | the head | the upper mass and the nose |
| `eyes` | the eyes (the eye sheet replaces them) | one 2×2 eye | the eyes |
| `limbA` | left outer foot | tail (stage 2 on) | left ear |
| `limbB` | right outer foot | wing (stage 3 on) | right ear |
| `accent` | the three crystals; at stage 4 the whole crown | cap and brim, plus the stage-4 crown | the hair tuft |
| **Twitches** (its own bit) | crystals / crown | cap | ears |
| **Lifts on the jump** | crystals / crown | cap, wing and tail | nothing extra |
| **Paint order** (back to front) | body, limbA, limbB, head, accent, eyes | limbB, limbA, body, head, eyes, accent | body, head, accent, limbA, limbB, eyes |

Joe has no tail fan and no crest. Lily's ears lean whole with her head.

Rules for every stage:

- **The pixels behind every moving part are painted in**, so sliding a part one
  pixel never shows a hole — at rest, mid-breath, and while leaning or
  twitching mid-breath.
- Each stage records where its **eyes** sit, its **lean step** (the row the
  head bends at when it leans; always above the eyes) and, if it needs one, a
  **breath row** (Joe: every row above it sinks with the breath).
- The eyes have **one pixel of room** left, right and up at every stage, for the
  glance and look-up idle moves.

## 4. The evolution arc

Evolution fires **three times ever**, at levels 10, 40 and 100.

- **Stages 1–3 look clearly bigger each time**, judged by eye. There is no area
  percentage.
- **Stage 4 stays about stage 3's size** and shows itself through finer detail:
  **finer, not busier**.
- **Every stage adds one new nameable thing**, never more copies of an old one.
- **Grow-only.** Everything at stage N is still there, and still visible, at
  stage N+1. Nothing is redrawn smaller or squeezed; a covered feature counts as
  missing. The one written exception is Geode's stage 4, whose crystals become
  jewels in its crown.
- The outer shape changes at every stage, not just its size.

As drawn:

- **Geode — accretion.** The body never changes; all growth is crystal, always
  three crystals, centred and mirrored, the starter shard the left one. S1 the
  starter, one shard. S2 three plain crystals. S3 the head splits open in a
  clean V; the centre crystal rises from the split and the sides lean out. S4 a
  crown forged from its own rock, with the three crystals as mint jewels (the
  large one in the centre), a finial, open filigree, a band of set stones and
  lit seams below it.
- **Joe — refolding.** S1 the starter chick. S2 lifted onto navy legs, with a
  long folded tail. S3 a wing spreading up and out from behind the back, and a
  navy tail tip. S4 a folded paper crown in his blue, on the cap; everything
  else is stage 3.
- **Lily — standing up.** Her body is the starter's at every stage, and her ears
  stay about the same size. S1 sitting, ears floppy. S2 feet, ears half lifted
  out to the sides with drooping tips. S3 legs, ears upright. S4 the same
  height, with a scalloped cream collar, cream tufts at the ear roots and toes.
  **Her ears stay up.**

## 5. Faces

Seven faces are drawn; **the MVP uses five.** *Thinking* and *Puzzled* had only
AI triggers and are parked with the AI layer
([ADR-0029](adr/0029-mvp-ships-without-ai-and-never-goes-online.md)); their eyes
and lean steps stay in the art files. Every name is **user-facing vocabulary**
that a screen reader speaks (#8), so they are plain words, not identifiers. A
face is the eyes plus how the parts move; nothing else is redrawn.

| Face | When | Eyes | Movement |
|---|---|---|---|
| **Resting** | default | resting, with blinks | breath, now and then an *idle move* |
| **Pleased** | a block running, and the block-done beat | pleased (arcs up) | one bob |
| **Drowsy** | a break | drowsy (lid in body shade) | breath |
| **Celebrating** | level-up, task done, evolution | pleased | the jump, with the species' extra lift |
| **Thinking** *(parked)* | an AI call is in flight | resting, one pixel aside | leans left |
| **Puzzled** *(parked)* | AI unavailable (all five causes of #6) | **both eyes smaller** | leans right |
| **Still** | *Calm pet* is on | resting, no blink | nothing moves |

**One eye sheet per species**, shared by all four stages: `resting`, `blink`,
`pleased`, `drowsy`, `puzzled`. Thinking and Still are rules over `resting`,
not drawings. **Eye shape, colour and spacing, and their place on the head, are
the same at every stage.**

**No face is lopsided.** Puzzled is both eyes smaller, never uneven.

**The lean is the tilt.** Pixel art can't rotate, so for Thinking and Puzzled
the lower head slides one pixel and the top two, with the step above the eyes.

**Reduce motion:** nothing moves more than one pixel, and the breath runs at
half speed. *Calm pet* is a face (Still), not a movement setting.

## 6. Eggs

Each species' egg is the **Tomo egg's shape** (the app icon, #44) in that pet's
colours, standing on the pet grid's bottom row, with its own mark: Geode's is
plain slate, Joe's has a navy zigzag band, Lily's has teal spots.

- **Whole, then crack steps**: Geode three, Lily four, Joe five. A running
  block shows them in equal shares, and **the last step shows the pet's eyes
  peeking out**, like the Tomo egg.
- **The shell rule.** At the hatch the shell breaks into seven pieces, cut by
  angle around the centre of the egg's bounding box. The dark of the crack flies
  with the shell; only the pet's own colours (the peeking eyes) stay. **Keep the
  egg's centre plain**: a crack there is chopped into single-pixel slivers.

## 7. Reward effects

Sparkles and confetti are drawn **in pet pixels**, on the pet's grid
(ADR-0019). A sparkle is a four-point star that opens and closes in place in
four frames, in the species accent with a lighter colour of the same pet at its
centre. Confetti uses the pet's colours that show on the current ground.
Nothing blinks on and off; the evolution flicker is the only flashing thing.

## 8. Approving a drawing

1. Claude draws or changes the text grid in the species file. A changed drawing
   is a **draft**.
2. `node tool/art/review_page.mjs` builds the review page from the code: each
   drawing on both grounds, at phone size and zoomed, split into parts, with
   every face, movement, idle move, the egg's steps and pieces, the flicker and
   the hatch.
3. The page's checks must pass: 48×48 grids on the shared bottom row, at most
   seven colours, eyes and eye room, lean step, crack outline, no gaps or holes
   on any movement, no slivers at the hatch.
4. By eye: the pet shows up on both grounds, reads as its species at 48×48, and
   keeps everything from the stage before.
5. The user approves on the generated page. The drawing is marked **approved**
   with its fingerprint and a link to the approval. Change one pixel or one
   colour and it is a draft again; a release build refuses drafts.

## 9. The three species voices

Each starter has its own voice. The **structure** of the system — how personality
multiplies against it, which registers vary and which are authored once — belongs
to [#30](https://github.com/heichan2000/Tomo/issues/30). What follows is the
species baseline only, which is this document's job.

Each voice needs one property that **no amount of personality shading can
erase** — the copy equivalent of §1's silhouette test. The personality axis is
warm at every point (the PRD forbids a cop; #8 binds every line to grow-only),
so the species axis has to carry distinctiveness on a dimension personality does
not touch.

#30 settled the personality axis as **Quiet / Chatty**: how much the pet
volunteers ([ADR-0021](adr/0021-plain-voice-bad-news-quiet-chatty-personality.md)).
The two right-hand columns below are those two ends. A Chatty line adds one
detail that can't go down: a growing count, a first or record, or this cycle.
It never mentions a streak, a comparison or time away.

| | Indelible property | At its quietest | At its most talkative |
|---|---|---|---|
| **Geode** | Present tense, duration only. No future tense, no "you should." It observes accumulation. | "Twenty-five minutes." | "Twenty-five minutes, and the one before it. Both in me now." |
| **Joe** | It counts. Exact numbers, never rounded, never "a bunch." | "Four." | "Four blocks. Two of them on the same task — the most so far." |
| **Lily** | Second person. The only one that says *you*, and the only one that asks questions. | "You're back." | "You're back. Same task, or something new?" |

The three properties are orthogonal by construction: **tense**, **number**,
**address**. A talkative Geode still does not count; a terse Joe still hands you
a figure; a quiet Lily still says *you*. This passes the test #30 sets — Geode at
its most talkative does not read as Joe at its quietest.

Two consequences for whoever authors the strings:

- Geode's ban on the future tense removes a whole class of line from it. It can
  never say "see you tomorrow" or "try again later," which is a real constraint
  on notification copy, where the other two are unencumbered.
- Lily's questions imply an answer, and in the no-key path there is nothing to
  answer *to*. Its offline lines must be rhetorical or self-closing, or Lily
  reads as broken precisely where graceful degradation matters most.

## What the vector guide had that is gone

The first version of this guide was a brief for an image generator feeding an
SVG tracer (see #9's resolution). Dropped with it: the `n@90%` colour budget
and its script, the tracing rules, the generator prompt, the ≥ 35% area rule,
the head-size proportions and eye-height band (the starter sprites now set
proportions), the 0.30 ground-luminance rule and Joe's exception to it, Joe's
three-quarter re-pose, lopsided Puzzled eyes, and the "Still is the idle's
mid-breath frame" pose.

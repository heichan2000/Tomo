# Animating the pet: free tooling, and what an agent can actually author

**Research date: 2026-09-16.**

> **Snapshot warning.** Pricing and plan boundaries move. The single most
> consequential fact below — that Rive's Free plan no longer exports `.riv` —
> is a *pricing* fact, read from the primary source on 2026-09-16, and could
> change again. The *shapes* (which formats are agent-authorable, which
> runtimes ship a state machine) are durable; the dollar figures expire.

## Why this exists

`Tomo_Tech_Stack_Architecture.md` assumes **Rive** for the pet, and issue #16
specifies a Rive state machine input contract. That assumption was made before
two things were known:

1. The developer has **no animation tooling and no rigging skill**, and asked
   whether the agent can do the animating instead.
2. Rive changed its pricing model.

Both bear on the same question, which the map had not asked: *is Rive still
the right runtime?* This document gathers the evidence; it does not make the
call.

## The binding constraint: what can an agent author?

This is the constraint that reorders everything, and it is not about quality —
it is about **file format**.

| Format | What it is | Agent-authorable? |
|---|---|---|
| Lottie `.json` | Plain JSON: layers, shapes, keyframed transforms | **Yes** — directly |
| dotLottie `.lottie` | A zip: Lottie JSON + `s/*.json` state machines | **Yes** — directly |
| Flutter widget code | Dart `AnimationController`, `Tween`, `CustomPainter` | **Yes** — directly |
| SVG + `flutter_svg` | XML | **Yes** — directly |
| Rive `.riv` | **Binary**, authored in the Rive editor | **No** — see below |

An agent writes text files. Lottie, dotLottie, SVG and Dart are text. `.riv`
is a binary artefact of a closed desktop/web editor, and there is no
first-party writer SDK — [Rive's own format
doc](https://rive.app/docs/runtimes/advanced-topic/format) describes `.riv` as
the *output* of the editor that runtimes read.

So the question "can you animate these for me?" has a precise answer:
**only if the target format is not `.riv`.**

## Finding 1 — Rive's Free plan no longer exports `.riv`

Read from [rive.app/pricing](https://rive.app/pricing) on 2026-09-16:

| Plan | Price | Exports `.riv`? |
|---|---|---|
| Free | $0 | **No** |
| Cadet | $9 / seat / mo (max 3 seats) | Yes |
| Voyager | $32 / seat / mo (max 25 seats) | Yes |
| Enterprise | $120 / seat / mo | Yes |

Rive's [own announcement](https://rive.app/blog/rive-s-new-9-mo-plan) frames
it as "free for creation and learning", with export gated behind a paid plan
once work "leaves the Editor to run in production, in an app, game, product,
or website."

**This is a $108/yr recurring cost on a project whose entire architecture
exists to avoid a backend and its bills.** It is not a large number in
absolute terms, and it buys a genuinely better tool. But it was never a
budgeted line, and the map should decide it rather than inherit it.

Note the *runtimes* remain MIT-licensed and free. The gate is on export, not
on shipping.

## Finding 2 — dotLottie now has state machines, and they are JSON

This is the finding that makes an alternative real rather than theoretical.

Lottie historically had no interactivity, which is why the architecture doc
reached for Rive. That is no longer true. The **dotLottie v2 spec** adds state
machines stored as **plain JSON files in the `s/` directory of the `.lottie`
zip**, with:

- `initial`, `states`, `inputs`, `interactions`
- transitions carrying `toState`, `duration`, `easing` and a `guards` array
- **guards** supporting numeric comparison (`Equal`, `NotEqual`, `LessThan`,
  `GreaterThan`, `LessThanOrEqual`, `GreaterThanOrEqual`), plus string and
  event matching
- **inputs** as named runtime variables — boolean, numeric, string — that
  drive the guards

Sources: [dotLottie 2.0 spec](https://dotlottie.io/spec/2.0/),
[dotlottie-web State Machines
wiki](https://github.com/LottieFiles/dotlottie-web/wiki/State-Machines).

Compare that list against **#16's** required input contract — "every boolean,
number, and trigger the state machine exposes… triggers for momentary events,
booleans and numbers for sustained state". It is a direct match. #16's
contract is expressible in dotLottie essentially unchanged.

### The Flutter runtime exists and is first-party

[`dotlottie_flutter`](https://pub.dev/packages/dotlottie_flutter) — published
by the **verified LottieFiles publisher**, v0.1.7, last published ~30 days ago
(mid-August 2026).

- Platforms: iOS, Android, macOS, Windows, Linux, Web
- 140 pub points, 13.3k downloads, **11 likes**
- State machine API: `stateMachineLoad()`, `stateMachineFire()`,
  `stateMachineSetBooleanInput()` / numeric / string setters, and
  `stateMachineOnStateEntered` callbacks
- No beta/experimental warning in the package description

**The honest read on maturity:** the version number is `0.x`, and 11 likes is
a very thin adoption signal for something load-bearing. It is first-party and
actively published, which is the strongest thing in its favour, but this is
not the mature option — `rive-flutter` is. Anyone choosing dotLottie is
trading maturity for authorability.

## Finding 3 — the editor-less Rive writers exist, and both are risky

Two projects claim to write `.riv` without the editor. Both are real; neither
is safe to build a product on.

**[rive-mcp](https://github.com/ODU33104/rive-mcp)** — an MCP server, exactly
the shape the developer asked about. 32 tools: `riv_create` (JSON → `.riv`),
`riv_rig_character` (**PNG → rigged `.riv`**), `riv_import_svg`,
`riv_lottie_import`, `riv_render_gif`, `riv_play_state_machine`, a local web
Studio, and `riv_generate_code` with Flutter output. Renders via the official
Rive WASM runtime in headless Chromium. Claims support for bones, skinning,
IK, mesh deformation, multi-layer state machines and listeners. Requires
neither the Rive editor nor a paid plan.

Install: `/plugin marketplace add ODU33104/rive-mcp` then
`/plugin install rive-mcp@rive-tools`, or `npm install -g rive-mcp-server`.

**Why this is a risk, not a solution:**

- **13 GitHub stars.** One maintainer.
- **Source-available freeware, not open source.** The license permits free
  personal and commercial use and says generated files are yours, but
  **prohibits modification, redistribution, and reverse engineering**, and
  explicitly prohibits AI-assisted code analysis. If it breaks or is
  abandoned, there is no fork path — which is the whole point of a license.
- It writes a **closed binary format by reimplementation**. A Rive runtime
  update that changes the format is a silent breakage with no recourse.
- Stated limitations include Canvas2D preview artefacts (phantom mesh seams),
  no transparency in GIF output, and no Luau/Layout generation.

**[rive-rs-cli](https://github.com/George-RD/rive-rs-cli)** — MIT-licensed
Rust CLI, JSON `SceneSpec` → `.riv`, built explicitly for AI agents. Better
license, **8 stars**, requires a Rust toolchain (not installed here). Narrower
feature claims: shapes, animations, embedded fonts, path morphing, pointer-
driven state machines.

Both would put a 10-star single-maintainer dependency on the critical path of
the product's emotional centre. That is a worse bet than either paying Rive
$9/mo or choosing a format the agent can author natively.

## Finding 4 — the assets are not yet riggable, in any format

Measured directly from `docs/assets/` on 2026-09-16 (Pillow, `python`):

| Candidate | Size | Unique colours | Background |
|---|---|---|---|
| Joe (origami bird) | 1024² RGBA | **4,128** | Opaque white, no alpha |
| Geode (crystal rock) | 1024² RGBA | 6,800 | Opaque white, no alpha |
| Lily (lop-eared blob) | 1024² RGBA | **13,402** | Opaque white, no alpha |

Three consequences, and they apply **regardless of which runtime wins**:

1. **No alpha.** Every file is opaque white behind the character. Background
   removal is required. For these — flat art on near-pure white — this is
   cheap and scriptable, not a `rembg` job.
2. **Compression noise.** A flat-vector illustration with six colours should
   have ~6 unique values, not 4,128. The extra colours are JPEG-style ringing
   around edges. Tracing amplifies this into hundreds of spurious sub-paths
   unless the image is colour-quantised first.
3. **Single flattened layer — this is the real blocker.** A rig needs the pet
   *in parts*: head separate from body, each ear separate, eyes separate,
   Geode's crystals separate from its rock. Nothing in these PNGs is
   separated, and no tool infers the separation reliably, because it requires
   knowing what is *behind* each part — the occluded geometry that has to be
   painted in before a part can move.

This third point is the one the architecture doc already predicted: generation
is "the easy 80%", with background removal, proportion consistency and rigging
as the manual remainder. The measurement confirms it.

**The colour count is also a design signal.** Joe at 4,128 is essentially four
flat tones and vectorises near-losslessly. Lily at 13,402 has genuine soft
gradients that no vector tracer reproduces cleanly — Lily would have to ship
as an **image-mesh** rig (bitmap deformation) rather than a vector rig.
Choosing Lily therefore narrows the runtime options at the same time as it
raises the rigging cost.

## The free pipeline, if the answer is "not Rive"

Every step here is free, scriptable, and available to an agent. It is written
down so the art spike (#23) has something concrete to time.

1. **Alpha + quantise** — Pillow. White-to-transparent, then quantise to the
   palette's exact colours. Kills the compression noise before it propagates.
   *(Pillow is already installed.)*
2. **Trace to SVG** — [VTracer](https://github.com/visioncortex/vtracer), MIT,
   available as a `pip` package (no Rust toolchain needed). Its stacking
   strategy produces far fewer shapes than Illustrator's Image Trace, which
   matters directly for file size. `binary` mode for single-tone parts,
   `color` mode for the whole figure.
3. **Separate into parts** — **the manual step.** Human decides the part
   breakdown and paints occluded geometry. No tool removes this.
4. **Compose Lottie JSON** — agent-authored, or
   [python-lottie](https://pypi.org/project/lottie/) for programmatic
   construction. Keyframed transforms per part: the breathing idle, the still
   pose, the reaction.
5. **Add the state machine** — hand-authored JSON in `s/`, matching #16's
   contract. Zip into `.lottie`.
6. **Play** — `dotlottie_flutter`.

A **free GUI fallback** exists for steps 4–5 if hand-authoring proves
unpleasant: [Glaxnimate](https://glaxnimate.org/) — free, open source, part of
KDE, Windows/Mac/Linux, imports SVG and exports Lottie JSON. It does not
author state machines, but it is a real timeline editor for the animation
layer.

## What this does and does not settle

**Settled by evidence:**

- `.riv` cannot be agent-authored without a third-party reimplementation.
- Rive Free cannot export; shipping Rive costs $9/mo minimum.
- dotLottie has a state machine that satisfies #16's contract shape, is JSON,
  and has a first-party Flutter runtime — at `0.x` maturity.
- The current assets need alpha, quantisation, and **manual part separation**
  before any rig, in any format.

**Not settled, and needs a human:**

- Whether $9/mo is worth Rive's maturity and superior rigging over
  authorability and $0.
- Whether the pet's motion is rich enough to *need* skeletal rigging at all —
  a breathing idle, a blink, a hop and a celebrate may be reachable with plain
  Flutter transform animations over a handful of layered SVGs, which is the
  cheapest option on the board and the one no one has priced.

That last option deserves naming explicitly, because it is easy to skip past:
**layered SVG + Flutter's own animation framework**. Zero new dependencies,
zero cost, fully agent-authorable, degrades trivially to a still pose for
`Calm pet` and to reduced amplitude for reduce-motion. It gives up mesh
deformation and squash-and-stretch. For a pet that mostly breathes, blinks,
and bounces, that may be a price worth paying.

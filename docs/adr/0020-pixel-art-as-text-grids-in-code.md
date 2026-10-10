# ADR-0020: Pixel art is text grids in the code, approved by fingerprint

- **Status:** Accepted
- **Date:** 2026-10-02
- **Decided in:** [#36 How pixel art is stored and edited](https://github.com/heichan2000/Tomo/issues/36)
- **Retires:** the *fallback pet* from
  [#16 Pet animation controller contract](https://github.com/heichan2000/Tomo/issues/16)
- **Replaces:** [#23 Art pipeline spike](https://github.com/heichan2000/Tomo/issues/23)
  (SVG tracing and part separation)
- **Amended by:** [#47 One art model for all three pets](https://github.com/heichan2000/Tomo/issues/47)
  — one model, one fingerprint rule, one folder and one review tool (see
  *Amendment* below)

## Context

Claude draws every pixel asset and the user approves it by eye on artifact pages
(the map's Notes). Pixel pets are six parts per stage plus one eye sheet per
species, slid in whole pixels by code (ADR-0018). The app icon is one 36×36 grid
that has to become seven platform files (#44). The starters and the icon were
already worked out as text grids: one letter per pixel plus a colour key.

The ticket expected a round trip through a pixel editor, so that the user could
change pixels too. The user chose not to edit at all: they say what to change,
and Claude changes it. That removes the only reason to keep art in an editor's
format.

## Decision

**Text grids are the one real copy of all pixel art.** One character per pixel,
`.` for clear, and a colour key per drawing (at most seven colours on a pet).
Every picture file is made from the grids and never edited by hand. This covers
the pets, the species eggs, the eye sheets, the sparkles, the 12×12 interface
icons and the Tomo egg. Only the font is not a grid.

**The grids live in Dart source, not in asset files.** One file per species holds
its egg, 4 stages × 6 parts and its eye sheet, with where the eyes sit on each
stage and the row where its head bends when it leans (the *lean step*, ADR-0018:
rows above it slide two pixels, the rest one; it sits above the eyes, wherever
that stage opens no gap, added in #42). Each part is a full 48×48 grid, so a part's position is where its pixels
are. They are compiled in, so the pet is there on the first frame, a broken grid
fails the build, and nothing can fail to load.

**The app paints the grids itself.** Each part is painted once as squares of a
whole number of screen dots, then slid. No PNG step, and the accent colour
(ADR-0015) is read from the pet's colour key, so it cannot drift.

**Every drawing carries a mark: draft or approved.** An approved mark holds a
fingerprint of the drawing's exact pixels and colours and a link to the comment
where the user said yes. Changing one pixel or one colour makes it a draft again.

**One art test** fails a release build if any drawing is missing, a draft, or no
longer matches its fingerprint. While the Draw tickets are under way, a stage
that isn't drawn yet shows the latest stage that is.

**The fallback pet is retired.** It existed so that a failed asset load could
never leave a hole and so the app could be built with no art. Built-in grids
can't fail to load, and the three stage-1 starters are already approved.

**The app icon and splash files are generated and committed.** A script makes the
iPhone 1024 master (default, dark, one-colour), the Android background,
foreground and monochrome layers, and the splash picture from the Tomo egg grid,
and saves them where each platform expects them. A test regenerates them and
fails if they differ.

**Review pages are generated from the code.** A script builds the artifact page
the user approves from: each drawing on both grounds, at phone size and zoomed,
with its parts, faces and fingerprint. Early side-by-side comparisons may still
be hand-made prototypes, but approval only ever happens on a generated page.

## Consequences

- No pixel editor, no paid tool and no format conversion. All art changes go
  through Claude, and the user's role is looking and approving.
- Art diffs line by line in review, and tests can assert on it (colour counts,
  the 48×48 grid, shared bottom row, eye sheets complete).
- "Approved" means exactly the pixels the user saw, enforced by the build rather
  than by memory.
- All three species ship in the binary. As text this is a few hundred KB, which
  answers most of the old map's *performance and asset-size* fog for art.
- Art sits in the code folder rather than an assets folder. Nobody but Claude
  edits it, so this costs nothing.

## Alternatives considered

**A pixel editor round trip** (Aseprite, LibreSprite, Piskel), so the user could
change pixels. Declined: the user prefers to describe changes, and every editor
format needs a conversion script in both directions.

**PNG as the real copy.** Easy to glance at in a folder, but Claude would edit it
blind through a script, and a change shows only as "image changed".

**Generating PNGs before each build and drawing them with smoothing off.** The
usual way to show images, but a second set of files must stay in step with the
grids, and the accent colour gets copied by hand.

**Grids as text asset files loaded at start.** Tidier to browse, but loading can
fail, which keeps the fallback pet, and the first frame waits for the load.

**Approval recorded only in the ticket.** Simpler, but nothing stops an
unapproved change later, and drafts can't be seen in the real app.

**Approved art stays approved through small fixes.** Faster, but "approved" would
no longer mean the exact pixels the user saw.

## Amendment: one art model (#47)

The three Draw tickets ran in parallel and each built its own model,
fingerprint and review tool. They are now one:

- **Folder.** All pixel art lives under `lib/art/`: the model in
  `lib/art/pixel_art.dart`, one file per species in `lib/art/pets/`. The icons,
  sparkles and Tomo egg join it there.
- **Model.** A species file holds its colour key, egg, four stages (six parts,
  eye spots, lean step, optional breath row) and eye sheet (five faces, each a
  small grid plus an offset; Thinking and Still are rules, not drawings). The
  egg is stored as **whole plus one full picture per crack step**, not as
  numbered crack pixels: Geode's and Lily's last steps recolour pixels (the
  eyes peeking out), which numbered pixels can't hold.
- **Each pet moves as it was approved.** Every movement is shared code, and a
  species names which parts take part: which ride with the head, which lean
  whole (Lily's ears), which twitch, which lift on the jump, its paint order,
  and the colours that stay at the hatch (Geode's eyes). Breathing sinks the
  riding parts, plus every row above a stage's breath row if it has one (Joe).
  These settings are part of each stage's fingerprint.
- **Fingerprint.** The first 16 hex digits of SHA-256 over a canonical text,
  written out in `pixel_art.dart`'s library doc. A standard hash, so the Dart
  art test, the Node tool and any later script compute it without a
  hand-written hash.
- **Review tool.** `node tool/art/review_page.mjs` builds one page for all
  three pets with a Pet switch. Its checks merge all three old tools': grids,
  shared bottom row, eyes, lean step, crack outline, gaps and holes on every
  movement, eye room, hatch slivers. The page plays movements with the same
  pose code the checks use.

The port changed no pixel and no approved movement (checked pose by pose
against each pet's old rule); all 18 drawings were re-approved under the new
fingerprint.

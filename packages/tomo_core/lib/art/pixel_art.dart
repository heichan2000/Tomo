/// Pixel art as text grids in the code (ADR-0020).
///
/// Every drawing is a text grid, one character per pixel, `.` for clear. Pet
/// grids are 48×48 (ADR-0014), so a part's position is simply where its pixels
/// are. A species file (`pets/geode.dart`, `pets/joe.dart`, `pets/lily.dart`)
/// is the one real copy of that pet's art; `icons.dart`, `sparkle.dart` and
/// `tomo_egg.dart` are the one real copy of the rest. Review pages are
/// generated from these files (`node tool/art/review_page.mjs`), and
/// `drawings.dart` lists every drawing for the art test.
///
/// Pets and the Tomo egg are read through their own colour key. Icons and the
/// sparkle are coloured at run time, so their characters name a *paint* (a
/// role such as "the icon's colour" or "the sparkle's centre") instead.
///
/// Each drawing carries a [Mark]. An [Approved] mark holds the fingerprint of
/// the exact pixels and colours the user said yes to, and a link to where they
/// said it. Changing one pixel or one colour makes the fingerprint stop
/// matching, so the drawing counts as a draft again.
///
/// **Fingerprint.** The first 16 hex characters of the SHA-256 of the
/// drawing's canonical text, UTF-8, lines joined by `\n`:
///
/// 1. `tomo-art 1`, then `drawing <id>`, where the id is `<species>.egg`,
///    `<species>.stage<N>` or `<species>.eyes` (species in lower case),
///    `icon.<name>` (an [IconName]), `sparkle` or `tomo.egg`;
/// 2. for a drawing with a colour key, one `colour <char> #rrggbb` line per
///    character its grids use, sorted by character code, lower-case hex, no
///    alpha. For an icon or the sparkle, one `paint <char> <role>` line per
///    character its grids use, sorted the same way, the role taken from
///    [IconArt.paints] or [Sparkle.paints];
/// 3. for a stage, the species' motion settings it was approved with, each a
///    list of part names in [Part] order, or `-` when empty: `order` (the
///    paint order, as listed), `rides`, `leans-whole`, `twitches`,
///    `lifts-on-jump`; then `eye <x> <y>` per eye, `lean <row>` and
///    `breath <row>` (or `breath -`). For a species egg, `stays <chars>`
///    (sorted, or `-`). Nothing for anything else;
/// 4. its grids, each introduced by a `grid <name>` line and followed by its
///    rows. A stage's grids are its parts in [Part] order; a species egg's are
///    `whole`, then `crack1`, `crack2`, …; an eye sheet's are its shapes in
///    [EyeShape] order, each introduced as `grid <shape> <dx> <dy>`. An icon's
///    one grid is `grid icon`, the sparkle's are `frame1` to `frame4`, and the
///    Tomo egg's one grid is `grid whole`.
///
/// `drawings.dart` writes the canonical text out and the art test hashes it;
/// `tool/art/pixel_art.mjs` computes the same for the review page.
library;

/// A pixel on the 48×48 pet grid, or an offset from one.
typedef Px = ({int x, int y});

/// The six parts every pet stage is split into (ADR-0018). Each is a full
/// 48×48 grid, with the pixels behind every moving part painted in.
enum Part { body, head, eyes, limbA, limbB, accent }

/// The eye drawings on a species' eye sheet, shared by all four stages.
///
/// Celebrating uses [pleased]. Thinking is [resting] moved one pixel toward
/// the lean. Still is [resting] with no blink.
enum EyeShape { resting, blink, pleased, drowsy, puzzled }

/// Whether the user has approved a drawing.
sealed class Mark {
  const Mark();
}

/// Not approved yet, or changed since it was. A release build refuses to ship
/// it.
final class Draft extends Mark {
  const Draft();
}

/// Approved for exactly the pixels and colours whose [fingerprint] this is.
final class Approved extends Mark {
  const Approved({required this.fingerprint, required this.approvedIn});

  /// See the library doc for how it is computed.
  final String fingerprint;

  /// The comment where the user said yes.
  final String approvedIn;
}

/// All of one species' art, and the few settings that say how its parts move.
///
/// Every movement is shared code over the parts (ADR-0018); these settings
/// only say which parts take part:
///
/// - **Breathing** sinks the parts that [ridesWithHead] one pixel, and also
///   every part's rows above the stage's [Stage.breathRow], if it has one.
/// - **Leaning** slides the parts that [ridesWithHead]: their rows above the
///   stage's [Stage.leanStep] two pixels, the rest one. A part that
///   [leansWhole] slides two pixels all the way down.
/// - **Twitching** lifts the [twitches] parts one pixel.
/// - **Celebrating** lifts the [liftsOnJump] parts one more pixel at the top
///   of the jump.
final class SpeciesArt {
  const SpeciesArt({
    required this.name,
    required this.colours,
    required this.paintOrder,
    required this.ridesWithHead,
    this.leansWhole = const {},
    required this.twitches,
    this.liftsOnJump = const {},
    required this.egg,
    required this.stages,
    required this.eyeSheet,
  });

  final String name;

  /// The colour key, `0xAARRGGBB`, shared by every drawing and both themes. At
  /// most seven colours (ADR-0014). The app's accent is copied from here
  /// (ADR-0015).
  final Map<String, int> colours;

  /// Back to front.
  final List<Part> paintOrder;

  final Set<Part> ridesWithHead;
  final Set<Part> leansWhole;
  final Set<Part> twitches;
  final Set<Part> liftsOnJump;

  final Egg egg;
  final List<Stage> stages;
  final EyeSheet eyeSheet;
}

/// One stage of a pet, split into its six parts.
final class Stage {
  const Stage({
    required this.mark,
    required this.eyes,
    required this.leanStep,
    this.breathRow,
    required this.parts,
  });

  final Mark mark;

  /// Where each eye's sheet drawing is placed from: one spot per eye.
  final List<Px> eyes;

  /// Leaning, rows above this one slide two pixels and the rest one. It is
  /// always above the eyes.
  final int leanStep;

  /// Breathing, every part's rows above this one sink a pixel too, not only
  /// the parts that ride with the head. Null when only those move.
  final int? breathRow;

  final Map<Part, String> parts;
}

/// A species' egg on the 48×48 pet grid: whole, then one picture per crack
/// step. A running block shows them in equal shares, so the last one (the
/// eyes peeking out) shows in the last share (#45).
final class Egg {
  const Egg({
    required this.mark,
    required this.whole,
    required this.cracks,
    this.staysAtHatch = const {},
  });

  final Mark mark;
  final String whole;
  final List<String> cracks;

  /// Colour-key characters that stay put when the shell breaks apart at the
  /// hatch, because they belong to the pet (Geode's peeking eyes). Everything
  /// else flies with the shell.
  final Set<String> staysAtHatch;
}

/// One eye drawing, placed at each of a stage's [Stage.eyes] plus [offset].
/// Its characters are colour-key characters; `.` shows the head.
final class Eye {
  const Eye(this.offset, this.grid);

  final Px offset;
  final String grid;
}

final class EyeSheet {
  const EyeSheet({required this.mark, required this.faces});

  final Mark mark;
  final Map<EyeShape, Eye> faces;
}

/// The 20 interface icons that ship (spec §9.5). `homeF` and `workClipF` are
/// the filled versions for the selected tab; `todo`, `doing` and `done` are
/// the task status glyphs.
enum IconName {
  home,
  homeF,
  workClip,
  workClipF,
  back,
  next,
  up,
  down,
  close,
  plus,
  minus,
  more,
  gear,
  trash,
  external,
  check,
  bellOff,
  todo,
  doing,
  done,
}

/// A 12×12 interface icon, one UI pixel per icon pixel (ADR-0017). It has one
/// colour, chosen where it is drawn: ink, muted, the accent or on-accent.
final class IconArt {
  const IconArt({required this.mark, required this.grid});

  /// The size of every icon grid, both ways.
  static const size = 12;

  /// `#` is the icon's colour.
  static const paints = {'#': 'icon'};

  final Mark mark;
  final String grid;
}

/// The reward sparkle (ADR-0019), drawn in pet pixels. Four frames, each a
/// square grid centred on the sparkle's middle pixel: 1, 3, 5 and 7 wide.
/// Its colours depend on the pet and the theme, so they are chosen where it is
/// drawn: the arms take the theme's accent, the centre a lighter colour of the
/// same pet.
final class Sparkle {
  const Sparkle({required this.mark, required this.frames});

  /// `#` is an arm; `o` and `x` are both the centre colour.
  static const paints = {'#': 'arms', 'o': 'centre', 'x': 'centre'};

  final Mark mark;
  final List<String> frames;
}

/// The Tomo egg: the app icon and the splash picture (spec §9.7). A 36×36 grid
/// with its own colour key; `.` shows the icon's background.
final class TomoEgg {
  const TomoEgg({
    required this.mark,
    required this.colours,
    required this.grid,
  });

  /// The size of the grid, both ways.
  static const size = 36;

  final Mark mark;

  /// `0xAARRGGBB`.
  final Map<String, int> colours;

  final String grid;
}

/// The rows of a grid literal: the newline after the opening quotes and the
/// one before the closing quotes are not rows.
List<String> gridRows(String grid) {
  final rows = grid.split('\n');
  if (rows.isNotEmpty && rows.first.isEmpty) rows.removeAt(0);
  if (rows.isNotEmpty && rows.last.isEmpty) rows.removeLast();
  return rows;
}

import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:tomo_core/art/compose.dart';
import 'package:tomo_core/art/drawings.dart';
import 'package:tomo_core/art/pixel_art.dart';
import 'package:tomo_core/art/sparkle.dart';
import 'package:tomo_core/pet/pet_look.dart';
import 'package:tomo_core/pet/reward_colours.dart';
import 'package:tomo_core/pet/run_script.dart';
import 'package:tomo_core/pet/species.dart';

import '../l10n/app_localizations.dart';
import '../ui/exp_bar.dart';
import '../ui/pixel_box.dart';
import '../ui/sharp_text.dart';
import '../ui/tomo_theme.dart';
import '../ui/ui_pixel.dart';
import '../ui/whole_dots.dart';
import 'pet_view.dart';

/// The pet as a beat run shows it (spec §7.5, ADR-0019): the pet or egg of
/// [frame], the sparkles, confetti and breaking shell drawn around it in pet
/// pixels, and "+EXP" rising beside its head.
///
/// The effects reach well outside the pet's spot, so nothing above it may
/// clip it. Once the run's payload is in, the pet is [rest], the screen's
/// own look, while the last effects play out.
class RewardPet extends StatelessWidget {
  const RewardPet({
    super.key,
    required this.frame,
    required this.rest,
    required this.spot,
    required this.semanticLabel,
  });

  final RunFrame frame;
  final PetLook rest;
  final double spot;
  final String semanticLabel;

  Species get _species => rest.species;
  Movement get _movement => rest.movement;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final dots = dotsPerPixel(
      spot: spot,
      gridSize: _grid,
      devicePixelRatio: dpr,
    );
    final shown = frame.pet;
    return SizedBox.square(
      dimension: spot,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ..._pets(shown),
          Positioned.fill(
            child: IgnorePointer(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: PixelBlocks(
                  blocks: _effects(context),
                  dots: dots,
                  gridSize: _grid,
                ),
              ),
            ),
          ),
          if (frame.gain case final gain?)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomSingleChildLayout(
                  delegate: _GainPlace(
                    anchor: _gainAnchor(shown, dots / dpr),
                    rightEdge:
                        spot + (MediaQuery.sizeOf(context).width - spot) / 2,
                    ui: UiPixel.of(context),
                    raised: gain.dy,
                  ),
                  child: Opacity(
                    opacity: gain.opacity,
                    child: PixelText(
                      AppLocalizations.of(context).beatGain(gain.exp),
                      step: TypeStep.title,
                      colour: TomoTheme.of(context).accent,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// The pet, or two of it while they cross-fade. The same pet keeps its
  /// key, so its own movement carries on from frame to frame.
  List<Widget> _pets(ShownPet? shown) => switch (shown) {
    null => [_pet(const ValueKey('pet'), rest)],
    ShownStage() ||
    ShownEgg() => [_pet(const ValueKey('pet'), _look(shown), shown)],
    CrossFade(:final from, :final to, :final share) => [
      Opacity(
        opacity: 1 - share,
        child: _pet(const ValueKey('from'), _look(from), from),
      ),
      Opacity(opacity: share, child: _pet(const ValueKey('to'), _look(to), to)),
    ],
  };

  Widget _pet(Key key, PetLook look, [ShownPet? shown]) => PetView(
    key: key,
    look: look,
    spot: spot,
    semanticLabel: semanticLabel,
    // Each beat starts the face over, so the block-done beat bobs even over
    // a running block's Pleased.
    beat: shown == null ? null : frame.beat,
    shift: shown is ShownEgg ? shown.shift : 0,
  );

  PetLook _look(ShownPet shown) => switch (shown) {
    ShownStage(:final stage, :final face) => HatchedLook(
      species: _species,
      movement: _movement,
      stage: stage,
      face: face,
    ),
    ShownEgg(:final picture) => EggLook(
      species: _species,
      movement: _movement,
      picture: picture,
    ),
    CrossFade(:final to) => _look(to),
  };

  /// The shell, the sparkles and the confetti, in that order, front last.
  List<GridBlock> _effects(BuildContext context) {
    final theme = TomoTheme.of(context).palette.theme;
    final colours = sparkleColours(theme, frame.hatched ? _species : null);
    return [
      for (final p in frame.shell) GridBlock(p.x, p.y, Color(p.colour)),
      for (final k in frame.sparkles)
        ..._stamp(k, Color(colours.arms), Color(colours.centre)),
      for (final p in frame.confetti)
        GridBlock(p.x, p.y, Color(p.colour), width: p.width, height: p.height),
    ];
  }

  /// [k]'s frame of the sparkle drawing, centred on its pixel: the arms (`#`)
  /// and the centre (`o`, `x`).
  Iterable<GridBlock> _stamp(SparkleShown k, Color arms, Color centre) sync* {
    final rows = _sparkleFrames[k.frame];
    final left = k.x - (rows.first.length - 1) ~/ 2;
    final top = k.y - (rows.length - 1) ~/ 2;
    for (var j = 0; j < rows.length; j++) {
      for (var i = 0; i < rows[j].length; i++) {
        final colour = switch (rows[j][i]) {
          '#' => arms,
          'o' || 'x' => centre,
          _ => null,
        };
        if (colour == null) continue;
        yield GridBlock(
          left + i,
          top + j,
          k.opacity == 1 ? colour : colour.withValues(alpha: k.opacity),
        );
      }
    }
  }

  /// Where "+EXP" starts, in points from the spot's top left: three pixels
  /// right of the picture and two down from its top (Tomo Pixel Screens).
  Offset _gainAnchor(ShownPet? shown, double pixel) {
    final rows = switch (shown) {
      ShownStage(:final stage) => composeStage(artOf(_species), stage - 1),
      ShownEgg(:final picture) => _eggRows(picture),
      CrossFade(:final from, :final to, :final share) => switch (share < 0.5
          ? from
          : to) {
        ShownStage(:final stage) => composeStage(artOf(_species), stage - 1),
        ShownEgg(:final picture) => _eggRows(picture),
        CrossFade() => const <String>[],
      },
      null => const <String>[],
    };
    var top = _grid, right = 0;
    for (var y = 0; y < rows.length; y++) {
      for (var x = 0; x < rows[y].length; x++) {
        if (rows[y][x] == '.') continue;
        top = math.min(top, y);
        right = math.max(right, x);
      }
    }
    final grid = _grid * pixel;
    return Offset(
      (spot - grid) / 2 + (right + 3) * pixel,
      spot - grid + (top + 2) * pixel,
    );
  }

  List<String> _eggRows(int picture) {
    final egg = artOf(_species).egg;
    return gridRows(picture == 0 ? egg.whole : egg.cracks[picture - 1]);
  }
}

const _grid = 48;

final _sparkleFrames = [for (final f in sparkle.frames) gridRows(f)];

/// Places "+EXP" at [anchor], kept 8 UI pixels clear of the screen's right
/// edge, on whole UI pixels, raised [raised] UI pixels.
class _GainPlace extends SingleChildLayoutDelegate {
  _GainPlace({
    required this.anchor,
    required this.rightEdge,
    required this.ui,
    required this.raised,
  });

  final Offset anchor;
  final double rightEdge;
  final UiPixel ui;
  final int raised;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      const BoxConstraints();

  @override
  Offset getPositionForChild(Size size, Size childSize) => Offset(
    ui.snap(math.min(rightEdge - childSize.width - ui(8), anchor.dx)),
    ui.snap(anchor.dy) - ui(raised),
  );

  @override
  bool shouldRelayout(_GainPlace old) =>
      old.anchor != anchor ||
      old.rightEdge != rightEdge ||
      old.ui != ui ||
      old.raised != raised;
}

/// The EXP bar as a beat run shows it: [bar]'s lit blocks and the one
/// popping, with [caption] under it, and [plate] ("Level 13", "Task done")
/// stepping in 10 UI pixels below them all (spec §7.5, Tomo Pixel Screens).
class RewardBar extends StatelessWidget {
  const RewardBar({
    super.key,
    required this.bar,
    this.plate,
    this.caption,
    this.semanticLabel,
  });

  final BarShown bar;
  final Plate? plate;
  final Widget? caption;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final u = UiPixel.of(context);
    final colours = TomoTheme.of(context);
    final words = AppLocalizations.of(context);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            ExpBar(lit: bar.lit, pop: bar.pop, semanticLabel: semanticLabel),
            if (caption case final caption?) ...[
              SizedBox(height: u(2)),
              caption,
            ],
          ],
        ),
        if (plate case final plate?)
          Positioned(
            left: 0,
            right: 0,
            // Hung from the bar's foot, so the plate is as tall as it needs.
            bottom: 0,
            child: IgnorePointer(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: FractionalTranslation(
                  translation: const Offset(0, 1),
                  child: Transform.translate(
                    offset: Offset(0, u(10) - u(plate.dy)),
                    child: Opacity(
                      opacity: plate.opacity,
                      child: PixelBox(
                        fill: colours.surface,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: u(8),
                            vertical: u(3),
                          ),
                          child: PixelText.number(switch (plate.level) {
                            final level? => words.beatLevelPlate(level),
                            null => words.beatTaskPlate,
                          }, step: TypeStep.petName),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// [child] with the dither over it while [active]: the chrome behind a
/// Moment (spec §9.3). On the bare ground the dither cannot be seen, so only
/// the chrome it covers changes.
class DitherOver extends StatelessWidget {
  const DitherOver({super.key, required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      child,
      if (active)
        Positioned.fill(
          child: IgnorePointer(
            child: Dither(colour: TomoTheme.of(context).ground),
          ),
        ),
    ],
  );
}

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:tomo_core/art/compose.dart';
import 'package:tomo_core/art/pets/geode.dart';
import 'package:tomo_core/art/pets/joe.dart';
import 'package:tomo_core/art/pets/lily.dart';
import 'package:tomo_core/art/pixel_art.dart';

import 'sharp_text.dart';
import 'whole_dots.dart';

/// A bare screen for checking Tomo's pixels on a real phone (spec §18,
/// `docs/manual-checks.md` "Pixels on a real screen"): the four type steps at
/// any text size, every pet and egg at every spot, the dither, and the two
/// haptics. A builder's tool, not part of the product, so its words are not
/// in the copy file and release builds never show it.
class PixelCheckScreen extends StatefulWidget {
  const PixelCheckScreen({super.key});

  @override
  State<PixelCheckScreen> createState() => _PixelCheckScreenState();
}

/// The phone's own text setting, or a fixed one.
enum _TextSize {
  phone('Phone', null),
  p100('100%', 1),
  p130('130%', 1.3),
  p200('200%', 2);

  const _TextSize(this.label, this.factor);
  final String label;
  final double? factor;
}

/// The theme roles this screen uses (spec §9.1).
class _Colours {
  const _Colours({
    required this.ground,
    required this.surface,
    required this.sunken,
    required this.ink,
    required this.muted,
  });

  final Color ground, surface, sunken, ink, muted;

  static const light = _Colours(
    ground: Color(0xFFF5F1EA),
    surface: Color(0xFFFCFAF6),
    sunken: Color(0xFFEAE4DA),
    ink: Color(0xFF24211D),
    muted: Color(0xFF6A6359),
  );
  static const dark = _Colours(
    ground: Color(0xFF000000),
    surface: Color(0xFF161412),
    sunken: Color(0xFF24211D),
    ink: Color(0xFFEDE7DC),
    muted: Color(0xFFA39B8F),
  );
}

/// The spots a pet is painted in (spec §7.1): Home and the hatch takeover are
/// both 192 pt.
const _spots = [192.0, 168.0, 96.0];

const _species = [geode, joe, lily];

class _PixelCheckScreenState extends State<PixelCheckScreen> {
  bool? _dark;
  _TextSize _textSize = _TextSize.phone;
  bool _inDots = true;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final dark = _dark ?? media.platformBrightness == Brightness.dark;
    final factor = _textSize.factor;
    return MediaQuery(
      data: factor == null
          ? media
          : media.copyWith(textScaler: TextScaler.linear(factor)),
      child: SharpText(
        child: _TextInDots(
          inDots: _inDots,
          child: _Body(
            colours: dark ? _Colours.dark : _Colours.light,
            dark: dark,
            textSize: _textSize,
            onDark: (value) => setState(() => _dark = value),
            onTextSize: (value) => setState(() => _textSize = value),
            onInDots: (value) => setState(() => _inDots = value),
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.colours,
    required this.dark,
    required this.textSize,
    required this.onDark,
    required this.onTextSize,
    required this.onInDots,
  });

  final _Colours colours;
  final bool dark;
  final _TextSize textSize;
  final ValueChanged<bool> onDark;
  final ValueChanged<_TextSize> onTextSize;
  final ValueChanged<bool> onInDots;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final screen = MediaQuery.sizeOf(context) * dpr;
    // One UI pixel: one body font pixel (ADR-0017).
    final u = bodyDots(dpr) / dpr;
    final scaler = SharpText.of(context);

    Widget text(String words, {TypeStep step = TypeStep.body, Color? colour}) =>
        _Words(words, step: step, colour: colour ?? colours.ink);

    Widget heading(String words) => Padding(
      padding: EdgeInsets.only(top: 12 * u, bottom: 4 * u),
      child: text(words, step: TypeStep.title),
    );

    Widget button(String label, VoidCallback onTap, {bool on = false}) =>
        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
            child: ColoredBox(
              color: on ? colours.ink : colours.sunken,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 6 * u),
                child: Align(
                  widthFactor: 1,
                  heightFactor: 1,
                  child: text(label, colour: on ? colours.ground : colours.ink),
                ),
              ),
            ),
          ),
        );

    final fontSize = TypeStep.body.style(dpr, colours.ink).fontSize!;
    final askedPercent = (MediaQuery.textScalerOf(context) as SharpTextScaler)
        .inner
        .scale(100);

    return ColoredBox(
      color: colours.ground,
      child: DefaultTextStyle(
        style: TypeStep.body.style(dpr, colours.ink),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(8 * u),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                text('Pixel check', step: TypeStep.petName),
                text(
                  '${_number(dpr)}× · ${screen.width.round()} × '
                  '${screen.height.round()} dots · body ${bodyDots(dpr)} dots '
                  'per font pixel · text ${askedPercent.round()}% asked, body '
                  'now ${_number(scaler.scale(fontSize) * dpr / 12)} dots',
                  step: TypeStep.caption,
                  colour: colours.muted,
                ),
                SizedBox(height: 6 * u),
                Wrap(
                  spacing: 2 * u,
                  runSpacing: 2 * u,
                  children: [
                    button('Light', () => onDark(false), on: !dark),
                    button('Dark', () => onDark(true), on: dark),
                  ],
                ),
                SizedBox(height: 2 * u),
                Wrap(
                  spacing: 2 * u,
                  runSpacing: 2 * u,
                  children: [
                    for (final size in _TextSize.values)
                      button(
                        size.label,
                        () => onTextSize(size),
                        on: size == textSize,
                      ),
                  ],
                ),
                SizedBox(height: 2 * u),
                Wrap(
                  spacing: 2 * u,
                  runSpacing: 2 * u,
                  children: [
                    button(
                      'Text in points',
                      () => onInDots(false),
                      on: !_TextInDots.of(context),
                    ),
                    button(
                      'Text in dots',
                      () => onInDots(true),
                      on: _TextInDots.of(context),
                    ),
                  ],
                ),
                heading('Type'),
                for (final step in TypeStep.values)
                  Padding(
                    padding: EdgeInsets.only(bottom: 4 * u),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        text(
                          '${step.name} · ${_dotsAt(context, step)} dots per '
                          'font pixel',
                          step: TypeStep.caption,
                          colour: colours.muted,
                        ),
                        text(_samples[step]!, step: step),
                      ],
                    ),
                  ),
                heading('Pets'),
                for (final species in _species) ...[
                  text(species.name),
                  SizedBox(height: 2 * u),
                  Wrap(
                    spacing: 4 * u,
                    runSpacing: 4 * u,
                    crossAxisAlignment: WrapCrossAlignment.end,
                    children: [
                      for (final picture in [
                        composeStage(species, 0),
                        gridRows(species.egg.whole),
                      ])
                        for (final spot in _spots)
                          _PetInSpot(
                            spot: spot,
                            rows: picture,
                            species: species,
                            colours: colours,
                          ),
                    ],
                  ),
                  SizedBox(height: 6 * u),
                ],
                heading('Dither'),
                text(
                  'Right half: every other dot in the ground colour.',
                  step: TypeStep.caption,
                  colour: colours.muted,
                ),
                SizedBox(height: 2 * u),
                _DitherPatch(colours: colours),
                heading('Haptics'),
                text(
                  'No vibrate permission is in the manifest.',
                  step: TypeStep.caption,
                  colour: colours.muted,
                ),
                SizedBox(height: 2 * u),
                Wrap(
                  spacing: 2 * u,
                  runSpacing: 2 * u,
                  children: [
                    button('Timer buzz', HapticFeedback.vibrate),
                    button('Reward tap', HapticFeedback.lightImpact),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Dots per font pixel [step] comes to at the text size in effect.
  static int _dotsAt(BuildContext context, TypeStep step) {
    final scaler = SharpText.of(context);
    return (step == TypeStep.petName ? scaler.capped() : scaler).dotsFor(
      step.dots(MediaQuery.devicePixelRatioOf(context)),
    );
  }
}

const _samples = {
  TypeStep.caption: 'About 19 min left · 2 of 4 blocks',
  TypeStep.body:
      'The quick brown fox jumps over the lazy dog. 0123456789 '
      '“Quotes”, it’s — dashes… Łukasz, Zoë.',
  TypeStep.title: 'Stop this block?',
  TypeStep.petName: 'Geode 480',
};

String _number(double value) =>
    value == value.roundToDouble() ? '${value.round()}' : '$value';

/// One line or paragraph of text: a [PixelText], or, to compare, the same
/// laid out in points and moved to start on a whole dot.
class _Words extends StatelessWidget {
  const _Words(this.words, {required this.step, required this.colour});

  final String words;
  final TypeStep step;
  final Color colour;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final scaler = step == TypeStep.petName
        ? SharpText.of(context).capped()
        : SharpText.of(context);
    if (!_TextInDots.of(context)) {
      return OnWholeDots(
        child: Text(words, style: step.style(dpr, colour), textScaler: scaler),
      );
    }
    return PixelText(words, step: step, colour: colour);
  }
}

/// Whether text below is laid out in dots ([InDots]) or in points.
class _TextInDots extends InheritedWidget {
  const _TextInDots({required this.inDots, required super.child});

  final bool inDots;

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_TextInDots>()!.inDots;

  @override
  bool updateShouldNotify(_TextInDots old) => old.inDots != inDots;
}

class _PetInSpot extends StatelessWidget {
  const _PetInSpot({
    required this.spot,
    required this.rows,
    required this.species,
    required this.colours,
  });

  final double spot;
  final List<String> rows;
  final SpeciesArt species;
  final _Colours colours;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final dots = dotsPerPixel(spot: spot, gridSize: 48, devicePixelRatio: dpr);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        PixelGrid(
          rows: rows,
          colours: {
            for (final MapEntry(:key, :value) in species.colours.entries)
              key: Color(value),
          },
          dots: dots,
        ),
        _Words(
          '${spot.round()} pt · $dots dots',
          step: TypeStep.caption,
          colour: colours.muted,
        ),
      ],
    );
  }
}

/// A surface with Joe on it, the right half under the dither.
class _DitherPatch extends StatelessWidget {
  const _DitherPatch({required this.colours});

  final _Colours colours;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final u = bodyDots(dpr) / dpr;
    return ColoredBox(
      color: colours.surface,
      child: Padding(
        padding: EdgeInsets.all(8 * u),
        child: Stack(
          children: [
            Wrap(
              spacing: 8 * u,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                PixelGrid.inSpot(
                  spot: 168,
                  rows: composeStage(joe, 0),
                  colours: {
                    for (final MapEntry(:key, :value) in joe.colours.entries)
                      key: Color(value),
                  },
                ),
                _Words(
                  'Behind a sheet',
                  step: TypeStep.title,
                  colour: colours.ink,
                ),
              ],
            ),
            Positioned.fill(
              child: FractionallySizedBox(
                alignment: Alignment.centerRight,
                widthFactor: 0.5,
                child: Dither(colour: colours.ground),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

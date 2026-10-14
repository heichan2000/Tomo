import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'whole_dots.dart';

/// Tomo's one font (spec §9.2, ADR-0016): Ark Pixel 12px Proportional, a
/// bundled Latin subset.
const arkPixel = 'ArkPixel';

/// Ark Pixel is drawn on a 12-pixel em.
const _em = 12;

/// Ark Pixel's own line, ascent 13 plus descent 3, in font pixels.
const _line = 16;

/// The text roles, each a whole number of screen dots per font pixel set from
/// body (spec §9.2, ADR-0017).
enum TypeStep {
  caption,
  body,
  title,
  petName;

  /// Dots per font pixel for this step on a screen of [dpr], at 100% text.
  int dots(double dpr) {
    final body = bodyDots(dpr);
    return switch (this) {
      caption => math.max(1, body - 1),
      TypeStep.body => body,
      title => body + 1,
      petName => 2 * body,
    };
  }

  /// This step's style at 100% text. [SharpTextScaler] keeps it sharp above.
  TextStyle style(double dpr, Color colour) => TextStyle(
    fontFamily: arkPixel,
    fontSize: sharpFontSize(dots(dpr), dpr),
    height: _line / _em,
    color: colour,
  );
}

/// Body text's dots per font pixel: about a 10 pt x-height.
int bodyDots(double dpr) => math.max(1, (1.667 * dpr).round());

/// The font size, in logical pixels, at which each font pixel is [n] dots.
double sharpFontSize(int n, double dpr) => _em * n / dpr;

/// Wraps the phone's text scaler so every size lands on a sharp one (ADR-0016).
///
/// At 100% or below it rounds to the nearest whole number of dots per font
/// pixel; above 100% it rounds **up**, so text is never smaller than asked
/// for. It never goes below one dot.
class SharpTextScaler extends TextScaler {
  const SharpTextScaler(this.inner, {required this.devicePixelRatio});

  /// The phone's scaler, after any clamp.
  final TextScaler inner;
  final double devicePixelRatio;

  /// The same, with the phone's text setting stopping at 130%: for numbers
  /// and the pet's name (spec §9.2).
  SharpTextScaler capped() => SharpTextScaler(
    inner.clamp(maxScaleFactor: 1.3),
    devicePixelRatio: devicePixelRatio,
  );

  /// The dots per font pixel a step of [n] dots comes to at this scale.
  int dotsFor(int n) =>
      (scale(sharpFontSize(n, devicePixelRatio)) * devicePixelRatio / _em)
          .round();

  @override
  double scale(double fontSize) {
    final asked = inner.scale(fontSize);
    final dots = asked * devicePixelRatio / _em;
    // A hair of slack, so a size that is sharp already isn't pushed up a step
    // by rounding error.
    final n = asked > fontSize + 1e-9 ? (dots - 1e-6).ceil() : dots.round();
    return sharpFontSize(math.max(1, n), devicePixelRatio);
  }

  @override
  @Deprecated('Use scale() instead.')
  // ignore: deprecated_member_use
  double get textScaleFactor => inner.textScaleFactor;

  @override
  bool operator ==(Object other) =>
      other is SharpTextScaler &&
      other.inner == inner &&
      other.devicePixelRatio == devicePixelRatio;

  @override
  int get hashCode => Object.hash(inner, devicePixelRatio);
}

/// Makes every [Text] below it use sharp sizes, by wrapping the phone's text
/// scaler in a [SharpTextScaler].
class SharpText extends StatelessWidget {
  const SharpText({super.key, required this.child});

  final Widget child;

  /// The sharp scaler in effect at [context].
  static SharpTextScaler of(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    return scaler is SharpTextScaler
        ? scaler
        : SharpTextScaler(
            scaler,
            devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
          );
  }

  @override
  Widget build(BuildContext context) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: of(context)),
    child: child,
  );
}

/// Text in Tomo's font at a sharp size, laid out in screen dots.
///
/// Laid out in points, a letter's position is a fraction of a dot on most
/// phones (2.8125 dots per point on the test phone), and some letters land a
/// quarter dot off. Laid out in dots, with the font size a whole number of
/// dots, every advance and line is a whole number, and the text starts on a
/// whole dot ([InDots]). Checked on the real phone (spec §18).
class PixelText extends StatelessWidget {
  const PixelText(
    this.words, {
    super.key,
    this.step = TypeStep.body,
    required this.colour,
  });

  final String words;
  final TypeStep step;
  final Color colour;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final scaler = SharpText.of(context);
    final n = (step == TypeStep.petName ? scaler.capped() : scaler).dotsFor(
      step.dots(dpr),
    );
    return InDots(
      child: Text(
        words,
        style: step.style(dpr, colour).copyWith(fontSize: _em * n.toDouble()),
        textScaler: TextScaler.noScaling,
      ),
    );
  }
}

import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'tomo_theme.dart';
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

/// Dots per font pixel [step] comes to at [context]'s text setting.
int dotsAt(BuildContext context, TypeStep step) =>
    SharpText.of(context)
        .dotsFor(step.dots(MediaQuery.devicePixelRatioOf(context)));

/// How tall one line of text is, in dots, at [n] dots per font pixel.
int lineDots(int n) => _line * n;

/// How wide [words] are on one line, in dots, at [n] dots per font pixel.
double lineWidthDots(String words, int n, TextDirection direction) {
  final painter = TextPainter(
    text: TextSpan(
      text: words,
      style: TextStyle(
        fontFamily: arkPixel,
        fontSize: _em * n.toDouble(),
        height: _line / _em,
      ),
    ),
    textDirection: direction,
    textScaler: TextScaler.noScaling,
    maxLines: 1,
  )..layout();
  final width = painter.width;
  painter.dispose();
  return width;
}

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
///
/// Centred and end-aligned lines are each moved to start on a whole dot too,
/// so text is never centred to a half dot (ADR-0017).
///
/// [colour] defaults to the theme's ink. A [header] is a screen's or a
/// sheet's title, or a group's label, and a screen reader says so.
class PixelText extends StatelessWidget {
  const PixelText(
    this.words, {
    super.key,
    this.step = TypeStep.body,
    this.colour,
    this.textAlign = TextAlign.start,
    this.header = false,
  }) : _oneLine = step == TypeStep.petName,
       _cut = false;

  /// Words on one line that end in "…" when they don't fit, growing with the
  /// phone's text setting as body text does: the running banner's task,
  /// whose time under it carries the news. Start-aligned.
  const PixelText.cut(
    this.words, {
    super.key,
    this.step = TypeStep.body,
    this.colour,
  }) : textAlign = TextAlign.start,
       header = false,
       _oneLine = false,
       _cut = true;

  /// A number or a time (spec §9.2): it stops growing at 130% of the phone's
  /// text setting, never wraps, and steps down to the largest sharp size that
  /// fits. The pet's name ([TypeStep.petName]) always works this way.
  const PixelText.number(
    this.words, {
    super.key,
    this.step = TypeStep.body,
    this.colour,
    this.textAlign = TextAlign.start,
  }) : header = false,
       _oneLine = true,
       _cut = false;

  final String words;
  final TypeStep step;
  final Color? colour;
  final TextAlign textAlign;
  final bool header;
  final bool _oneLine;
  final bool _cut;

  @override
  Widget build(BuildContext context) {
    final text = _text(context);
    return header ? Semantics(header: true, child: text) : text;
  }

  Widget _text(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final scaler = SharpText.of(context);
    final n = (_oneLine ? scaler.capped() : scaler).dotsFor(step.dots(dpr));
    final style = step.style(dpr, colour ?? TomoTheme.of(context).ink);
    if (_cut) {
      return InDots(
        child: Text(
          words,
          style: style.copyWith(fontSize: _em * n.toDouble()),
          textScaler: TextScaler.noScaling,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }
    if (!_oneLine) return InDots(child: _lines(style, n));
    return LayoutBuilder(
      builder: (context, constraints) {
        final room = constraints.maxWidth * dpr;
        var fits = n;
        final direction = Directionality.of(context);
        while (fits > 1 &&
            lineWidthDots(words, fits, direction) > room + 1e-6) {
          fits--;
        }
        return InDots(child: _lines(style, fits, oneLine: true));
      },
    );
  }

  /// Laid out in dots: a font pixel is [n] dots.
  Widget _lines(TextStyle style, int n, {bool oneLine = false}) {
    final sized = style.copyWith(fontSize: _em * n.toDouble());
    if (textAlign == TextAlign.start || textAlign == TextAlign.left) {
      return Text(
        words,
        style: sized,
        textScaler: TextScaler.noScaling,
        maxLines: oneLine ? 1 : null,
        softWrap: !oneLine,
      );
    }
    return _LinesOnWholeDots(
      text: TextSpan(text: words, style: sized),
      textAlign: textAlign,
      oneLine: oneLine,
    );
  }
}

/// Text whose lines are each moved, when painting, to start on a whole dot.
/// Lives inside [InDots], where one unit is one dot.
class _LinesOnWholeDots extends LeafRenderObjectWidget {
  const _LinesOnWholeDots({
    required this.text,
    required this.textAlign,
    required this.oneLine,
  });

  final TextSpan text;
  final TextAlign textAlign;
  final bool oneLine;

  @override
  RenderLinesOnWholeDots createRenderObject(BuildContext context) =>
      RenderLinesOnWholeDots(
        text: text,
        textAlign: textAlign,
        textDirection: Directionality.of(context),
        maxLines: oneLine ? 1 : null,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    RenderLinesOnWholeDots renderObject,
  ) => renderObject
    ..text = text
    ..textAlign = textAlign
    ..textDirection = Directionality.of(context)
    ..maxLines = oneLine ? 1 : null;
}

class RenderLinesOnWholeDots extends RenderBox {
  RenderLinesOnWholeDots({
    required TextSpan text,
    required TextAlign textAlign,
    required TextDirection textDirection,
    int? maxLines,
  }) : _painter = TextPainter(
         text: text,
         textAlign: textAlign,
         textDirection: textDirection,
         maxLines: maxLines,
         textScaler: TextScaler.noScaling,
       );

  final TextPainter _painter;

  set text(TextSpan value) {
    if (_painter.text == value) return;
    _painter.text = value;
    markNeedsLayout();
    markNeedsSemanticsUpdate();
  }

  set textAlign(TextAlign value) {
    if (_painter.textAlign == value) return;
    _painter.textAlign = value;
    markNeedsLayout();
  }

  set textDirection(TextDirection value) {
    if (_painter.textDirection == value) return;
    _painter.textDirection = value;
    markNeedsLayout();
  }

  set maxLines(int? value) {
    if (_painter.maxLines == value) return;
    _painter.maxLines = value;
    markNeedsLayout();
  }

  @override
  void dispose() {
    _painter.dispose();
    super.dispose();
  }

  /// Lays the text out as narrow as its longest line, so the lines are
  /// placed within that width and nothing else moves them.
  void _layoutText(double maxWidth) {
    _painter.layout(maxWidth: maxWidth);
    final longest = _painter.computeLineMetrics().fold(
      0.0,
      (widest, line) => math.max(widest, line.width),
    );
    if (longest < _painter.width) {
      _painter.layout(minWidth: longest, maxWidth: longest);
    }
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    _layoutText(double.infinity);
    return _painter.minIntrinsicWidth;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    _layoutText(double.infinity);
    return _painter.maxIntrinsicWidth;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    _layoutText(width);
    return _painter.height;
  }

  @override
  double computeMaxIntrinsicHeight(double width) =>
      computeMinIntrinsicHeight(width);

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    _layoutText(constraints.maxWidth);
    return constraints.constrain(_painter.size);
  }

  @override
  void performLayout() {
    _layoutText(constraints.maxWidth);
    size = constraints.constrain(_painter.size);
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) {
    _layoutText(constraints.maxWidth);
    return _painter.computeDistanceToActualBaseline(baseline);
  }

  /// Where the painter's lines start across the box, which may be wider
  /// than the longest line.
  double get _start => switch (_painter.textAlign) {
    TextAlign.center => (size.width - _painter.width) / 2,
    TextAlign.end || TextAlign.right => size.width - _painter.width,
    _ => 0.0,
  };

  /// Where each line starts inside the painter, before it is moved.
  @visibleForTesting
  List<double> get debugLineLefts {
    _layoutText(constraints.maxWidth);
    return [for (final line in _painter.computeLineMetrics()) line.left];
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    _layoutText(constraints.maxWidth);
    final start = _start;
    final canvas = context.canvas;
    var top = 0.0;
    for (final line in _painter.computeLineMetrics()) {
      final left = start + line.left;
      // This line alone, moved to start on a whole dot.
      final shift = left.roundToDouble() - left;
      canvas
        ..save()
        ..clipRect(
          Rect.fromLTWH(
            offset.dx - line.width,
            offset.dy + top,
            size.width + 2 * line.width,
            line.height,
          ),
        );
      _painter.paint(canvas, offset + Offset(start + shift, 0));
      canvas.restore();
      top += line.height;
    }
  }

  // Like a paragraph, a tap on the words lands on them.
  @override
  bool hitTestSelf(Offset position) => true;

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    config
      ..label = _painter.text!.toPlainText()
      ..textDirection = _painter.textDirection;
  }
}

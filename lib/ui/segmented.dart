import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'buttons.dart';
import 'pixel_box.dart';
import 'sharp_text.dart';
import 'tomo_theme.dart';
import 'ui_pixel.dart';

/// One choice in a [PixelSegmented].
@immutable
class Segment<T> {
  const Segment(this.value, this.label);

  final T value;
  final String label;
}

/// A segmented control (spec §9.3): a sunken track with the chosen option in
/// the accent. When every option fits on one row they share it equally and
/// stand one height, the tallest's, so a two-line label (*Custom* over
/// *15 min*) keeps the row's shape; when one doesn't, the options stack one
/// per row. It wraps rather than clips, and each option is at least 48 pt
/// tall.
class PixelSegmented<T> extends StatelessWidget {
  const PixelSegmented({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
  });

  final List<Segment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  /// Whether [labels] fit side by side in [width] dots, each in an equal
  /// share with two UI pixels either side, one UI pixel apart.
  static bool fitsOnOneRow({
    required List<double> labels,
    required double width,
    required int uiPixel,
  }) {
    final widest = labels.fold(0.0, math.max) + 4 * uiPixel;
    return widest * labels.length + (labels.length - 1) * uiPixel <=
        width + 1e-6;
  }

  @override
  Widget build(BuildContext context) {
    final colours = TomoTheme.of(context);
    final u = UiPixel.of(context);
    final dpr = u.devicePixelRatio;
    final n = dotsAt(context, TypeStep.caption);
    final direction = Directionality.of(context);
    final vertical =
        math.max(5 * u.dots, ((48 * dpr - lineDots(n)) / 2).ceil()) / dpr;

    Widget option(Segment<T> segment) {
      final chosen = segment.value == selected;
      return Pressable(
        onPressed: () => onChanged(segment.value),
        button: false,
        selected: chosen,
        inMutuallyExclusiveGroup: true,
        builder: (context, pressed, ring) {
          final fill = chosen ? colours.accent : null;
          return PixelBox(
            fill: pressed ? colours.pressed(fill ?? colours.sunken) : fill,
            ring: ring ? colours.accent : null,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: u(2),
                vertical: vertical,
              ),
              child: Center(
                heightFactor: 1,
                child: PixelText(
                  segment.label,
                  step: TypeStep.caption,
                  colour: chosen ? colours.onAccent : colours.ink,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        },
      );
    }

    return PixelBox(
      fill: colours.sunken,
      child: Padding(
        padding: EdgeInsets.all(u(1)),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Shares are counted in whole dots, so every gap is one UI pixel.
            final width = (constraints.maxWidth * dpr).floor();
            final oneRow = fitsOnOneRow(
              labels: [
                // A label on two lines is as wide as its wider line.
                for (final s in segments)
                  for (final line in s.label.split('\n'))
                    lineWidthDots(line, n, direction),
              ],
              width: width.toDouble(),
              uiPixel: u.dots,
            );
            if (!oneRow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (i, s) in segments.indexed) ...[
                    if (i > 0) SizedBox(height: u(1)),
                    option(s),
                  ],
                ],
              );
            }
            final count = segments.length;
            final room = width - (count - 1) * u.dots;
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (i, s) in segments.indexed) ...[
                    if (i > 0) SizedBox(width: u(1)),
                    SizedBox(
                      // The dots left over go to the first shares.
                      width: (room ~/ count + (i < room % count ? 1 : 0)) / dpr,
                      child: option(s),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

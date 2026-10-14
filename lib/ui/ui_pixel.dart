import 'package:flutter/widgets.dart';

import 'sharp_text.dart';

/// The UI pixel (spec §9.3, ADR-0017): one font pixel of body text at 100%,
/// so a whole number of screen dots. Lines, corners, gaps, icon strokes and
/// movement are whole UI pixels, and they stay fixed when the phone's text
/// size changes; only text grows.
@immutable
class UiPixel {
  UiPixel(this.devicePixelRatio) : dots = bodyDots(devicePixelRatio);

  /// The UI pixel on the screen at [context].
  factory UiPixel.of(BuildContext context) =>
      UiPixel(MediaQuery.devicePixelRatioOf(context));

  final double devicePixelRatio;

  /// Screen dots per UI pixel.
  final int dots;

  /// One UI pixel in logical points.
  double get pt => dots / devicePixelRatio;

  /// [n] UI pixels in logical points.
  double call(num n) => n * pt;

  /// The fewest whole UI pixels covering [points], in logical points.
  double atLeast(double points) =>
      (points / pt - 1e-9).ceilToDouble().clamp(0, double.infinity) * pt;

  /// The smallest touch target, 48 pt, in whole UI pixels (spec §12).
  double get target => atLeast(48);

  /// [points] rounded to the nearest whole UI pixel.
  double snap(double points) => (points / pt).roundToDouble() * pt;

  @override
  bool operator ==(Object other) =>
      other is UiPixel && other.devicePixelRatio == devicePixelRatio;

  @override
  int get hashCode => devicePixelRatio.hashCode;
}

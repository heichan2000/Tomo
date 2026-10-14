import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'sharp_text.dart';

/// Where a box laid out at [topLeft] (global, logical points) and [size]
/// lands on the screen, with every edge moved to the nearest whole dot. In
/// dots. Its start *and* its end are whole, so no faint line shows where it
/// meets the next one (#60).
Rect wholeDotRect(Offset topLeft, Size size, double devicePixelRatio) {
  final d = devicePixelRatio;
  return Rect.fromLTRB(
    (topLeft.dx * d).roundToDouble(),
    (topLeft.dy * d).roundToDouble(),
    ((topLeft.dx + size.width) * d).roundToDouble(),
    ((topLeft.dy + size.height) * d).roundToDouble(),
  );
}

/// The outline of [r] with its corners cut in steps of [unit]: row `i` from
/// each edge starts `steps[i]` units in. `[1]` is a corner that loses one
/// pixel (ADR-0017); `[2, 1]` rounds in two steps, as the focus ring does.
List<Offset> steppedOutline(Rect r, List<int> steps, double unit) {
  final k = steps.length;
  final p = <Offset>[Offset(r.left, r.top + k * unit)];
  for (var i = k - 1; i >= 0; i--) {
    p
      ..add(Offset(r.left + steps[i] * unit, r.top + (i + 1) * unit))
      ..add(Offset(r.left + steps[i] * unit, r.top + i * unit));
  }
  for (var i = 0; i < k; i++) {
    p
      ..add(Offset(r.right - steps[i] * unit, r.top + i * unit))
      ..add(Offset(r.right - steps[i] * unit, r.top + (i + 1) * unit));
  }
  p
    ..add(Offset(r.right, r.top + k * unit))
    ..add(Offset(r.right, r.bottom - k * unit));
  for (var i = k - 1; i >= 0; i--) {
    p
      ..add(Offset(r.right - steps[i] * unit, r.bottom - (i + 1) * unit))
      ..add(Offset(r.right - steps[i] * unit, r.bottom - i * unit));
  }
  for (var i = 0; i < k; i++) {
    p
      ..add(Offset(r.left + steps[i] * unit, r.bottom - i * unit))
      ..add(Offset(r.left + steps[i] * unit, r.bottom - (i + 1) * unit));
  }
  p.add(Offset(r.left, r.bottom - k * unit));
  return p;
}

/// A box of chrome (spec §9.3, ADR-0017, "quiet steps"): a flat [fill] whose
/// corners each lose one UI pixel, painted on whole screen dots.
///
/// - [outline] draws a line [outlineWidth] UI pixels wide inside the edge.
///   Only text fields have one.
/// - [ring] draws the keyboard-focus ring outside the box: one UI pixel of
///   the colour, one UI pixel clear between it and the box, its corners
///   rounded in two steps.
///
/// Layout stays in points. When it paints, the box's edges move to the
/// nearest whole dot, so a box placed a fraction of a dot off still has crisp
/// edges and meets its neighbour without a seam. Keep [RepaintBoundary]s out
/// from between a box and a scroll view, or it won't re-snap as it scrolls.
class PixelBox extends SingleChildRenderObjectWidget {
  const PixelBox({
    super.key,
    this.fill,
    this.outline,
    this.outlineWidth = 1,
    this.ring,
    this.cutCorners = true,
    super.child,
  });

  final Color? fill;
  final Color? outline;

  /// In UI pixels.
  final int outlineWidth;

  final Color? ring;

  /// Whether each corner loses one UI pixel. Every box does (ADR-0017); only
  /// a box meant to read as a single pixel block, such as an EXP block, keeps
  /// its corners.
  final bool cutCorners;

  @override
  RenderPixelBox createRenderObject(BuildContext context) => RenderPixelBox(
    fill: fill,
    outline: outline,
    outlineWidth: outlineWidth,
    ring: ring,
    cutCorners: cutCorners,
    devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
  );

  @override
  void updateRenderObject(BuildContext context, RenderPixelBox renderObject) =>
      renderObject
        ..fill = fill
        ..outline = outline
        ..outlineWidth = outlineWidth
        ..ring = ring
        ..cutCorners = cutCorners
        ..devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
}

class RenderPixelBox extends RenderProxyBox {
  RenderPixelBox({
    this._fill,
    this._outline,
    required this._outlineWidth,
    this._ring,
    required this._cutCorners,
    required this._devicePixelRatio,
  });

  Color? _fill;
  set fill(Color? value) {
    if (value == _fill) return;
    _fill = value;
    markNeedsPaint();
  }

  Color? _outline;
  set outline(Color? value) {
    if (value == _outline) return;
    _outline = value;
    markNeedsPaint();
  }

  int _outlineWidth;
  set outlineWidth(int value) {
    if (value == _outlineWidth) return;
    _outlineWidth = value;
    markNeedsPaint();
  }

  Color? _ring;
  set ring(Color? value) {
    if (value == _ring) return;
    _ring = value;
    markNeedsPaint();
  }

  bool _cutCorners;
  set cutCorners(bool value) {
    if (value == _cutCorners) return;
    _cutCorners = value;
    markNeedsPaint();
  }

  double _devicePixelRatio;
  set devicePixelRatio(double value) {
    if (value == _devicePixelRatio) return;
    _devicePixelRatio = value;
    markNeedsPaint();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_fill != null || _outline != null || _ring != null) {
      _paintBox(context.canvas, offset);
    }
    super.paint(context, offset);
  }

  void _paintBox(Canvas canvas, Offset offset) {
    final dpr = _devicePixelRatio;
    final global = localToGlobal(Offset.zero);
    final dots = wholeDotRect(global, size, dpr);
    if (dots.isEmpty) return;
    final u = bodyDots(dpr).toDouble();
    final box = dots.shift(-dots.topLeft);
    final corner = _cutCorners && box.shortestSide > 2 * u ? [1] : <int>[];
    final paint = Paint()..isAntiAlias = false;

    Path shape(Rect r, List<int> steps) =>
        Path()..addPolygon(steppedOutline(r, steps, u), true);

    canvas
      ..save()
      // From here on, one unit is one screen dot, and (0, 0) is the box's
      // top-left on a whole dot.
      ..translate(
        offset.dx + dots.left / dpr - global.dx,
        offset.dy + dots.top / dpr - global.dy,
      )
      ..scale(1 / dpr);

    final ring = _ring;
    if (ring != null) {
      canvas.drawPath(
        Path.combine(
          ui.PathOperation.difference,
          shape(box.inflate(2 * u), [2, 1]),
          shape(box.inflate(u), [1]),
        ),
        paint..color = ring,
      );
    }

    final outline = _outline;
    if (outline != null && _outlineWidth > 0) {
      final inner = box.deflate(_outlineWidth * u);
      canvas.drawPath(
        Path.combine(
          ui.PathOperation.difference,
          shape(box, corner),
          Path()..addRect(inner),
        ),
        paint..color = outline,
      );
      if (_fill != null) canvas.drawRect(inner, paint..color = _fill!);
    } else if (_fill != null) {
      canvas.drawPath(shape(box, corner), paint..color = _fill!);
    }

    canvas.restore();
  }
}

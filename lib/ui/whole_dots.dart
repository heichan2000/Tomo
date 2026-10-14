import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Painting on whole screen dots (spec §7.1, §9.3, ADR-0014, ADR-0017).
///
/// Flutter lays out in logical points, and on most phones a point is not a
/// whole number of dots (2.625, 2.8125 …). Anything that has to be sharp is
/// moved, when it paints, to start on the nearest whole dot of the screen.
/// That move is under one dot, so layout never notices it.

/// The largest whole number of dots per pixel at which a grid [gridSize]
/// pixels wide fits in [spot] points, never below 2 (ADR-0014).
int dotsPerPixel({
  required double spot,
  required int gridSize,
  required double devicePixelRatio,
}) => math.max(2, (spot * devicePixelRatio / gridSize + 1e-9).floor());

/// How far [box], about to paint at [offset], must move so its top-left lands
/// on a whole screen dot, in logical points.
Offset _toWholeDot(RenderBox box, double devicePixelRatio) {
  final global = box.localToGlobal(Offset.zero) * devicePixelRatio;
  return Offset(
        global.dx.roundToDouble() - global.dx,
        global.dy.roundToDouble() - global.dy,
      ) /
      devicePixelRatio;
}

/// Moves its child, when painting, so it starts on a whole screen dot.
///
/// For text: Ark Pixel's advances and line are whole font pixels, so a line
/// that starts on a whole dot stays on whole dots.
class OnWholeDots extends SingleChildRenderObjectWidget {
  const OnWholeDots({super.key, super.child});

  @override
  RenderOnWholeDots createRenderObject(BuildContext context) =>
      RenderOnWholeDots(MediaQuery.devicePixelRatioOf(context));

  @override
  void updateRenderObject(
    BuildContext context,
    RenderOnWholeDots renderObject,
  ) => renderObject.devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
}

class RenderOnWholeDots extends RenderProxyBox {
  RenderOnWholeDots(this._devicePixelRatio);

  double _devicePixelRatio;
  set devicePixelRatio(double value) {
    if (value == _devicePixelRatio) return;
    _devicePixelRatio = value;
    markNeedsPaint();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null) return;
    context.paintChild(child!, offset + _toWholeDot(this, _devicePixelRatio));
  }
}

/// Lays its child out in screen dots instead of points, then draws it scaled
/// back down, starting on a whole dot. Inside, one unit is one dot, so whole
/// numbers stay whole all the way to the screen.
class InDots extends SingleChildRenderObjectWidget {
  const InDots({super.key, super.child});

  @override
  RenderInDots createRenderObject(BuildContext context) =>
      RenderInDots(MediaQuery.devicePixelRatioOf(context));

  @override
  void updateRenderObject(BuildContext context, RenderInDots renderObject) =>
      renderObject.devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
}

class RenderInDots extends RenderProxyBox {
  RenderInDots(this._devicePixelRatio);

  double _devicePixelRatio;
  set devicePixelRatio(double value) {
    if (value == _devicePixelRatio) return;
    _devicePixelRatio = value;
    markNeedsLayout();
  }

  Matrix4 get _shrink =>
      Matrix4.diagonal3Values(1 / _devicePixelRatio, 1 / _devicePixelRatio, 1);

  BoxConstraints _inDots(BoxConstraints c) {
    final dpr = _devicePixelRatio;
    return BoxConstraints(
      minWidth: c.minWidth * dpr,
      maxWidth: c.maxWidth * dpr,
      minHeight: c.minHeight * dpr,
      maxHeight: c.maxHeight * dpr,
    );
  }

  @override
  void performLayout() {
    final c = constraints;
    if (child == null) {
      size = c.smallest;
      return;
    }
    child!.layout(_inDots(c), parentUsesSize: true);
    size = c.constrain(child!.size / _devicePixelRatio);
  }

  // Asked from outside in points, answered inside in dots.

  @override
  Size computeDryLayout(BoxConstraints constraints) => child == null
      ? constraints.smallest
      : constraints.constrain(
          child!.getDryLayout(_inDots(constraints)) / _devicePixelRatio,
        );

  @override
  double computeMinIntrinsicWidth(double height) =>
      (child?.getMinIntrinsicWidth(height * _devicePixelRatio) ?? 0) /
      _devicePixelRatio;

  @override
  double computeMaxIntrinsicWidth(double height) =>
      (child?.getMaxIntrinsicWidth(height * _devicePixelRatio) ?? 0) /
      _devicePixelRatio;

  @override
  double computeMinIntrinsicHeight(double width) =>
      (child?.getMinIntrinsicHeight(width * _devicePixelRatio) ?? 0) /
      _devicePixelRatio;

  @override
  double computeMaxIntrinsicHeight(double width) =>
      (child?.getMaxIntrinsicHeight(width * _devicePixelRatio) ?? 0) /
      _devicePixelRatio;

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) {
    final distance = child?.getDistanceToActualBaseline(baseline);
    return distance == null ? null : distance / _devicePixelRatio;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null) return;
    context.pushTransform(
      needsCompositing,
      offset + _toWholeDot(this, _devicePixelRatio),
      _shrink,
      (context, offset) => context.paintChild(child!, offset),
    );
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) =>
      transform.multiply(_shrink);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      result.addWithPaintTransform(
        transform: _shrink,
        position: position,
        hitTest: (result, position) =>
            child?.hitTest(result, position: position) ?? false,
      );
}

/// A pixel-art grid painted as squares of [dots] screen dots each, starting
/// on a whole dot, never smoothed (ADR-0014).
///
/// [rows] are characters looked up in [colours]; `.` and any character not
/// there are clear.
class PixelGrid extends LeafRenderObjectWidget {
  const PixelGrid({
    super.key,
    required this.rows,
    required this.colours,
    required this.dots,
  });

  /// The grid at the largest size that fits in a [spot] points wide and high
  /// (ADR-0014). It may underfill the spot; it never overfills it, except
  /// where the two-dot floor makes it.
  static Widget inSpot({
    Key? key,
    required double spot,
    required List<String> rows,
    required Map<String, Color> colours,
  }) => Builder(
    key: key,
    builder: (context) => PixelGrid(
      rows: rows,
      colours: colours,
      dots: dotsPerPixel(
        spot: spot,
        gridSize: rows.length,
        devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
      ),
    ),
  );

  final List<String> rows;
  final Map<String, Color> colours;
  final int dots;

  @override
  RenderPixelGrid createRenderObject(BuildContext context) => RenderPixelGrid(
    rows: rows,
    colours: colours,
    dots: dots,
    devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
  );

  @override
  void updateRenderObject(BuildContext context, RenderPixelGrid renderObject) =>
      renderObject
        ..rows = rows
        ..colours = colours
        ..dots = dots
        ..devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
}

class RenderPixelGrid extends RenderBox {
  RenderPixelGrid({
    required this._rows,
    required this._colours,
    required this._dots,
    required this._devicePixelRatio,
  });

  List<String> _rows;
  set rows(List<String> value) {
    if (identical(value, _rows)) return;
    _rows = value;
    markNeedsLayout();
  }

  Map<String, Color> _colours;
  set colours(Map<String, Color> value) {
    if (identical(value, _colours)) return;
    _colours = value;
    markNeedsPaint();
  }

  int _dots;
  set dots(int value) {
    if (value == _dots) return;
    _dots = value;
    markNeedsLayout();
  }

  double _devicePixelRatio;
  set devicePixelRatio(double value) {
    if (value == _devicePixelRatio) return;
    _devicePixelRatio = value;
    markNeedsLayout();
  }

  int get _width => _rows.fold(0, (w, r) => math.max(w, r.length));

  @override
  void performLayout() {
    size = constraints.constrain(
      Size((_width * _dots).toDouble(), (_rows.length * _dots).toDouble()) /
          _devicePixelRatio,
    );
  }

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  void paint(PaintingContext context, Offset offset) {
    final start = offset + _toWholeDot(this, _devicePixelRatio);
    final canvas = context.canvas
      ..save()
      ..translate(start.dx, start.dy)
      // From here on, one unit is one screen dot.
      ..scale(1 / _devicePixelRatio);
    final paint = Paint()..isAntiAlias = false;
    for (var y = 0; y < _rows.length; y++) {
      final row = _rows[y];
      var x = 0;
      while (x < row.length) {
        // One rectangle per run of the same colour.
        final c = row[x];
        var end = x + 1;
        while (end < row.length && row[end] == c) {
          end++;
        }
        final colour = _colours[c];
        if (colour != null) {
          canvas.drawRect(
            Rect.fromLTRB(
              (x * _dots).toDouble(),
              (y * _dots).toDouble(),
              (end * _dots).toDouble(),
              ((y + 1) * _dots).toDouble(),
            ),
            paint..color = colour,
          );
        }
        x = end;
      }
    }
    canvas.restore();
  }
}

/// The dither behind sheets, dialogs and Moments (spec §9.3, ADR-0017):
/// every other screen dot in [colour], in a checkerboard that starts on whole
/// dots. It fills its parent and lets everything under it show through the
/// other half of the dots.
class Dither extends LeafRenderObjectWidget {
  const Dither({super.key, required this.colour});

  final Color colour;

  @override
  RenderDither createRenderObject(BuildContext context) => RenderDither(
    colour: colour,
    devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
  );

  @override
  void updateRenderObject(BuildContext context, RenderDither renderObject) =>
      renderObject
        ..colour = colour
        ..devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
}

class RenderDither extends RenderBox {
  RenderDither({required this._colour, required this._devicePixelRatio});

  Color _colour;
  set colour(Color value) {
    if (value == _colour) return;
    _colour = value;
    _disposeTile();
    markNeedsPaint();
  }

  double _devicePixelRatio;
  set devicePixelRatio(double value) {
    if (value == _devicePixelRatio) return;
    _devicePixelRatio = value;
    markNeedsPaint();
  }

  /// Two dots by two, the colour on the top-left and bottom-right.
  ui.Image? _tile;

  ui.Image _makeTile() {
    final recorder = ui.PictureRecorder();
    final paint = Paint()
      ..isAntiAlias = false
      ..color = _colour;
    Canvas(recorder)
      ..drawRect(const Rect.fromLTWH(0, 0, 1, 1), paint)
      ..drawRect(const Rect.fromLTWH(1, 1, 1, 1), paint);
    final picture = recorder.endRecording();
    final image = picture.toImageSync(2, 2);
    picture.dispose();
    return image;
  }

  void _disposeTile() {
    _tile?.dispose();
    _tile = null;
  }

  @override
  void detach() {
    _disposeTile();
    super.detach();
  }

  @override
  bool get sizedByParent => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.biggest;

  @override
  void paint(PaintingContext context, Offset offset) {
    final tile = _tile ??= _makeTile();
    final dpr = _devicePixelRatio;
    final shift = _toWholeDot(this, dpr);
    // Where this box starts, in whole screen dots: the checks are laid on the
    // screen's dots, so two dithers side by side line up.
    final start = (localToGlobal(Offset.zero) + shift) * dpr;
    final startX = start.dx.round(), startY = start.dy.round();
    final canvas = context.canvas
      ..save()
      ..translate((offset + shift).dx, (offset + shift).dy)
      ..scale(1 / dpr);
    canvas.drawRect(
      Rect.fromLTWH(
        0,
        0,
        (size.width * dpr).floorToDouble(),
        (size.height * dpr).floorToDouble(),
      ),
      Paint()
        ..isAntiAlias = false
        ..shader = ImageShader(
          tile,
          TileMode.repeated,
          TileMode.repeated,
          Matrix4.translationValues(
            -(startX % 2).toDouble(),
            -(startY % 2).toDouble(),
            0,
          ).storage,
          filterQuality: FilterQuality.none,
        ),
    );
    canvas.restore();
  }
}

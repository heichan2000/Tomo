import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// A column of a project's rows, [gap] apart, in which one row can slide
/// from where it was to where the list now puts it (spec §8.8): the row
/// whose ring was just tapped, moving to its new place.
///
/// Arm a row with a new [SlideArm] in the same build that moves it. Laid out in its
/// new place, it is painted where it last stood; then [onArmed] is called
/// after that frame, and the row eases home as [slide] runs from 0 to 1, in
/// whole UI pixels ([step]). The other rows simply take their new places.
class SlidingColumn extends MultiChildRenderObjectWidget {
  const SlidingColumn({
    super.key,
    required this.gap,
    required this.step,
    required this.slide,
    this.armed,
    this.onArmed,
    required super.children,
  });

  final double gap;
  final double step;
  final Animation<double> slide;

  /// The row to slide. A new arm each time, even for the same row.
  final SlideArm? armed;

  /// Called once per arming, after the frame that moved the row, with how
  /// far it has to go; zero when it didn't move.
  final void Function(double distance)? onArmed;

  @override
  RenderObject createRenderObject(BuildContext context) => RenderSlidingColumn(
    gap: gap,
    step: step,
    slide: slide,
    armed: armed,
    onArmed: onArmed,
  );

  @override
  void updateRenderObject(
    BuildContext context,
    RenderSlidingColumn renderObject,
  ) => renderObject
    ..gap = gap
    ..step = step
    ..slide = slide
    ..armed = armed
    ..onArmed = onArmed;
}

/// Which row of a [SlidingColumn] slides next: the one with [id], given
/// with [SlidingItem].
final class SlideArm {
  SlideArm(this.id);

  final Object id;
}

/// Names a child of [SlidingColumn], so it can be followed when the list
/// changes order.
class SlidingItem extends ParentDataWidget<_SlidingSlot> {
  const SlidingItem({super.key, required this.id, required super.child});

  final Object id;

  @override
  void applyParentData(RenderObject renderObject) {
    final slot = renderObject.parentData! as _SlidingSlot;
    if (slot.id != id) {
      slot.id = id;
      renderObject.parent?.markNeedsLayout();
    }
  }

  @override
  Type get debugTypicalAncestorWidgetClass => SlidingColumn;
}

class _SlidingSlot extends ContainerBoxParentData<RenderBox> {
  Object? id;
}

/// [SlidingColumn]'s render object.
class RenderSlidingColumn extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _SlidingSlot>,
        RenderBoxContainerDefaultsMixin<RenderBox, _SlidingSlot> {
  RenderSlidingColumn({
    required this._gap,
    required this._step,
    required this._slide,
    this._armed,
    this._onArmed,
  });

  double _gap;
  set gap(double value) {
    if (value == _gap) return;
    _gap = value;
    markNeedsLayout();
  }

  double _step;
  set step(double value) {
    if (value == _step) return;
    _step = value;
    markNeedsPaint();
  }

  Animation<double> _slide;
  set slide(Animation<double> value) {
    if (value == _slide) return;
    if (attached) _slide.removeListener(markNeedsPaint);
    _slide = value;
    if (attached) _slide.addListener(markNeedsPaint);
    markNeedsPaint();
  }

  SlideArm? _armed;
  set armed(SlideArm? value) {
    if (identical(value, _armed)) return;
    _armed = value;
    markNeedsLayout();
  }

  void Function(double distance)? _onArmed;
  set onArmed(void Function(double distance)? value) => _onArmed = value;

  /// Where each named row stood at the last layout.
  var _lastTops = <Object, double>{};

  /// The last arm acted on, the row sliding now, and how far from its place
  /// it set out.
  SlideArm? _handled;
  Object? _sliding;
  var _distance = 0.0;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _slide.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _slide.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _SlidingSlot) child.parentData = _SlidingSlot();
  }

  @override
  void performLayout() {
    final width = BoxConstraints.tightFor(width: constraints.maxWidth);
    final tops = <Object, double>{};
    var y = 0.0;
    var child = firstChild;
    while (child != null) {
      child.layout(width, parentUsesSize: true);
      final slot = child.parentData! as _SlidingSlot;
      slot.offset = Offset(0, y);
      if (slot.id case final id?) tops[id] = y;
      y += child.size.height;
      child = slot.nextSibling;
      if (child != null) y += _gap;
    }
    size = constraints.constrain(Size(constraints.maxWidth, y));

    final armed = _armed;
    if (armed != null && !identical(armed, _handled)) {
      final from = _lastTops[armed.id];
      final to = tops[armed.id];
      _handled = armed;
      _sliding = armed.id;
      _distance = from == null || to == null ? 0 : from - to;
      final distance = _distance;
      SchedulerBinding.instance.addPostFrameCallback(
        (_) => _onArmed?.call(distance),
      );
    } else if (armed == null) {
      _sliding = null;
    }
    _lastTops = tops;
  }

  /// How far the sliding row is from its place now, in whole UI pixels.
  double get _offset {
    final left = _distance * (1 - Curves.easeOutCubic.transform(_slide.value));
    return _step <= 0 ? left : (left / _step).roundToDouble() * _step;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    RenderBox? sliding;
    var child = firstChild;
    while (child != null) {
      final slot = child.parentData! as _SlidingSlot;
      if (_sliding != null && slot.id == _sliding) {
        sliding = child;
      } else {
        context.paintChild(child, offset + slot.offset);
      }
      child = slot.nextSibling;
    }
    // The moving row passes over the others.
    if (sliding != null) {
      final slot = sliding.parentData! as _SlidingSlot;
      context.paintChild(sliding, offset + slot.offset + Offset(0, _offset));
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}

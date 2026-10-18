import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'ui_pixel.dart';

/// A screen's content, as the approved screens lay it out: 6 UI pixels from
/// the top, 12 from each side, 10 from the bottom, with 6 between parts.
///
/// [content] runs down from the top and [bottom] (the screen's buttons) sits
/// at the foot, with at least 16 UI pixels between them. [middle], if any,
/// sits halfway down the room between the two, as the pet does on Focus.
/// When it all doesn't fit, as at large text, the whole screen scrolls,
/// buttons included, rather than clip (spec §12).
///
/// It keeps clear of the status bar, the phone's gesture bar (outside the
/// shell, which already does), and the keyboard when one is up.
class ScreenBody extends StatelessWidget {
  const ScreenBody({
    super.key,
    required this.content,
    this.middle = const [],
    this.bottom = const [],
    this.bottomGap = 6,
  });

  final List<Widget> content;
  final List<Widget> middle;
  final List<Widget> bottom;

  /// UI pixels between the parts of [bottom].
  final double bottomGap;

  /// [parts], with [gap] UI pixels between each.
  static List<Widget> spaced(
    BuildContext context,
    List<Widget> parts,
    num gap,
  ) {
    final u = UiPixel.of(context);
    return [
      for (final (i, part) in parts.indexed) ...[
        if (i > 0) SizedBox(height: u(gap)),
        part,
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final u = UiPixel.of(context);
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final padding = EdgeInsets.fromLTRB(u(12), u(6), u(12), u(10));
    Widget column(List<Widget> parts, num gap) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: spaced(context, parts, gap),
    );
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: keyboard),
        child: LayoutBuilder(
          builder: (context, viewport) => SingleChildScrollView(
            padding: padding,
            child: _ContentAndFoot(
              // The approved screens' "grow": at least 4 UI pixels, with the
              // usual gap on each side.
              gap: u(16),
              // Inside the padding, the screen is that much shorter.
              minHeight: math.max(0, viewport.maxHeight - padding.vertical),
              children: [
                column(content, 6),
                column(middle, 6),
                column(bottom, bottomGap),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Three children: the first at the top, the last at the foot of at least
/// [minHeight], and the middle one halfway down the room between them; each
/// at least [gap] from the next. An empty child takes no room and no gap.
class _ContentAndFoot extends MultiChildRenderObjectWidget {
  const _ContentAndFoot({
    required this.gap,
    required this.minHeight,
    required super.children,
  });

  final double gap;
  final double minHeight;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderContentAndFoot(gap: gap, minHeight: minHeight);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderContentAndFoot renderObject,
  ) => renderObject
    ..gap = gap
    ..minHeight = minHeight;
}

class _Slot extends ContainerBoxParentData<RenderBox> {}

class _RenderContentAndFoot extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _Slot>,
        RenderBoxContainerDefaultsMixin<RenderBox, _Slot> {
  _RenderContentAndFoot({required this._gap, required this._minHeight});

  double _gap;
  set gap(double value) {
    if (value == _gap) return;
    _gap = value;
    markNeedsLayout();
  }

  double _minHeight;
  set minHeight(double value) {
    if (value == _minHeight) return;
    _minHeight = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _Slot) child.parentData = _Slot();
  }

  @override
  void performLayout() {
    final width = BoxConstraints.tightFor(width: constraints.maxWidth);
    final content = firstChild!..layout(width, parentUsesSize: true);
    final middle = childAfter(content)!..layout(width, parentUsesSize: true);
    final foot = childAfter(middle)!..layout(width, parentUsesSize: true);
    double room(RenderBox child) =>
        child.size.height > 0 ? _gap + child.size.height : 0;
    final height = math.max(
      _minHeight,
      content.size.height + room(middle) + room(foot),
    );
    size = constraints.constrain(Size(constraints.maxWidth, height));
    (content.parentData! as _Slot).offset = Offset.zero;
    final footTop = size.height - foot.size.height;
    // Halfway, but never nearer either neighbour than the gap.
    final free = footTop - content.size.height - middle.size.height;
    (middle.parentData! as _Slot).offset = Offset(
      0,
      content.size.height + math.max(_gap, free / 2),
    );
    (foot.parentData! as _Slot).offset = Offset(0, footTop);
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}

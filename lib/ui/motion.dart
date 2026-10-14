import 'package:flutter/widgets.dart';

import 'ui_pixel.dart';

/// The motion tiers the chrome uses (spec §9.4, ADR-0017). Beat and Moment
/// belong to the pet and the reward ladder.
///
/// Everything moves in whole UI pixels and nothing fades, except the
/// cross-fades reduce motion asks for. Only the pet and reward objects
/// spring; the chrome never overshoots.
abstract final class Motion {
  /// Feedback: press, toggle, tab change. A shade changes at once; anything
  /// that moves takes this long. The same under reduce motion.
  static const feedback = Duration(milliseconds: 120);

  /// Transition: routes, sheets, the Focus takeover and minimise. A slide of
  /// [slide] on the decelerate curve.
  static const transition = Duration(milliseconds: 280);

  /// Transition under reduce motion: a cross-fade, the one fade allowed.
  static const transitionReduced = Duration(milliseconds: 150);

  /// How far a transition slides, in points (rounded to whole UI pixels).
  static const slide = 24.0;

  static const curve = Curves.decelerate;
}

/// Whether the phone asks for reduced motion (spec §7.7, ADR-0005).
bool reduceMotion(BuildContext context) =>
    MediaQuery.maybeDisableAnimationsOf(context) ?? false;

/// How long a transition takes at [context].
Duration transitionDuration(BuildContext context) =>
    reduceMotion(context) ? Motion.transitionReduced : Motion.transition;

/// [child] coming in from [from] as [animation] runs: a slide of 24 pt in
/// whole UI pixels, decelerating; or, under reduce motion, a cross-fade.
class PixelTransition extends StatelessWidget {
  const PixelTransition({
    super.key,
    required this.animation,
    required this.from,
    required this.child,
  });

  final Animation<double> animation;

  /// The edge it arrives from.
  final AxisDirection from;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (reduceMotion(context)) {
      return FadeTransition(opacity: animation, child: child);
    }
    return _PixelSlide(animation: animation, from: from, child: child);
  }
}

class _PixelSlide extends AnimatedWidget {
  const _PixelSlide({
    required Animation<double> animation,
    required this.from,
    required this.child,
  }) : super(listenable: animation);

  final AxisDirection from;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final u = UiPixel.of(context);
    final t = Motion.curve.transform(
      (listenable as Animation<double>).value.clamp(0.0, 1.0),
    );
    // Whole UI pixels still to go.
    final left = ((1 - t) * u.snap(Motion.slide) / u.pt).round() * u.pt;
    final offset = switch (from) {
      AxisDirection.right => Offset(left, 0),
      AxisDirection.left => Offset(-left, 0),
      AxisDirection.down => Offset(0, left),
      AxisDirection.up => Offset(0, -left),
    };
    return Transform.translate(offset: offset, child: child);
  }
}

/// A full screen pushed over the last (spec §8.1): it slides in from the
/// right, or for the Focus takeover from the bottom, by 24 pt in whole UI
/// pixels; under reduce motion it cross-fades. Nothing behind it moves.
class PixelPageRoute<T> extends PageRoute<T> {
  PixelPageRoute({
    required this.builder,
    this.from = AxisDirection.right,
    super.settings,
  });

  final WidgetBuilder builder;
  final AxisDirection from;

  bool get _reduced => navigator != null && reduceMotion(navigator!.context);

  @override
  Duration get transitionDuration =>
      _reduced ? Motion.transitionReduced : Motion.transition;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => Semantics(
    scopesRoute: true,
    explicitChildNodes: true,
    child: builder(context),
  );

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => PixelTransition(animation: animation, from: from, child: child);
}

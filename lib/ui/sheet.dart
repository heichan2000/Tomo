import 'package:flutter/material.dart' show MaterialLocalizations;
import 'package:flutter/widgets.dart';

import 'motion.dart';
import 'pixel_box.dart';
import 'tomo_theme.dart';
import 'ui_pixel.dart';
import 'whole_dots.dart';

/// Opens a sheet (spec §9.3): a surface anchored to the bottom, over the
/// dither. Every dialog in Tomo is one (spec §8.1). A tap on the dither or
/// the back gesture closes it. It rises above the keyboard, and once it
/// nearly fills the screen its content scrolls.
Future<T?> showPixelSheet<T>(BuildContext context, WidgetBuilder builder) =>
    Navigator.of(context).push(
      PixelSheetRoute<T>(
        builder: builder,
        dismissLabel: MaterialLocalizations.of(context)
            .modalBarrierDismissLabel,
      ),
    );

/// The route behind [showPixelSheet]. It slides up 24 pt in whole UI pixels
/// while the dither is there at once (Transition tier); under reduce motion
/// both cross-fade.
class PixelSheetRoute<T> extends PopupRoute<T> {
  PixelSheetRoute({
    required this.builder,
    required this.dismissLabel,
    super.settings,
  });

  final WidgetBuilder builder;
  final String dismissLabel;

  bool get _reduced => navigator != null && reduceMotion(navigator!.context);

  @override
  Duration get transitionDuration =>
      _reduced ? Motion.transitionReduced : Motion.transition;

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => dismissLabel;

  // The dither stands in for a colour; see [buildModalBarrier].
  @override
  Color? get barrierColor => null;

  @override
  Widget buildModalBarrier() => Stack(
    fit: StackFit.expand,
    children: [
      IgnorePointer(child: _DitherBehind(animation: animation!)),
      ModalBarrier(
        dismissible: barrierDismissible,
        semanticsLabel: barrierLabel,
        barrierSemanticsDismissible: semanticsDismissible,
      ),
    ],
  );

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final colours = TomoTheme.of(context);
    final u = UiPixel.of(context);
    final media = MediaQuery.of(context);
    final keyboard = media.viewInsets.bottom;
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.only(bottom: keyboard),
        child: ConstrainedBox(
          // Nearly full: the dither still shows above it.
          constraints: BoxConstraints(
            maxHeight: media.size.height - keyboard - media.padding.top - u(12),
          ),
          child: PixelBox(
            fill: colours.surface,
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(u(12), u(10), u(12), u(16)),
                child: Semantics(
                  scopesRoute: true,
                  namesRoute: true,
                  explicitChildNodes: true,
                  child: builder(context),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => PixelTransition(
    animation: animation,
    from: AxisDirection.down,
    child: child,
  );
}

/// The dither behind a sheet: there at once, or under reduce motion fading
/// in with it.
class _DitherBehind extends StatelessWidget {
  const _DitherBehind({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final dither = Dither(colour: TomoTheme.of(context).ground);
    return reduceMotion(context)
        ? FadeTransition(opacity: animation, child: dither)
        : dither;
  }
}

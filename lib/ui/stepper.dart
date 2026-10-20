import 'package:flutter/widgets.dart';
import 'package:tomo_core/art/pixel_art.dart';

import 'buttons.dart';
import 'pixel_box.dart';
import 'pixel_icon.dart';
import 'sharp_text.dart';
import 'tomo_theme.dart';
import 'ui_pixel.dart';

/// A −/+ stepper (spec §9.3): two sunken 48 pt squares with the value
/// between them. At a limit its square turns off, its icon in the boundary
/// grey. Used for the Custom sheet's lengths and a task's planned blocks.
///
/// To a screen reader it is [label] and [value], with its two squares as
/// buttons of their own, [lessLabel] and [moreLabel].
class PixelStepper extends StatelessWidget {
  const PixelStepper({
    super.key,
    required this.label,
    required this.value,
    required this.lessLabel,
    required this.moreLabel,
    required this.onLess,
    required this.onMore,
    this.mutedValue = false,
  });

  final String label;
  final String value;
  final String lessLabel;
  final String moreLabel;

  /// Null at the lower limit.
  final VoidCallback? onLess;

  /// Null at the upper limit.
  final VoidCallback? onMore;

  /// The value is an absence, such as *No plan*, and is shown muted.
  final bool mutedValue;

  @override
  Widget build(BuildContext context) {
    final u = UiPixel.of(context);
    final colours = TomoTheme.of(context);
    return Semantics(
      container: true,
      label: label,
      value: value,
      child: Row(
        children: [
          _Square(icon: IconName.minus, label: lessLabel, onPressed: onLess),
          SizedBox(width: u(4)),
          Expanded(
            child: ExcludeSemantics(
              child: PixelText(
                value,
                textAlign: TextAlign.center,
                colour: mutedValue ? colours.muted : colours.ink,
              ),
            ),
          ),
          SizedBox(width: u(4)),
          _Square(icon: IconName.plus, label: moreLabel, onPressed: onMore),
        ],
      ),
    );
  }
}

class _Square extends StatelessWidget {
  const _Square({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconName icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colours = TomoTheme.of(context);
    final side = UiPixel.of(context).target;
    return Pressable(
      onPressed: onPressed,
      semanticLabel: label,
      builder: (context, pressed, ring) => PixelBox(
        fill: pressed ? colours.pressed(colours.sunken) : colours.sunken,
        ring: ring ? colours.accent : null,
        child: SizedBox.square(
          dimension: side,
          child: Center(
            child: PixelIcon(
              icon,
              colour: onPressed == null ? colours.boundary : colours.ink,
            ),
          ),
        ),
      ),
    );
  }
}

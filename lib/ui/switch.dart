import 'package:flutter/widgets.dart';

import 'buttons.dart';
import 'pixel_box.dart';
import 'sharp_text.dart';
import 'tomo_theme.dart';
import 'motion.dart';
import 'ui_pixel.dart';

/// An on/off switch (spec §9.3): off is a sunken track with a muted knob, on
/// an accent track with an on-accent knob. 24 × 14 UI pixels, in a 48 pt
/// target. The knob slides in whole UI pixels (Feedback tier).
class PixelSwitch extends StatelessWidget {
  const PixelSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    required this.semanticLabel,
    this.held = HeldState.live,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String semanticLabel;
  final HeldState held;

  @override
  Widget build(BuildContext context) {
    final change = onChanged;
    final side = UiPixel.of(context).target;
    return Pressable(
      onPressed: change == null ? null : () => change(!value),
      button: false,
      toggled: value,
      held: held,
      semanticLabel: semanticLabel,
      builder: (context, pressed, ring) => SizedBox(
        width: side,
        height: side,
        child: Center(
          child: SwitchLook(value: value, pressed: pressed, ring: ring),
        ),
      ),
    );
  }
}

/// A settings row with a switch at its end (spec §8.10): the whole row is
/// the target.
class PixelSwitchRow extends StatelessWidget {
  const PixelSwitchRow({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colours = TomoTheme.of(context);
    final u = UiPixel.of(context);
    final change = onChanged;
    return Pressable(
      onPressed: change == null ? null : () => change(!value),
      button: false,
      toggled: value,
      builder: (context, pressed, ring) => PixelBox(
        fill: pressed ? colours.pressed(colours.surface) : colours.surface,
        ring: ring ? colours.accent : null,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: u.target),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: u(7), vertical: u(3)),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PixelText(title),
                      if (subtitle != null)
                        PixelText(
                          subtitle!,
                          step: TypeStep.caption,
                          colour: colours.muted,
                        ),
                    ],
                  ),
                ),
                SizedBox(width: u(6)),
                SwitchLook(value: value),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// How a switch looks, with no behaviour of its own.
class SwitchLook extends StatefulWidget {
  const SwitchLook({
    super.key,
    required this.value,
    this.pressed = false,
    this.ring = false,
  });

  final bool value;
  final bool pressed;
  final bool ring;

  @override
  State<SwitchLook> createState() => _SwitchLookState();
}

class _SwitchLookState extends State<SwitchLook>
    with SingleTickerProviderStateMixin {
  late final _slide = AnimationController(
    vsync: this,
    duration: Motion.feedback,
    value: widget.value ? 1 : 0,
  );

  @override
  void didUpdateWidget(SwitchLook oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      widget.value ? _slide.forward() : _slide.reverse();
    }
  }

  @override
  void dispose() {
    _slide.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colours = TomoTheme.of(context);
    final u = UiPixel.of(context);
    final track = widget.value ? colours.accent : colours.sunken;
    return PixelBox(
      fill: widget.pressed ? colours.pressed(track) : track,
      ring: widget.ring ? colours.accent : null,
      child: SizedBox(
        width: u(24),
        height: u(14),
        child: AnimatedBuilder(
          animation: _slide,
          builder: (context, _) {
            // Ten UI pixels of travel, taken whole.
            final at = (Motion.curve.transform(_slide.value) * 10).round();
            return Stack(
              children: [
                Positioned(
                  left: u(2 + at),
                  top: u(2),
                  child: PixelBox(
                    fill: widget.value ? colours.onAccent : colours.muted,
                    child: SizedBox.square(dimension: u(10)),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

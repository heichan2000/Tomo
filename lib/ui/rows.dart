import 'package:flutter/widgets.dart';
import 'package:tomo_core/art/pixel_art.dart';

import 'buttons.dart';
import 'pixel_box.dart';
import 'pixel_icon.dart';
import 'sharp_text.dart';
import 'tomo_theme.dart';
import 'ui_pixel.dart';

/// A list row (spec §9.3, §8.8): a surface with a title in body text, an
/// optional line under it in muted caption, and room at either end for 48 pt
/// targets such as a status glyph or ⋯. The title wraps and the row grows.
///
/// With [onTap] the whole row is pressable: it shades toward ink while held.
class PixelRow extends StatelessWidget {
  const PixelRow({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing = const [],
    this.mutedTitle = false,
    this.onTap,
    this.onLongPress,
    this.selected,
    this.held = HeldState.live,
  });

  final String title;
  final String? subtitle;

  /// Usually a 48 pt target, which brings its own room, so the row adds no
  /// padding on that side.
  final Widget? leading;

  final List<Widget> trailing;

  /// A done task's title (spec §9.3).
  final bool mutedTitle;

  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// For a row in a list to choose from: whether it is the chosen one.
  final bool? selected;

  final HeldState held;

  @override
  Widget build(BuildContext context) {
    final colours = TomoTheme.of(context);
    final u = UiPixel.of(context);

    Widget row(bool pressed, bool ring) => PixelBox(
      fill: pressed ? colours.pressed(colours.surface) : colours.surface,
      ring: ring ? colours.accent : null,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: u.target),
        child: Padding(
          padding: EdgeInsets.only(
            left: leading == null ? u(7) : 0,
            right: trailing.isEmpty ? u(7) : 0,
            top: u(3),
            bottom: u(3),
          ),
          child: Row(
            children: [
              if (leading != null) ...[leading!, SizedBox(width: u(3))],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PixelText(
                      title,
                      colour: mutedTitle ? colours.muted : colours.ink,
                    ),
                    if (subtitle != null)
                      PixelText(
                        subtitle!,
                        step: TypeStep.caption,
                        colour: colours.muted,
                      ),
                  ],
                ),
              ),
              for (final widget in trailing) ...[SizedBox(width: u(3)), widget],
            ],
          ),
        ),
      ),
    );

    if (onTap == null && onLongPress == null) {
      return Semantics(container: true, child: row(false, false));
    }
    return Pressable(
      onPressed: onTap,
      onLongPress: onLongPress,
      selected: selected,
      held: held,
      builder: (context, pressed, ring) => row(pressed, ring),
    );
  }
}

/// How a chip is coloured.
enum ChipTone {
  /// Sunken, ink: *Doing* on the doing row.
  plain,

  /// Accent fill: *Focus*.
  accent,

  /// Sunken, muted: *Break*.
  muted,
}

/// A small label in a box (spec §9.3), in caption text. Never a target on
/// its own.
class PixelChip extends StatelessWidget {
  const PixelChip(
    this.label, {
    super.key,
    this.tone = ChipTone.plain,
    this.big = false,
  });

  final String label;
  final ChipTone tone;

  /// Body text, with more room around it: Focus's *Focus* and *Break*.
  final bool big;

  @override
  Widget build(BuildContext context) {
    final colours = TomoTheme.of(context);
    final u = UiPixel.of(context);
    final (fill, ink) = switch (tone) {
      ChipTone.plain => (colours.sunken, colours.ink),
      ChipTone.accent => (colours.accent, colours.onAccent),
      ChipTone.muted => (colours.sunken, colours.muted),
    };
    return PixelBox(
      fill: fill,
      child: Padding(
        padding: big
            ? EdgeInsets.symmetric(horizontal: u(6), vertical: u(2))
            : EdgeInsets.symmetric(horizontal: u(4), vertical: u(1)),
        child: PixelText(
          label,
          step: big ? TypeStep.body : TypeStep.caption,
          colour: ink,
        ),
      ),
    );
  }
}

/// A sunken line of plain words where something happened (spec §8.8): a
/// task-lock refusal under what was tapped, a write that failed, or a
/// project's all-done line with its done icon. Never a toast.
class SunkenLine extends StatelessWidget {
  const SunkenLine(this.text, {super.key, this.icon});

  final String text;

  /// Shown muted before the words.
  final IconName? icon;

  @override
  Widget build(BuildContext context) {
    final colours = TomoTheme.of(context);
    final u = UiPixel.of(context);
    return PixelBox(
      fill: colours.sunken,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: u(7), vertical: u(5)),
        child: Row(
          children: [
            if (icon != null) ...[
              PixelIcon(icon!, colour: colours.muted),
              SizedBox(width: u(5)),
            ],
            Expanded(child: PixelText(text)),
          ],
        ),
      ),
    );
  }
}

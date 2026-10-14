import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'pixel_box.dart';
import 'sharp_text.dart';
import 'tomo_theme.dart';
import 'ui_pixel.dart';

/// What a button is for (spec §9.3).
enum ButtonKind {
  /// Accent fill: the one thing the screen is for.
  primary,

  /// Sunken fill.
  secondary,

  /// Accent-free, no fill: text only, in ink.
  quiet,

  /// Quiet, with a muted label: *Stop early* on Focus.
  quietMuted,

  /// Quiet, with a destructive label: *Delete task* on task detail.
  quietDestructive,

  /// Brick in light, true red in dark.
  destructive,
}

/// A button or icon button held in one state, so the kit gallery can show
/// every state side by side. Everywhere else it is [live].
enum HeldState { live, pressed, focused }

/// The chrome's interaction states, shared by every pressable part.
///
/// - **Pressed**: one shade toward ink, at once (Feedback tier, no movement).
/// - **Turned off** ([onPressed] null): solid sunken with a muted label,
///   never see-through.
/// - **Keyboard focus**: a one-pixel accent ring with a one-pixel gap, shown
///   only when the keyboard moved focus there.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.onPressed,
    required this.builder,
    this.onLongPress,
    this.held = HeldState.live,
    this.button = true,
    this.selected,
    this.inMutuallyExclusiveGroup,
    this.toggled,
    this.semanticLabel,
  });

  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;

  /// Builds the part for whether it is [pressed] and whether it shows the
  /// focus [ring].
  final Widget Function(BuildContext context, bool pressed, bool ring) builder;

  final HeldState held;

  /// Whether screen readers hear it as a button. Rows that open something
  /// say so; a segment or a switch row has its own semantics.
  final bool button;

  /// For a segment: whether it is the chosen one.
  final bool? selected;
  final bool? inMutuallyExclusiveGroup;

  /// For a switch row: whether it is on.
  final bool? toggled;

  /// What a part with no words of its own says, such as an icon button.
  final String? semanticLabel;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;
  bool _ring = false;

  bool get _enabled => widget.onPressed != null;

  void _setDown(bool value) {
    if (value != _down) setState(() => _down = value);
  }

  @override
  Widget build(BuildContext context) {
    final pressed = _enabled && (_down || widget.held == HeldState.pressed);
    final ring = _enabled && (_ring || widget.held == HeldState.focused);
    // One node for the part, its words included; buttons inside it, such as
    // a row's ⋯, stay nodes of their own.
    return Semantics(
      container: true,
      button: widget.button,
      enabled: _enabled,
      selected: widget.selected,
      inMutuallyExclusiveGroup: widget.inMutuallyExclusiveGroup,
      toggled: widget.toggled,
      label: widget.semanticLabel,
      child: FocusableActionDetector(
        enabled: _enabled,
        mouseCursor: _enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onShowFocusHighlight: (value) => setState(() => _ring = value),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onPressed?.call();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: _enabled ? (_) => _setDown(true) : null,
          onTapUp: _enabled ? (_) => _setDown(false) : null,
          onTapCancel: _enabled ? () => _setDown(false) : null,
          onTap: widget.onPressed,
          onLongPress: _enabled ? widget.onLongPress : null,
          child: widget.builder(context, pressed, ring),
        ),
      ),
    );
  }
}

/// A text button (spec §9.3), at least 48 pt tall. Its height is the label's
/// line plus equal padding above and below, so the label sits on whole dots.
class PixelButton extends StatelessWidget {
  const PixelButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.kind = ButtonKind.primary,
    this.wide = false,
    this.held = HeldState.live,
  });

  final String label;

  /// Null turns the button off.
  final VoidCallback? onPressed;

  final ButtonKind kind;

  /// Fills the width it is given.
  final bool wide;

  final HeldState held;

  @override
  Widget build(BuildContext context) {
    final colours = TomoTheme.of(context);
    final u = UiPixel.of(context);
    final dpr = u.devicePixelRatio;
    final line = 16 * SharpText.of(context).dotsFor(TypeStep.body.dots(dpr));
    final padding = EdgeInsets.symmetric(
      horizontal: u(10),
      vertical: math.max(3 * u.dots, ((48 * dpr - line) / 2).ceil()) / dpr,
    );

    return Pressable(
      onPressed: onPressed,
      held: held,
      builder: (context, pressed, ring) {
        var (fill, ink) = switch (kind) {
          ButtonKind.primary => (colours.accent, colours.onAccent),
          ButtonKind.secondary => (colours.sunken, colours.ink),
          ButtonKind.quiet => (null, colours.ink),
          ButtonKind.quietMuted => (null, colours.muted),
          ButtonKind.quietDestructive => (null, colours.destructive),
          ButtonKind.destructive => (
            colours.destructive,
            colours.onDestructive,
          ),
        };
        if (onPressed == null) {
          (fill, ink) = (colours.sunken, colours.muted);
        } else if (pressed) {
          fill = fill == null ? colours.sunken : colours.pressed(fill);
        }
        return PixelBox(
          fill: fill,
          ring: ring ? colours.accent : null,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: wide ? double.infinity : u.target,
            ),
            child: Padding(
              padding: padding,
              child: Align(
                widthFactor: 1,
                heightFactor: 1,
                child: PixelText(
                  label,
                  colour: ink,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A 48 pt square holding an icon (or a status glyph), for back, ⋯, the gear
/// and the like. [semanticLabel] says what it does.
class PixelIconButton extends StatelessWidget {
  const PixelIconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    this.onLongPress,
    this.held = HeldState.live,
  });

  final Widget icon;
  final String semanticLabel;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final HeldState held;

  @override
  Widget build(BuildContext context) {
    final colours = TomoTheme.of(context);
    final side = UiPixel.of(context).target;
    return Pressable(
      onPressed: onPressed,
      onLongPress: onLongPress,
      held: held,
      semanticLabel: semanticLabel,
      builder: (context, pressed, ring) => PixelBox(
        fill: pressed ? colours.sunken : null,
        ring: ring ? colours.accent : null,
        child: SizedBox.square(
          dimension: side,
          child: Center(child: icon),
        ),
      ),
    );
  }
}

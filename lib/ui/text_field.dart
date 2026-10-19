import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart'
    show cupertinoTextSelectionHandleControls;
import 'package:flutter/material.dart'
    show AdaptiveTextSelectionToolbar, materialTextSelectionHandleControls;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:tomo_core/art/pixel_art.dart';

import 'pixel_box.dart';
import 'pixel_icon.dart';
import 'sharp_text.dart';
import 'tomo_theme.dart';
import 'ui_pixel.dart';
import 'whole_dots.dart';

/// A text field (spec §9.3): the one part with an outline, one UI pixel of
/// the boundary grey, two of the accent while typing. Its text wraps and the
/// field grows. The text is laid out in screen dots like all of Tomo's text
/// (spec §17 C46), caret and selection included.
class PixelTextField extends StatefulWidget {
  const PixelTextField({
    super.key,
    required this.controller,
    this.focusNode,
    this.hint,
    this.label,
    this.autofocus = false,
    this.textInputAction = TextInputAction.done,
    this.onChanged,
    this.onSubmitted,
    this.maxLines,
    this.inputFormatters,
    this.restingIcon,
    this.staysOpen = false,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;

  /// Shown, muted, while the field is empty.
  final String? hint;

  /// What a screen reader calls the field, when a label over it says so.
  final String? label;

  final bool autofocus;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  /// Null lets the text wrap onto as many lines as it needs.
  final int? maxLines;

  final List<TextInputFormatter>? inputFormatters;

  /// Shown, muted, before the [hint] while the field is empty and not being
  /// typed in: the + of *Add a task* (spec §8.8).
  final IconName? restingIcon;

  /// The keyboard stays up after [onSubmitted], ready for the next line, as
  /// *Add a task* is (spec §8.8).
  final bool staysOpen;

  @override
  State<PixelTextField> createState() => _PixelTextFieldState();
}

class _PixelTextFieldState extends State<PixelTextField>
    implements TextSelectionGestureDetectorBuilderDelegate {
  FocusNode? _ownFocusNode;
  FocusNode get _focusNode =>
      widget.focusNode ?? (_ownFocusNode ??= FocusNode());

  final _editable = GlobalKey<EditableTextState>();

  @override
  GlobalKey<EditableTextState> get editableTextKey => _editable;

  @override
  bool get forcePressEnabled => false;

  @override
  bool get selectionEnabled => true;

  /// Tap, double-tap, long-press and drag to place the caret and select,
  /// as the platform's own fields do.
  late final _gestures = TextSelectionGestureDetectorBuilder(delegate: this);

  bool _showHandles = false;

  void _selectionChanged(TextSelection _, SelectionChangedCause? cause) {
    final show =
        _gestures.shouldShowSelectionToolbar &&
        cause != SelectionChangedCause.keyboard &&
        (cause == SelectionChangedCause.longPress ||
            widget.controller.text.isNotEmpty);
    if (show != _showHandles) setState(() => _showHandles = show);
  }

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_changed);
    widget.controller.addListener(_changed);
  }

  @override
  void didUpdateWidget(PixelTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _ownFocusNode)?.removeListener(_changed);
      _focusNode.addListener(_changed);
    }
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_changed);
      widget.controller.addListener(_changed);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_changed);
    widget.controller.removeListener(_changed);
    _ownFocusNode?.dispose();
    super.dispose();
  }

  void _changed() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final colours = TomoTheme.of(context);
    final u = UiPixel.of(context);
    final dpr = u.devicePixelRatio;
    final n = SharpText.of(context).dotsFor(TypeStep.body.dots(dpr));
    final typing = _focusNode.hasFocus;
    final style = TypeStep.body
        .style(dpr, colours.ink)
        .copyWith(fontSize: 12.0 * n);
    final android = defaultTargetPlatform == TargetPlatform.android;

    final editable = InDots(
      child: EditableText(
        key: _editable,
        controller: widget.controller,
        focusNode: _focusNode,
        autofocus: widget.autofocus,
        style: style,
        textScaler: TextScaler.noScaling,
        cursorColor: colours.ink,
        backgroundCursorColor: colours.muted,
        // One UI pixel wide and one line tall, blinking without a fade.
        cursorWidth: u.dots.toDouble(),
        cursorHeight: 16.0 * n,
        cursorOpacityAnimates: false,
        selectionColor: colours.pressed(colours.sunken),
        maxLines: widget.maxLines,
        minLines: 1,
        keyboardType: widget.maxLines == 1
            ? TextInputType.text
            : TextInputType.multiline,
        textInputAction: widget.textInputAction,
        textCapitalization: TextCapitalization.sentences,
        inputFormatters: widget.inputFormatters,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
        onEditingComplete: widget.staysOpen ? () {} : null,
        selectionControls: android
            ? materialTextSelectionHandleControls
            : cupertinoTextSelectionHandleControls,
        contextMenuBuilder: (context, state) =>
            AdaptiveTextSelectionToolbar.editableText(editableTextState: state),
        scrollPadding: EdgeInsets.all(20 * dpr),
        showSelectionHandles: _showHandles,
        onSelectionChanged: _selectionChanged,
        rendererIgnoresPointer: true,
      ),
    );

    // A tap on the padding still starts typing.
    return _gestures.buildGestureDetector(
      behavior: HitTestBehavior.translucent,
      child: PixelBox(
        fill: colours.surface,
        outline: typing ? colours.accent : colours.boundary,
        outlineWidth: typing ? 2 : 1,
        child: Padding(
          // The outline is drawn over the padding, so the text stays put
          // when it thickens.
          padding: EdgeInsets.symmetric(horizontal: u(7), vertical: u(8)),
          child: Stack(
            children: [
              if (widget.hint != null && widget.controller.text.isEmpty)
                ExcludeSemantics(
                  child: Row(
                    children: [
                      if (widget.restingIcon != null && !typing) ...[
                        PixelIcon(widget.restingIcon!, colour: colours.muted),
                        SizedBox(width: u(4)),
                      ],
                      Expanded(
                        child: PixelText(widget.hint!, colour: colours.muted),
                      ),
                    ],
                  ),
                ),
              Semantics(
                label: widget.label,
                hint: widget.hint,
                child: editable,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

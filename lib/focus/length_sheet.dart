import 'package:flutter/widgets.dart';
import 'package:tomo_core/focus/block_lengths.dart';

import '../l10n/app_localizations.dart';
import '../ui/buttons.dart';
import '../ui/sharp_text.dart';
import '../ui/sheet.dart';
import '../ui/stepper.dart';
import '../ui/tomo_theme.dart';
import '../ui/ui_pixel.dart';

/// Opens the Custom length sheet (spec §4.7) at [from]. *Use these* gives
/// back the pair chosen; dismissing it gives null and changes nothing.
Future<BlockLengths?> chooseCustomLengths(
  BuildContext context, {
  required BlockLengths from,
}) =>
    showPixelSheet<BlockLengths>(context, (_) => CustomLengthSheet(from: from));

/// Two steppers, **Focus** 10–120 minutes in fives and **Break** 1–30
/// minutes in ones, then *Use these*.
class CustomLengthSheet extends StatefulWidget {
  const CustomLengthSheet({super.key, required this.from});

  final BlockLengths from;

  @override
  State<CustomLengthSheet> createState() => _CustomLengthSheetState();
}

class _CustomLengthSheetState extends State<CustomLengthSheet> {
  late var _focus = widget.from.focusMinutes;
  late var _break = widget.from.breakMinutes;

  @override
  Widget build(BuildContext context) {
    final words = AppLocalizations.of(context);
    final u = UiPixel.of(context);

    Widget stepper({
      required String label,
      required int minutes,
      required int min,
      required int max,
      required int Function({required bool up}) step,
    }) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.only(left: u(1)),
          child: ExcludeSemantics(
            child: PixelText(
              label,
              step: TypeStep.caption,
              colour: TomoTheme.of(context).muted,
            ),
          ),
        ),
        SizedBox(height: u(3)),
        PixelStepper(
          label: label,
          value: words.lengthMinutes(minutes),
          lessLabel: words.stepFewer,
          moreLabel: words.stepMore,
          onLess: minutes > min ? () => setState(() => step(up: false)) : null,
          onMore: minutes < max ? () => setState(() => step(up: true)) : null,
        ),
      ],
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PixelText(words.customTitle, step: TypeStep.title, header: true),
        SizedBox(height: u(5)),
        stepper(
          label: words.customFocus,
          minutes: _focus,
          min: minFocusMinutes,
          max: maxFocusMinutes,
          step: ({required up}) =>
              _focus = focusMinutesAfterStep(_focus, up: up),
        ),
        SizedBox(height: u(5)),
        stepper(
          label: words.customBreak,
          minutes: _break,
          min: minBreakMinutes,
          max: maxBreakMinutes,
          step: ({required up}) =>
              _break = breakMinutesAfterStep(_break, up: up),
        ),
        SizedBox(height: u(8)),
        PixelButton(
          label: words.customUse,
          wide: true,
          onPressed: () => Navigator.of(context)
              .pop(BlockLengths(focusMinutes: _focus, breakMinutes: _break)),
        ),
      ],
    );
  }
}

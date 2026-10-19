import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:tomo_core/pet/pet_look.dart';
import 'package:tomo_core/pet/pet_service.dart';
import 'package:tomo_core/pet/run_script.dart';

import '../l10n/app_localizations.dart';
import '../pet/reward_view.dart';
import '../ui/buttons.dart';
import '../ui/pixel_box.dart';
import '../ui/screen_body.dart';
import '../ui/sharp_text.dart';
import '../ui/text_field.dart';
import '../ui/tomo_theme.dart';
import '../ui/ui_pixel.dart';
import 'after_block.dart';

/// The hatch takeover (spec §8.7, ADR-0012): the only thing in Tomo that
/// clears the screen. No header, no minimise, no buttons while the egg
/// shakes and breaks; then the pet's hatch line, the **Name your Geode**
/// field (it says what hatched, ADR-0031) and *Done* step in together.
///
/// [name] holds the name, pre-filled with the species name; the first time
/// the field is touched it is all selected, so typing replaces it. [onDone]
/// is null while the name is being written.
class HatchTakeover extends StatefulWidget {
  const HatchTakeover({
    super.key,
    required this.frame,
    required this.rest,
    required this.semanticLabel,
    required this.line,
    required this.name,
    required this.failed,
    required this.onDone,
  });

  final RunFrame frame;

  /// How the pet looks once the run is over.
  final PetLook rest;
  final String semanticLabel;

  /// The pet's hatch line.
  final String line;

  final TextEditingController name;

  /// Whether the last *Done* failed to write: the plain error line shows.
  final bool failed;

  final VoidCallback? onDone;

  /// The pet's spot during the takeover (spec §7.1).
  static const spot = 192.0;

  @override
  State<HatchTakeover> createState() => _HatchTakeoverState();
}

class _HatchTakeoverState extends State<HatchTakeover> {
  final _focus = FocusNode();
  var _touched = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_selectOnce);
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  /// The pre-filled name is all selected the first time the field is
  /// touched, after the tap has placed the caret.
  void _selectOnce() {
    if (!_focus.hasFocus || _touched) return;
    _touched = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final name = widget.name;
      name.selection = TextSelection(
        baseOffset: 0,
        extentOffset: name.text.length,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final words = AppLocalizations.of(context);
    final label = words.hatchName(words.speciesName(widget.rest.species.name));
    final colours = TomoTheme.of(context);
    final u = UiPixel.of(context);
    final payload = widget.frame.payload;
    return ScreenBody(
      content: const [],
      middle: [
        Center(
          child: RewardPet(
            frame: widget.frame,
            rest: widget.rest,
            spot: HatchTakeover.spot,
            semanticLabel: widget.semanticLabel,
          ),
        ),
        SteppingIn(
          stepIn: payload,
          child: PixelText(widget.line, textAlign: TextAlign.center),
        ),
      ],
      bottomGap: 5,
      bottom: [
        SteppingIn(
          stepIn: payload,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsetsDirectional.only(start: u(1)),
                child: ExcludeSemantics(
                  child: PixelText(
                    label,
                    step: TypeStep.caption,
                    colour: colours.muted,
                  ),
                ),
              ),
              SizedBox(height: u(3)),
              PixelTextField(
                controller: widget.name,
                focusNode: _focus,
                label: label,
                maxLines: 1,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(maxPetNameLength),
                ],
                onSubmitted: (_) => widget.onDone?.call(),
              ),
            ],
          ),
        ),
        if (widget.failed)
          PixelBox(
            fill: colours.sunken,
            child: Padding(
              padding: EdgeInsets.all(u(5)),
              child: PixelText(words.error),
            ),
          ),
        SteppingIn(
          stepIn: payload,
          child: PixelButton(
            label: words.hatchDone,
            wide: true,
            onPressed: widget.onDone,
          ),
        ),
      ],
    );
  }
}

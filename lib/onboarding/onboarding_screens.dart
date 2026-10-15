import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tomo_core/art/pixel_art.dart';
import 'package:tomo_core/pet/pet_look.dart';
import 'package:tomo_core/pet/personality.dart';
import 'package:tomo_core/pet/species.dart';
import 'package:tomo_core/result.dart';
import 'package:tomo_core/tasks/task_service.dart';
import 'package:tomo_core/voice/pet_moment.dart';

import '../app/providers.dart';
import '../app/routes.dart';
import '../l10n/app_localizations.dart';
import '../pet/pet_view.dart';
import '../ui/buttons.dart';
import '../ui/motion.dart';
import '../ui/pixel_box.dart';
import '../ui/pixel_icon.dart';
import '../ui/screen_body.dart';
import '../ui/segmented.dart';
import '../ui/sharp_text.dart';
import '../ui/text_field.dart';
import '../ui/tomo_theme.dart';
import '../ui/ui_pixel.dart';
import '../voice/pet_voice.dart';

// Onboarding (spec §8.2, ADR-0012): two screens, once ever, in the neutral
// grey of the egg. No account, no permissions, nothing taught.
//
// Nothing is written until the second screen is finished or skipped; then
// one transaction makes the pet, the project and the first task. Cut off
// before that, the next start opens on the first screen again.

/// Onboarding 1, *Choose your pet*: the three starters, the chosen pet
/// describing itself, and Quiet / Chatty.
class PickPetScreen extends StatefulWidget {
  const PickPetScreen({super.key});

  @override
  State<PickPetScreen> createState() => _PickPetScreenState();
}

class _PickPetScreenState extends State<PickPetScreen> {
  var _species = Species.geode;
  var _personality = Personality.quiet;

  void _next() => Navigator.of(context).push(
    PixelPageRoute<void>(
      settings: const RouteSettings(name: '/onboarding/task'),
      builder: (_) =>
          FirstTaskScreen(species: _species, personality: _personality),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final words = AppLocalizations.of(context);
    final colours = TomoTheme.of(context);
    final u = UiPixel.of(context);
    return ScreenBody(
      content: [
        _Heading(title: words.pickTitle, line: words.pickLine),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final species in Species.values) ...[
              if (species != Species.values.first) SizedBox(width: u(4)),
              Expanded(
                child: _PetTile(
                  species: species,
                  chosen: species == _species,
                  onPressed: () => setState(() => _species = species),
                ),
              ),
            ],
          ],
        ),
        PixelText(
          petLine(
            words,
            moment: const SetupMoment(),
            species: _species,
            personality: _personality,
          ),
          textAlign: TextAlign.center,
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.only(left: u(1)),
              child: PixelText(words.persLabel),
            ),
            SizedBox(height: u(3)),
            PixelSegmented<Personality>(
              segments: [
                Segment(Personality.quiet, words.persQuiet),
                Segment(Personality.chatty, words.persChatty),
              ],
              selected: _personality,
              onChanged: (value) => setState(() => _personality = value),
            ),
            SizedBox(height: u(3)),
            Padding(
              padding: EdgeInsets.only(left: u(1)),
              child: PixelText(
                words.persHint,
                step: TypeStep.caption,
                colour: colours.muted,
              ),
            ),
          ],
        ),
      ],
      bottom: [
        PixelButton(label: words.onboardingNext, wide: true, onPressed: _next),
      ],
    );
  }
}

/// A starter on its tile at stage 1 (spec §7.1, 96 pt). The chosen one is
/// sunken with a check before its name; the others are surface, muted and
/// still. Shade and the check say which, never a pet's colour.
class _PetTile extends StatelessWidget {
  const _PetTile({
    required this.species,
    required this.chosen,
    required this.onPressed,
  });

  final Species species;
  final bool chosen;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final words = AppLocalizations.of(context);
    final colours = TomoTheme.of(context);
    final u = UiPixel.of(context);
    final ink = chosen ? colours.ink : colours.muted;
    final reduce = MediaQuery.disableAnimationsOf(context);
    return Pressable(
      onPressed: onPressed,
      selected: chosen,
      inMutuallyExclusiveGroup: true,
      builder: (context, pressed, ring) {
        final fill = chosen ? colours.sunken : colours.surface;
        return PixelBox(
          fill: pressed ? colours.pressed(fill) : fill,
          ring: ring ? colours.accent : null,
          child: Padding(
            padding: EdgeInsets.fromLTRB(u(2), u(6), u(2), u(5)),
            child: Column(
              children: [
                LayoutBuilder(
                  // The tile is the button, and its name says what it is.
                  builder: (context, constraints) => ExcludeSemantics(
                    child: IgnorePointer(
                      child: PetView(
                        look: HatchedLook(
                          species: species,
                          movement: reduce ? Movement.reduced : Movement.full,
                          stage: 1,
                          // The chosen pet is alive; the others wait, still.
                          face: chosen ? Face.resting : Face.still,
                        ),
                        spot: constraints.maxWidth < PetSpot.setupTile
                            ? constraints.maxWidth
                            : PetSpot.setupTile,
                        semanticLabel: '',
                      ),
                    ),
                  ),
                ),
                SizedBox(height: u(3)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (chosen) ...[
                      PixelIcon(IconName.check, colour: ink),
                      SizedBox(width: u(2)),
                    ],
                    Flexible(
                      child: PixelText(
                        words.speciesName(species.name),
                        colour: ink,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Onboarding 2, *What are you working on?*: one line that becomes both the
/// first project's name and its first task, or *Skip* for one plain project
/// and no task.
class FirstTaskScreen extends ConsumerStatefulWidget {
  const FirstTaskScreen({
    super.key,
    required this.species,
    required this.personality,
  });

  final Species species;
  final Personality personality;

  @override
  ConsumerState<FirstTaskScreen> createState() => _FirstTaskScreenState();
}

class _FirstTaskScreenState extends ConsumerState<FirstTaskScreen> {
  final _line = TextEditingController();
  var _busy = false;
  var _failed = false;

  bool get _typed => _line.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _line.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _line.dispose();
    super.dispose();
  }

  /// Writes everything in one go, then puts the shell in onboarding's place.
  /// [line] null is *Skip*.
  Future<void> _finish(String? line) async {
    if (_busy) return;
    setState(() => _busy = true);
    final words = AppLocalizations.of(context);
    final result = await ref
        .read(onboardingProvider)
        .complete(
          species: widget.species,
          personality: widget.personality,
          defaultProjectName: words.defaultProject,
          line: line,
        );
    if (!mounted) return;
    switch (result) {
      case Success():
        finishOnboarding(context);
      case Failure():
        // Already recorded. Nothing was written, so trying again is safe.
        setState(() {
          _busy = false;
          _failed = true;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final words = AppLocalizations.of(context);
    final colours = TomoTheme.of(context);
    final u = UiPixel.of(context);
    return ScreenBody(
      content: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Transform.translate(
            offset: Offset(-u(6), 0),
            child: PixelIconButton(
              icon: PixelIcon(IconName.back, colour: colours.ink),
              semanticLabel: words.back,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
        ),
        _Heading(title: words.taskTitle, line: words.taskLine),
        PixelTextField(
          controller: _line,
          autofocus: true,
          inputFormatters: [
            LengthLimitingTextInputFormatter(maxProjectNameLength),
          ],
          onSubmitted: (text) {
            if (_typed) _finish(text);
          },
        ),
        if (_failed)
          PixelBox(
            fill: colours.sunken,
            child: Padding(
              padding: EdgeInsets.all(u(5)),
              child: PixelText(words.error),
            ),
          ),
      ],
      bottomGap: 5,
      bottom: [
        PixelButton(
          label: words.onboardingDone,
          wide: true,
          onPressed: _typed ? () => _finish(_line.text) : null,
        ),
        PixelButton(
          label: words.onboardingSkip,
          kind: ButtonKind.quietMuted,
          wide: true,
          onPressed: () => _finish(null),
        ),
      ],
    );
  }
}

/// A screen's title and its one line under it.
class _Heading extends StatelessWidget {
  const _Heading({required this.title, required this.line});

  final String title;
  final String line;

  @override
  Widget build(BuildContext context) {
    final u = UiPixel.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PixelText(title, step: TypeStep.title),
        SizedBox(height: u(3)),
        PixelText(line, colour: TomoTheme.of(context).muted),
      ],
    );
  }
}

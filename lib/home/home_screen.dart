import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tomo_core/art/pixel_art.dart';
import 'package:tomo_core/focus/projection.dart';
import 'package:tomo_core/pet/pet_look.dart';
import 'package:tomo_core/pet/pet_standing.dart';
import 'package:tomo_core/rewards/rewards.dart';

import '../app/providers.dart';
import '../app/routes.dart';
import '../l10n/app_localizations.dart';
import '../settings/settings_screen.dart';
import '../stats/stats_screen.dart';
import '../pet/pet_label.dart';
import '../pet/pet_view.dart';
import '../ui/buttons.dart';
import '../ui/exp_bar.dart';
import '../ui/pixel_box.dart';
import '../ui/pixel_icon.dart';
import '../ui/screen_body.dart';
import '../ui/sharp_text.dart';
import '../ui/tomo_theme.dart';
import '../ui/ui_pixel.dart';

/// Home (spec §8.3): the pet, its name and EXP, and *Start focusing*; the
/// level chip to Stats and the gear to Settings. Before the hatch, the egg
/// and its line instead of the chip, the name and the bar.
///
/// The pet says hello each time the app opens onto Home (§7.6): a cold start
/// that lands here, or coming back from the background while Home is the
/// screen showing. Switching tabs, or coming back from Stats, is not opening.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _cues = PetCues();
  late final AppLifecycleListener _lifecycle;
  Timer? _tick;

  /// The app has just opened; the hello plays if it opened onto Home.
  var _helloOwed = true;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onShow: _opened);
  }

  @override
  void dispose() {
    _tick?.cancel();
    _lifecycle.dispose();
    _cues.dispose();
    super.dispose();
  }

  void _opened() {
    _helloOwed = true;
    _helloIfOpenedHere();
  }

  /// Plays the owed hello if Home is what the app opened onto: its tab is
  /// shown and nothing covers it. The pet plays it only if it is resting.
  void _helloIfOpenedHere() {
    if (!_helloOwed || !mounted) return;
    _helloOwed = false;
    if (TickerMode.valuesOf(context).enabled) _cues.hello();
  }

  DateTime _now() => ref.read(databaseProvider).clock();

  /// Looks again when the pet's look next changes with the clock: each
  /// minute of a block (the egg cracks), the end of a block or a break.
  void _wakeAt(PetStanding? pet, DateTime now) {
    _tick?.cancel();
    final next = pet?.nextChangeAfter(now);
    if (next == null) return;
    _tick = Timer(next.difference(now), () {
      if (mounted) setState(() {});
    });
  }

  void _startFocusing(PetStanding? pet) {
    final live = project(pet?.cycle, _now()).state != FocusState.idle;
    // While a cycle is live, *Start focusing* opens Focus, like the banner
    // (§17, C3).
    if (live) {
      openFocus(context);
    } else {
      unawaited(openTaskPicker(context));
    }
  }

  @override
  Widget build(BuildContext context) {
    final pet = ref.watch(petStandingProvider);
    final calmPet = ref.watch(calmPetProvider);
    final clockNotice = ref.watch(clockNoticeProvider);
    final words = AppLocalizations.of(context);
    final colours = TomoTheme.of(context);
    final u = UiPixel.of(context);

    final now = _now();
    _wakeAt(pet, now);
    final look = pet?.lookAt(
      now,
      calmPet: calmPet,
      reduceMotion: MediaQuery.disableAnimationsOf(context),
    );
    if (look != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _helloIfOpenedHere());
    }
    final hatched = look is HatchedLook;
    final speciesName = pet == null ? '' : words.speciesName(pet.species.name);
    final name = pet?.name ?? speciesName;

    return ColoredBox(
      color: colours.ground,
      child: ScreenBody(
        content: [
          _TopRow(level: hatched ? pet!.level : null),
          if (clockNotice)
            _ClockNotice(
              onDismiss: () => ref.read(clockNoticeProvider.notifier).dismiss(),
            ),
          if (look != null)
            Center(
              child: PetView(
                look: look,
                spot: PetSpot.home,
                cues: _cues,
                semanticLabel: petLabel(words, pet!, look),
              ),
            ),
          if (hatched)
            // The pet's own label already says its name and EXP.
            ExcludeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PixelText(
                    name,
                    step: TypeStep.petName,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: u(6)),
                  _ExpMeter(exp: pet!.exp),
                ],
              ),
            )
          else if (pet != null)
            PixelText(
              words.egg(words.eggInLine(pet.species.name)),
              colour: colours.muted,
              textAlign: TextAlign.center,
            ),
        ],
        bottom: [
          PixelButton(
            label: words.startFocusing,
            wide: true,
            onPressed: () => _startFocusing(pet),
          ),
        ],
      ),
    );
  }
}

/// The level chip at the left, once the pet has hatched, and the gear at the
/// right.
class _TopRow extends StatelessWidget {
  const _TopRow({required this.level});

  /// Null before the hatch: no chip.
  final int? level;

  @override
  Widget build(BuildContext context) {
    final words = AppLocalizations.of(context);
    final colours = TomoTheme.of(context);
    final u = UiPixel.of(context);
    final level = this.level;
    return Row(
      children: [
        if (level != null)
          Pressable(
            onPressed: () =>
                pushInTab(context, (_) => const StatsScreen()),
            semanticLabel: words.srLevelChip(level),
            builder: (context, pressed, ring) => ConstrainedBox(
              // The chip is small; its target is the full 48 pt.
              constraints: BoxConstraints(
                minWidth: u.target,
                minHeight: u.target,
              ),
              child: Center(
                widthFactor: 1,
                child: PixelBox(
                  fill: pressed
                      ? colours.pressed(colours.sunken)
                      : colours.sunken,
                  ring: ring ? colours.accent : null,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: u(6),
                      vertical: u(3),
                    ),
                    child: ExcludeSemantics(
                      child: PixelText.number(
                        words.levelChip(level),
                        step: TypeStep.caption,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        const Spacer(),
        Transform.translate(
          offset: Offset(u(6), 0),
          child: PixelIconButton(
            icon: PixelIcon(IconName.gear, colour: colours.ink),
            semanticLabel: words.settings,
            onPressed: () =>
                pushInTab(context, (_) => const SettingsScreen()),
          ),
        ),
      ],
    );
  }
}

/// The 20-block EXP bar and "480 / 600 EXP" under it: EXP toward the next
/// level, one block to every 30.
class _ExpMeter extends StatelessWidget {
  const _ExpMeter({required this.exp});

  final int exp;

  @override
  Widget build(BuildContext context) {
    final words = AppLocalizations.of(context);
    final u = UiPixel.of(context);
    final toward = exp % expPerLevel;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExpBar(lit: toward * ExpBar.blocks ~/ expPerLevel),
        SizedBox(height: u(2)),
        PixelText.number(
          words.expLine(toward),
          step: TypeStep.caption,
          colour: TomoTheme.of(context).muted,
        ),
      ],
    );
  }
}

/// The clock notice (spec §8.3, §4.4): a sunken strip in plain voice with a
/// close. Never a dialog.
class _ClockNotice extends StatelessWidget {
  const _ClockNotice({required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final words = AppLocalizations.of(context);
    final colours = TomoTheme.of(context);
    final u = UiPixel.of(context);
    return PixelBox(
      fill: colours.sunken,
      child: Padding(
        padding: EdgeInsets.only(left: u(7)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: u(5)),
                child: PixelText(words.clock),
              ),
            ),
            SizedBox(width: u(2)),
            PixelIconButton(
              icon: PixelIcon(IconName.close, colour: colours.muted),
              semanticLabel: words.dismiss,
              onPressed: onDismiss,
            ),
          ],
        ),
      ),
    );
  }
}

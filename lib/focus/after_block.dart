import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tomo_core/focus/choices.dart';
import 'package:tomo_core/pet/run_script.dart';
import 'package:tomo_core/rewards/rewards.dart';
import 'package:tomo_core/stats/stats.dart';

import '../app/providers.dart';
import '../l10n/app_localizations.dart';
import '../pet/reward_view.dart';
import '../ui/buttons.dart';
import '../ui/pixel_box.dart';
import '../ui/screen_body.dart';
import '../ui/sharp_text.dart';
import '../ui/tomo_theme.dart';
import '../ui/ui_pixel.dart';

/// What Focus shows once a block or a break has ended (spec §8.4, §8.5),
/// and while a beat run plays: the header, the notes, the pet, its line, the
/// EXP bar with the level and EXP under it, then the estimate card and the
/// choices.
///
/// While a run plays, [stepIn] is null and the card and the choices keep
/// their room unseen; the run steps them in (spec §7.5). The dither covers
/// the header and notes only (§17, C89).
class AfterBlock extends StatelessWidget {
  const AfterBlock({
    super.key,
    required this.header,
    this.notes = const [],
    required this.pet,
    this.line,
    required this.level,
    required this.exp,
    required this.bar,
    this.plate,
    this.dither = false,
    this.card,
    this.failed = false,
    required this.choices,
    required this.stepIn,
  });

  final Widget header;

  /// Sunken strips under the header: the *while you were away* note.
  final List<String> notes;

  final Widget pet;

  /// The pet's line, under the pet.
  final Widget? line;

  /// The level and EXP the caption under the bar gives.
  final int level;
  final int exp;

  final BarShown bar;

  /// "Level 13" or "Task done", hanging under the bar during its beat.
  final Plate? plate;
  final bool dither;

  /// The estimate card, above the choices.
  final Widget? card;

  /// Whether the last choice failed to write: the plain error line shows.
  final bool failed;

  final List<AfterChoice> choices;

  /// How far the card and the choices have stepped in; null until they do.
  final StepIn? stepIn;

  @override
  Widget build(BuildContext context) {
    final words = AppLocalizations.of(context);
    final colours = TomoTheme.of(context);
    final u = UiPixel.of(context);
    Widget sunken(String text) => PixelBox(
      fill: colours.sunken,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: u(7), vertical: u(5)),
        child: PixelText(text),
      ),
    );
    final card = this.card;
    return ScreenBody(
      content: [
        DitherOver(
          active: dither,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: ScreenBody.spaced(context, [
              header,
              for (final note in notes) sunken(note),
            ], 6),
          ),
        ),
      ],
      middle: [
        pet,
        ?line,
        // The pet's own label says the level and the EXP: not read twice.
        ExcludeSemantics(
          child: RewardBar(
            bar: bar,
            plate: plate,
            caption: Row(
              children: [
                PixelText.number(
                  words.levelChip(level),
                  step: TypeStep.caption,
                  colour: colours.muted,
                ),
                const Spacer(),
                PixelText.number(
                  words.expLine(exp % expPerLevel),
                  step: TypeStep.caption,
                  colour: colours.muted,
                ),
              ],
            ),
          ),
        ),
      ],
      bottom: [
        for (final part in [
          ?card,
          if (failed) sunken(words.error),
          for (final choice in choices)
            PixelButton(
              label: choice.label,
              kind: switch (choice.weight) {
                ChoiceWeight.primary => ButtonKind.primary,
                ChoiceWeight.secondary => ButtonKind.secondary,
                ChoiceWeight.quiet => ButtonKind.quiet,
              },
              wide: true,
              onPressed: choice.onPressed,
            ),
        ])
          SteppingIn(stepIn: stepIn, child: part),
      ],
      bottomGap: 5,
    );
  }
}

/// One of the choices: its words, its weight, and what it does (null: turned
/// off while another is being written).
typedef AfterChoice = ({
  String label,
  ChoiceWeight weight,
  VoidCallback? onPressed,
});

/// The estimate card (spec §8.4, §4.9): "Is this task done?", the pet's fact
/// line, then *Not yet* beside *Mark done*. Ignorable: any choice puts it
/// away.
class EstimateCard extends StatelessWidget {
  const EstimateCard({
    super.key,
    required this.fact,
    required this.onNotYet,
    required this.onMarkDone,
  });

  final String fact;
  final VoidCallback? onNotYet;
  final VoidCallback? onMarkDone;

  @override
  Widget build(BuildContext context) {
    final words = AppLocalizations.of(context);
    final colours = TomoTheme.of(context);
    final u = UiPixel.of(context);
    return PixelBox(
      fill: colours.surface,
      child: Padding(
        padding: EdgeInsets.all(u(7)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PixelText(words.estimateTitle),
            PixelText(fact, step: TypeStep.caption, colour: colours.muted),
            SizedBox(height: u(5)),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: PixelButton(
                    label: words.notYet,
                    kind: ButtonKind.secondary,
                    wide: true,
                    onPressed: onNotYet,
                  ),
                ),
                SizedBox(width: u(6)),
                Expanded(
                  child: PixelButton(
                    label: words.estimateMarkDone,
                    wide: true,
                    onPressed: onMarkDone,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The pet's line for a moment made from today's blocks, centred: read
/// once, when it first shows (spec §10, C35).
class TodayLine extends ConsumerStatefulWidget {
  const TodayLine({super.key, required this.line});

  /// The words, given today's totals.
  final String Function(DayTotals today) line;

  @override
  ConsumerState<TodayLine> createState() => _TodayLineState();
}

class _TodayLineState extends ConsumerState<TodayLine> {
  DayTotals? _today;

  @override
  void initState() {
    super.initState();
    unawaited(_read());
  }

  Future<void> _read() async {
    final today = await ref
        .read(statsReaderProvider)
        .dayOf(ref.read(databaseProvider).clock());
    if (mounted) setState(() => _today = today);
  }

  @override
  Widget build(BuildContext context) {
    final today = _today;
    if (today == null) return const SizedBox.shrink();
    return PixelText(widget.line(today), textAlign: TextAlign.center);
  }
}

/// [child] unseen, its room kept, until [stepIn] brings it up into place.
class SteppingIn extends StatelessWidget {
  const SteppingIn({super.key, required this.stepIn, required this.child});

  final StepIn? stepIn;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final stepIn = this.stepIn;
    return Visibility.maintain(
      visible: stepIn != null,
      child: Transform.translate(
        offset: Offset(0, UiPixel.of(context)(stepIn?.dy ?? 0)),
        child: Opacity(opacity: stepIn?.opacity ?? 0, child: child),
      ),
    );
  }
}

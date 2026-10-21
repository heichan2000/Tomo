import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:tomo_core/stats/stats.dart';

import '../app/providers.dart';
import '../l10n/app_localizations.dart';
import '../ui/back_header.dart';
import '../ui/pixel_box.dart';
import '../ui/screen_body.dart';
import '../ui/sharp_text.dart';
import '../ui/tomo_theme.dart';
import '../ui/ui_pixel.dart';
import '../voice/pet_voice.dart';

/// Stats (spec §8.9, ADR-0026): back, the title, and four all-time numbers,
/// each in a surface row with its label muted at the left and the number in
/// ink at the right. No pet, no icons, no buttons.
///
/// The numbers are counted fresh from the block records each time it opens.
/// There is no empty state: it opens only from the level chip, which shows
/// from the hatch, and the hatch is a finished block.
class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  late final Future<Stats> _stats = ref.read(statsReaderProvider).read();

  @override
  Widget build(BuildContext context) {
    final words = AppLocalizations.of(context);
    final colours = TomoTheme.of(context);
    final number = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    );
    return ColoredBox(
      color: colours.ground,
      child: FutureBuilder(
        future: _stats,
        builder: (context, read) {
          final stats = read.data;
          return ScreenBody(
            content: [
              BackHeader(backLabel: words.back, title: words.statsTitle),
              if (stats != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: ScreenBody.spaced(context, [
                    StatRow(words.statLevel, number.format(stats.level)),
                    StatRow(
                      words.statTimeFocused,
                      focusTime(words, stats.minutesFocused),
                    ),
                    StatRow(
                      words.statBlocks,
                      number.format(stats.blocksFinished),
                    ),
                    StatRow(words.statDays, number.format(stats.daysFocused)),
                  ], 3),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// One Stats row: [label] muted at the left, [value] in ink at the right.
/// The value is a number (spec §9.2): it stops growing at 130% and never
/// wraps. When the two don't fit side by side, the value drops under the
/// label, still at the right, as on Tomo Stats Screen.
///
/// A screen reader reads the row as one item.
class StatRow extends StatelessWidget {
  const StatRow(this.label, this.value, {super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colours = TomoTheme.of(context);
    final u = UiPixel.of(context);
    final dpr = u.devicePixelRatio;
    final direction = Directionality.of(context);
    final labelDots = dotsAt(context, TypeStep.body);
    final valueDots = SharpText.of(
      context,
    ).capped().dotsFor(TypeStep.body.dots(dpr));
    return MergeSemantics(
      child: PixelBox(
        fill: colours.surface,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: u.target),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: u(7), vertical: u(6)),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final room = constraints.maxWidth * dpr;
                final sideBySide =
                    lineWidthDots(label, labelDots, direction) +
                        6 * u.dots +
                        lineWidthDots(value, valueDots, direction) <=
                    room + 1e-6;
                final name = PixelText(label, colour: colours.muted);
                final number = PixelText.number(value);
                if (sideBySide) {
                  return Row(children: [name, const Spacer(), number]);
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    name,
                    SizedBox(height: u(1)),
                    Align(alignment: Alignment.centerRight, child: number),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

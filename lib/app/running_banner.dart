import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tomo_core/art/pixel_art.dart';
import 'package:tomo_core/focus/live_cycle.dart';
import 'package:tomo_core/focus/projection.dart';
import 'package:tomo_core/focus/quiet_clock.dart';
import 'package:tomo_core/pet/pet_standing.dart';

import '../l10n/app_localizations.dart';
import '../ui/buttons.dart';
import '../ui/pixel_box.dart';
import '../ui/pixel_icon.dart';
import '../ui/sharp_text.dart';
import '../ui/tomo_theme.dart';
import '../ui/ui_pixel.dart';
import 'providers.dart';
import 'routes.dart';

/// The banner Focus leaves when it is minimised (spec §8.1, §8.3,
/// ADR-0003), docked above the tab bar on every tab. Tapping it opens Focus
/// again. Nothing shows while no cycle is live.
///
/// - **Running**: a sunken strip with a 4-UI-pixel accent square, the task,
///   and "19 min left" (or "Break · about 4 min") in rough minutes, updated
///   as they change (ADR-0010).
/// - **Finished**: an accent strip, "Block done · 25 min counted" or "Break
///   over", which wraps at large text. A block's beat waits for the tap: it
///   plays only on Focus (§7.4).
class RunningBannerSlot extends ConsumerStatefulWidget {
  const RunningBannerSlot({super.key});

  @override
  ConsumerState<RunningBannerSlot> createState() => _RunningBannerSlotState();
}

class _RunningBannerSlotState extends ConsumerState<RunningBannerSlot> {
  Timer? _wake;
  FocusState? _shown;

  @override
  void dispose() {
    _wake?.cancel();
    super.dispose();
  }

  DateTime _now() => ref.read(databaseProvider).clock();

  /// Looks again when what the banner says next changes: its rough minutes,
  /// or the end of the block or the break.
  void _wakeAt(PetStanding? pet, DateTime now) {
    _wake?.cancel();
    final cycle = pet?.cycle;
    final end = switch (project(cycle, now).state) {
      FocusState.focusRunning => cycle!.endAt,
      FocusState.breakRunning => cycle!.breakEndAt,
      _ => null,
    };
    final candidates = [
      ?pet?.nextChangeAfter(now),
      if (end != null) ?nextRoughChange(now: now, end: end),
    ];
    if (candidates.isEmpty) return;
    final next = candidates.reduce((a, b) => a.isBefore(b) ? a : b);
    _wake = Timer(next.difference(now), () {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final pet = ref.watch(petStandingProvider);
    final task = ref.watch(cycleTaskProvider)?.task;
    final words = AppLocalizations.of(context);
    final now = _now();
    final cycle = pet?.cycle;
    final state = project(cycle, now).state;
    if (_shown != null && state != _shown && state != FocusState.idle) {
      // A block that ended here is settled now, so the break under
      // auto-start runs on time (spec §4.5).
      unawaited(ref.read(focusCycleServiceProvider).reconcile());
    }
    _shown = state;
    _wakeAt(pet, now);
    if (pet == null || cycle == null || task == null) {
      return const SizedBox.shrink();
    }

    final banner = switch (state) {
      FocusState.idle => null,
      _ when pet.owedRun.isNotEmpty || state == FocusState.focusComplete =>
        _Finished(words.bannerBlockDone(cycle.focusMinutes)),
      FocusState.breakComplete => _Finished(words.bannerBreakOver),
      FocusState.focusRunning => _Running(
        task: task.title,
        left: _blockLeft(words, cycle, now),
      ),
      FocusState.breakRunning => _Running(
        task: task.title,
        left: _breakLeft(words, cycle, now),
      ),
      // Settled already, so reached only above.
      FocusState.focusComplete => null,
    };
    if (banner == null) return const SizedBox.shrink();

    final colours = TomoTheme.of(context);
    final u = UiPixel.of(context);
    return ColoredBox(
      color: colours.ground,
      child: Padding(
        padding: EdgeInsets.fromLTRB(u(6), 0, u(6), u(4)),
        child: banner,
      ),
    );
  }

  String _blockLeft(AppLocalizations words, LiveCycle cycle, DateTime now) {
    final minutes = roughMinutes(cycle.endAt.difference(now));
    return minutes == null ? words.clockUnderMinute : words.bannerLeft(minutes);
  }

  String _breakLeft(AppLocalizations words, LiveCycle cycle, DateTime now) {
    final minutes = roughMinutes(cycle.breakEndAt!.difference(now));
    return minutes == null
        ? words.bannerBreakUnderMinute
        : words.bannerBreak(minutes);
  }
}

/// The running banner: the accent square, the task (cut short if long; the
/// minutes under it carry the news), the time left, and the chevron up.
class _Running extends StatelessWidget {
  const _Running({required this.task, required this.left});

  final String task;
  final String left;

  @override
  Widget build(BuildContext context) {
    final colours = TomoTheme.of(context);
    final u = UiPixel.of(context);
    return _Strip(
      fill: colours.sunken,
      label: '$task. $left',
      children: [
        PixelBox(
          fill: colours.accent,
          cutCorners: false,
          child: SizedBox.square(dimension: u(4)),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PixelText.cut(task),
              PixelText(left, step: TypeStep.caption, colour: colours.muted),
            ],
          ),
        ),
        PixelIcon(IconName.up, colour: colours.ink),
      ],
    );
  }
}

/// The finished banner: an accent strip whose words wrap at large text.
class _Finished extends StatelessWidget {
  const _Finished(this.words);

  final String words;

  @override
  Widget build(BuildContext context) {
    final colours = TomoTheme.of(context);
    return _Strip(
      fill: colours.accent,
      label: words,
      children: [
        Expanded(child: PixelText(words, colour: colours.onAccent)),
        PixelIcon(IconName.up, colour: colours.onAccent),
      ],
    );
  }
}

/// One banner strip: a button the whole width, opening Focus.
class _Strip extends StatelessWidget {
  const _Strip({
    required this.fill,
    required this.label,
    required this.children,
  });

  final Color fill;
  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colours = TomoTheme.of(context);
    final u = UiPixel.of(context);
    return Pressable(
      onPressed: () => openFocus(context),
      semanticLabel: label,
      builder: (context, pressed, ring) => PixelBox(
        fill: pressed ? colours.pressed(fill) : fill,
        ring: ring ? colours.accent : null,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: u.target),
          child: Padding(
            padding: EdgeInsets.fromLTRB(u(7), u(4), u(4), u(4)),
            child: ExcludeSemantics(
              child: Row(
                children: [
                  for (final (i, child) in children.indexed) ...[
                    if (i > 0) SizedBox(width: u(6)),
                    child,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

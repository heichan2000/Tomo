import 'dart:async';

import 'package:flutter/material.dart' show MaterialLocalizations;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tomo_core/art/pixel_art.dart';
import 'package:tomo_core/focus/block_lengths.dart';
import 'package:tomo_core/focus/focus_cycle_service.dart';
import 'package:tomo_core/focus/live_cycle.dart';
import 'package:tomo_core/focus/projection.dart';
import 'package:tomo_core/pet/pet_standing.dart';
import 'package:tomo_core/result.dart';
import 'package:tomo_core/stats/stats.dart';
import 'package:tomo_core/tasks/task.dart';
import 'package:tomo_core/tasks/task_status.dart';
import 'package:tomo_core/voice/pet_moment.dart';

import '../app/placeholder_screens.dart';
import '../app/providers.dart';
import '../l10n/app_localizations.dart';
import '../pet/pet_label.dart';
import '../pet/pet_view.dart';
import '../platform/notifications.dart';
import '../ui/buttons.dart';
import '../ui/pixel_box.dart';
import '../ui/pixel_icon.dart';
import '../ui/rows.dart';
import '../ui/screen_body.dart';
import '../ui/sharp_text.dart';
import '../ui/sheet.dart';
import '../ui/tomo_theme.dart';
import '../ui/ui_pixel.dart';
import '../voice/pet_voice.dart';
import 'clock_view.dart';
import 'focus_screen.dart';
import 'task_picker.dart';

/// Focus while a cycle is live (spec §8.4): a block running, a break, and
/// the next block counting down. What a finished block or break shows is a
/// stand-in until *Focus: block done, break over and the choices* builds it.
///
/// It reads the pet and the cycle as Home does, and looks again whenever the
/// cycle can change with the clock alone. Minimise, and Android back while a
/// block or break runs, close it and end nothing (ADR-0003). The screen is
/// not kept awake.
class LiveFocus extends ConsumerStatefulWidget {
  const LiveFocus({super.key});

  /// How long the next block counts down after a break ends on screen
  /// (spec §4.8, ADR-0011).
  static const countdown = 10;

  @override
  ConsumerState<LiveFocus> createState() => _LiveFocusState();
}

class _LiveFocusState extends ConsumerState<LiveFocus> {
  late final AppLifecycleListener _lifecycle;
  Timer? _wake;

  /// The state the screen last showed, to see a change as it happens.
  FocusState? _shown;

  /// When the next block began counting down; null when it isn't.
  DateTime? _countdownFrom;

  /// The open *Stop this block?* sheet, if any.
  PixelSheetRoute<bool>? _stopSheet;

  var _busy = false;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _lookAgain);
    // A block that finished while Focus was away is settled as it opens.
    _reconcile();
  }

  @override
  void dispose() {
    _wake?.cancel();
    _lifecycle.dispose();
    super.dispose();
  }

  DateTime _now() => ref.read(databaseProvider).clock();
  FocusCycleService get _cycles => ref.read(focusCycleServiceProvider);

  void _reconcile() => unawaited(_cycles.reconcile());

  /// Looks again when the cycle can next change with the clock alone: each
  /// minute of a block (the egg cracks), its end, the end of a break.
  void _wakeAt(PetStanding? pet, DateTime now) {
    _wake?.cancel();
    final next = pet?.nextChangeAfter(now);
    if (next == null) return;
    _wake = Timer(next.difference(now), _lookAgain);
  }

  /// The clock has moved on: what does the cycle show now?
  void _lookAgain() {
    if (!mounted) return;
    final pet = ref.read(petStandingProvider);
    final cycle = pet?.cycle;
    final now = _now();
    final state = project(cycle, now).state;
    final was = _shown;
    if (was == FocusState.focusRunning && state != FocusState.focusRunning) {
      // The block completed under the open sheet: it counts (spec §4.6).
      _closeStopSheet();
    }
    if (was == FocusState.breakRunning &&
        state == FocusState.breakComplete &&
        _countsDown(cycle!, now)) {
      _countdownFrom = now;
    }
    if (state != was && state != FocusState.focusRunning) _reconcile();
    setState(() {});
  }

  /// Whether a break that just ended counts the next block down (spec §4.8,
  /// ADR-0011): auto-start is on, the break ran out rather than being
  /// skipped, the task isn't done, and Focus is on screen. Off screen
  /// nothing starts.
  bool _countsDown(LiveCycle cycle, DateTime now) {
    final task = ref.read(cycleTaskProvider)?.task;
    final ended = cycle.breakEndAt;
    return cycle.autoStart &&
        cycle.breakSkippedAt == null &&
        ended != null &&
        // Seen as it happened, not on coming back to it.
        now.difference(ended) < const Duration(seconds: 2) &&
        task?.status != TaskStatus.done &&
        appIsForeground();
  }

  void _minimise() => Navigator.of(context).pop();

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // The stop sheet (spec §8.6).

  Future<void> _askToStop() async {
    final sheet = PixelSheetRoute<bool>(
      builder: (_) => const _StopSheet(),
      dismissLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    );
    _stopSheet = sheet;
    final stop = await Navigator.of(context, rootNavigator: true).push(sheet);
    if (_stopSheet == sheet) _stopSheet = null;
    if (stop == true && mounted) await _run(_stopEarly);
  }

  void _closeStopSheet() {
    final sheet = _stopSheet;
    _stopSheet = null;
    if (sheet == null || !sheet.isActive) return;
    if (sheet.isCurrent) {
      sheet.navigator!.pop();
    } else {
      sheet.navigator!.removeRoute(sheet);
    }
  }

  Future<void> _stopEarly() async {
    final stopped = await _cycles.stopEarly();
    if (!mounted) return;
    // Stopped, Focus closes: the egg is never seen closing (spec §7.2). If
    // the block finished first, it counted, and Focus shows that instead.
    if (stopped case Success(value: CycleStanding(state: FocusState.idle))) {
      Navigator.of(context).pop();
    }
  }

  // Commands.

  Future<void> _skipBreak() => _cycles.skipBreak();

  Future<void> _leave() async {
    await _cycles.leave();
    if (mounted) Navigator.of(context).pop();
  }

  /// Another block on the cycle's task, at the cycle's own lengths, with
  /// auto-start as it is set now (spec §4.8).
  Future<void> _startNext(LiveCycle cycle) async {
    _countdownFrom = null;
    final settings = ref.read(settingsProvider);
    final started = await _cycles.startBlock(
      taskId: cycle.taskId,
      lengths: BlockLengths(
        focusMinutes: cycle.focusMinutes,
        breakMinutes: cycle.breakMinutes,
      ),
      autoStart: await settings.autoStart(),
    );
    if (started is Success) {
      final project = ref.read(cycleTaskProvider)?.project;
      if (project != null) await settings.setLastProjectId(project.id);
    }
    if (mounted) setState(() {});
  }

  void _notYet() => setState(() => _countdownFrom = null);

  /// Android back (spec §8.1): minimises while a block or a break runs; on
  /// a finished state it is *Leave*. An open sheet closes first by itself.
  void _back(FocusState state) {
    switch (state) {
      case FocusState.focusRunning || FocusState.breakRunning:
        _minimise();
      case FocusState.focusComplete || FocusState.breakComplete:
        unawaited(_run(_leave));
      case FocusState.idle:
        Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colours = TomoTheme.of(context);
    final pet = ref.watch(petStandingProvider);
    final live = ref.watch(cycleTaskProvider);
    final calmPet = ref.watch(calmPetProvider);
    final access = ref.watch(notificationAccessProvider).value;
    final now = _now();
    final cycle = pet?.cycle;
    final state = project(cycle, now).state;
    _shown = state;
    _wakeAt(pet, now);

    final countdownFrom = _countdownFrom;
    final counting = state == FocusState.breakComplete && countdownFrom != null;

    Widget body;
    if (pet == null || cycle == null || live == null) {
      // Just started, or just ended: the database is a frame behind.
      body = const SizedBox.expand();
    } else {
      final header = FocusHeader(
        picked: PickedTask(live.task, live.project),
        leading: PixelIconButton(
          icon: PixelIcon(IconName.down, colour: colours.ink),
          semanticLabel: AppLocalizations.of(context).minimise,
          onPressed: _minimise,
        ),
        notificationsOff: access == NotificationAccess.denied,
      );
      final look = pet.lookAt(
        now,
        calmPet: calmPet,
        reduceMotion: MediaQuery.disableAnimationsOf(context),
      );
      final petView = Center(
        child: PetView(
          look: look,
          spot: PetSpot.focus,
          semanticLabel: petLabel(AppLocalizations.of(context), pet, look),
        ),
      );
      final ending = state != FocusState.focusRunning && !cycle.isCredited;
      body = switch (state) {
        _ when pet.owedRun.isNotEmpty || ending => _stand(
          'Block done',
          header,
          [('Beat seen', () => _cycles.markBeatRunSeen())],
        ),
        FocusState.focusRunning => _Running(
          header: header,
          pet: petView,
          cycle: cycle,
          task: live.task,
          onStop: _busy ? null : () => unawaited(_askToStop()),
        ),
        FocusState.breakRunning => _Break(
          header: header,
          pet: petView,
          standing: pet,
          cycle: cycle,
          task: live.task,
          onSkip: _busy ? null : () => unawaited(_run(_skipBreak)),
        ),
        FocusState.breakComplete when counting => _Countdown(
          header: header,
          pet: petView,
          standing: pet,
          cycle: cycle,
          from: countdownFrom,
          now: _now,
          onStart: _busy
              ? null
              : () => unawaited(_run(() => _startNext(cycle))),
          onNotYet: _busy ? null : _notYet,
        ),
        FocusState.focusComplete => _stand('Block done', header, [
          ('Take break', () => _cycles.takeBreak()),
          if (live.task.status != TaskStatus.done)
            ('Another block', () => _startNext(cycle)),
          ('Done for now', _leave),
        ]),
        FocusState.breakComplete => _stand('Break over', header, [
          if (live.task.status != TaskStatus.done)
            ('Start another block', () => _startNext(cycle)),
          ('Done for now', _leave),
        ]),
        FocusState.idle => const SizedBox.expand(),
      };
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back(state);
      },
      child: ColoredBox(color: colours.ground, child: body),
    );
  }

  /// The stand-in for what *Focus: block done, break over and the choices*
  /// builds.
  Widget _stand(
    String title,
    Widget header,
    List<(String, Future<void> Function())> actions,
  ) => FocusAfterPlaceholder(
    title: title,
    header: header,
    actions: [
      for (final (label, action) in actions)
        (label, _busy ? null : () => unawaited(_run(action))),
    ],
  );
}

/// A block running (spec §8.4): the pet, Pleased (or the egg cracking, on
/// the first block); the quiet clock and its line; the **Focus** chip; and
/// *Stop early*, quiet and muted, alone at the bottom.
class _Running extends StatelessWidget {
  const _Running({
    required this.header,
    required this.pet,
    required this.cycle,
    required this.task,
    required this.onStop,
  });

  final Widget header;
  final Widget pet;
  final LiveCycle cycle;
  final Task task;
  final VoidCallback? onStop;

  @override
  Widget build(BuildContext context) {
    final words = AppLocalizations.of(context);
    return ScreenBody(
      content: [header],
      middle: [
        pet,
        QuietClock(start: cycle.startAt, end: cycle.endAt, task: task.title),
        Center(
          child: PixelChip(words.chipFocus, tone: ChipTone.accent, big: true),
        ),
      ],
      bottom: [
        PixelButton(
          label: words.stopEarly,
          kind: ButtonKind.quietMuted,
          wide: true,
          onPressed: onStop,
        ),
      ],
    );
  }
}

/// A break running (spec §8.4): under auto-start the note saying why it
/// began on its own; the pet, Drowsy, and its break line; the clock in rest
/// minutes over the muted line; the **Break** chip; and *Skip break*, never
/// confirmed.
class _Break extends ConsumerStatefulWidget {
  const _Break({
    required this.header,
    required this.pet,
    required this.standing,
    required this.cycle,
    required this.task,
    required this.onSkip,
  });

  final Widget header;
  final Widget pet;
  final PetStanding standing;
  final LiveCycle cycle;
  final Task task;
  final VoidCallback? onSkip;

  @override
  ConsumerState<_Break> createState() => _BreakState();
}

class _BreakState extends ConsumerState<_Break> {
  DayTotals? _today;

  @override
  void initState() {
    super.initState();
    unawaited(_readToday());
  }

  Future<void> _readToday() async {
    final today = await ref
        .read(statsReaderProvider)
        .dayOf(ref.read(databaseProvider).clock());
    if (mounted) setState(() => _today = today);
  }

  @override
  Widget build(BuildContext context) {
    final words = AppLocalizations.of(context);
    final colours = TomoTheme.of(context);
    final u = UiPixel.of(context);
    final today = _today;
    final cycle = widget.cycle;
    return ScreenBody(
      content: [
        widget.header,
        if (cycle.autoStart)
          PixelBox(
            fill: colours.sunken,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: u(7), vertical: u(5)),
              child: PixelText(words.autoNote),
            ),
          ),
      ],
      middle: [
        widget.pet,
        if (today != null)
          PixelText(
            petLine(
              words,
              moment: OnBreakMoment(
                breakMinutes: cycle.breakMinutes,
                todayBlocks: today.blocks,
                todayMinutes: today.minutes,
              ),
              species: widget.standing.species,
              personality: widget.standing.personality,
            ),
            textAlign: TextAlign.center,
          ),
        QuietClock(
          start: cycle.breakStartAt!,
          end: cycle.breakEndAt!,
          task: widget.task.title,
          rest: true,
        ),
        Center(
          child: PixelChip(words.chipBreak, tone: ChipTone.muted, big: true),
        ),
      ],
      bottom: [
        PixelButton(
          label: words.skipBreak,
          kind: ButtonKind.secondary,
          wide: true,
          onPressed: widget.onSkip,
        ),
      ],
    );
  }
}

/// The next block in 10 (spec §4.8, ADR-0011): the break ended while Focus
/// was on screen with auto-start on. The pet's break-over line, the
/// countdown line, *Start now* and *Not yet*. At zero the block starts, as
/// *Start now* would.
class _Countdown extends ConsumerStatefulWidget {
  const _Countdown({
    required this.header,
    required this.pet,
    required this.standing,
    required this.cycle,
    required this.from,
    required this.now,
    required this.onStart,
    required this.onNotYet,
  });

  final Widget header;
  final Widget pet;
  final PetStanding standing;
  final LiveCycle cycle;
  final DateTime from;
  final DateTime Function() now;
  final VoidCallback? onStart;
  final VoidCallback? onNotYet;

  @override
  ConsumerState<_Countdown> createState() => _CountdownState();
}

class _CountdownState extends ConsumerState<_Countdown> {
  Timer? _tick;
  DayTotals? _today;
  var _started = false;

  @override
  void initState() {
    super.initState();
    unawaited(_readToday());
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _readToday() async {
    final today = await ref.read(statsReaderProvider).dayOf(widget.now());
    if (mounted) setState(() => _today = today);
  }

  int _secondsLeft(DateTime now) {
    final gone = now.difference(widget.from).inMilliseconds;
    return LiveFocus.countdown - gone ~/ 1000;
  }

  @override
  Widget build(BuildContext context) {
    final words = AppLocalizations.of(context);
    final now = widget.now();
    final left = _secondsLeft(now);
    _tick?.cancel();
    if (left <= 0) {
      if (!_started) {
        _started = true;
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => widget.onStart?.call(),
        );
      }
    } else {
      final next = widget.from.add(
        Duration(seconds: LiveFocus.countdown - left + 1),
      );
      _tick = Timer(next.difference(now), () {
        if (mounted) setState(() {});
      });
    }
    final standing = widget.standing;
    final today = _today;
    String line(PetMoment moment) => petLine(
      words,
      moment: moment,
      species: standing.species,
      personality: standing.personality,
    );
    return ScreenBody(
      content: [widget.header],
      middle: [
        widget.pet,
        if (today != null)
          PixelText(
            line(
              BreakOverMoment(
                breakMinutes: widget.cycle.breakMinutes,
                todayBlocks: today.blocks,
                todayMinutes: today.minutes,
              ),
            ),
            textAlign: TextAlign.center,
          ),
      ],
      bottom: [
        // Read when touched; never a live region (spec §12).
        PixelText(
          line(CountdownMoment(seconds: left.clamp(0, LiveFocus.countdown))),
          step: TypeStep.title,
          textAlign: TextAlign.center,
        ),
        PixelButton(
          label: words.startNow,
          wide: true,
          onPressed: widget.onStart,
        ),
        PixelButton(
          label: words.notYet,
          kind: ButtonKind.secondary,
          wide: true,
          onPressed: widget.onNotYet,
        ),
      ],
    );
  }
}

/// *Stop this block?* (spec §8.6): plain words, then *Keep going* above *Stop
/// early*, 8 UI pixels apart. It gives back true to stop. No pet, no minute
/// count, no haptic.
class _StopSheet extends StatelessWidget {
  const _StopSheet();

  @override
  Widget build(BuildContext context) {
    final words = AppLocalizations.of(context);
    final u = UiPixel.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PixelText(words.stopTitle, step: TypeStep.title),
        SizedBox(height: u(5)),
        PixelText(words.stopBody),
        SizedBox(height: u(5)),
        PixelButton(
          label: words.keepGoing,
          wide: true,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        SizedBox(height: u(8)),
        PixelButton(
          label: words.stopEarly,
          kind: ButtonKind.destructive,
          wide: true,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }
}

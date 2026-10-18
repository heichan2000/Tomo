import 'dart:async';

import 'package:flutter/material.dart' show MaterialLocalizations, TimeOfDay;
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tomo_core/art/pixel_art.dart';
import 'package:tomo_core/focus/block_lengths.dart';
import 'package:tomo_core/focus/choices.dart';
import 'package:tomo_core/focus/focus_cycle_service.dart';
import 'package:tomo_core/focus/live_cycle.dart';
import 'package:tomo_core/focus/projection.dart';
import 'package:tomo_core/pet/beat.dart';
import 'package:tomo_core/pet/pet_look.dart';
import 'package:tomo_core/pet/pet_standing.dart';
import 'package:tomo_core/pet/run_script.dart';
import 'package:tomo_core/result.dart';
import 'package:tomo_core/rewards/rewards.dart';
import 'package:tomo_core/tasks/task.dart';
import 'package:tomo_core/tasks/task_status.dart';
import 'package:tomo_core/voice/pet_moment.dart';

import '../app/providers.dart';
import '../l10n/app_localizations.dart';
import '../pet/pet_label.dart';
import '../pet/pet_view.dart';
import '../pet/reward_view.dart';
import '../pet/run_player.dart';
import '../platform/notifications.dart';
import '../ui/buttons.dart';
import '../ui/exp_bar.dart';
import '../ui/pixel_box.dart';
import '../ui/pixel_icon.dart';
import '../ui/rows.dart';
import '../ui/screen_body.dart';
import '../ui/sharp_text.dart';
import '../ui/sheet.dart';
import '../ui/tomo_theme.dart';
import '../ui/ui_pixel.dart';
import '../voice/pet_voice.dart';
import 'after_block.dart';
import 'clock_view.dart';
import 'focus_screen.dart';
import 'task_picker.dart';

/// Focus while a cycle is live (spec §8.4): a block running, a break, the
/// next block counting down, and once a block or a break has ended, the beat
/// run and the choices (`AfterBlock`).
///
/// It reads the pet and the cycle as Home does, and looks again whenever the
/// cycle can change with the clock alone. Minimise, and Android back while a
/// block or break runs, close it and end nothing (ADR-0003). The screen is
/// not kept awake.
///
/// Only Focus plays a beat run (spec §7.4): the one the live cycle owes, as
/// it opens or as its block ends, and *Task done* when the task is marked
/// done here. [onReady] takes Focus back to Ready on another task, for
/// *Start another task*.
class LiveFocus extends ConsumerStatefulWidget {
  const LiveFocus({super.key, this.onReady});

  final ValueChanged<PickedTask>? onReady;

  /// How long the next block counts down after a break ends on screen
  /// (spec §4.8, ADR-0011).
  static const countdown = 10;

  @override
  ConsumerState<LiveFocus> createState() => _LiveFocusState();
}

class _LiveFocusState extends ConsumerState<LiveFocus>
    with TickerProviderStateMixin {
  late final AppLifecycleListener _lifecycle;
  Timer? _wake;

  /// The state the screen last showed, to see a change as it happens.
  FocusState? _shown;

  /// When the next block began counting down; null when it isn't.
  DateTime? _countdownFrom;

  /// The open *Stop this block?* sheet, if any.
  PixelSheetRoute<bool>? _stopSheet;

  var _busy = false;

  /// The run playing, or played, on this screen; kept until a choice moves
  /// the screen on, so its last frame and its line stay.
  _Played? _played;

  /// The block record whose run this screen has taken on: it is never
  /// started twice, while the database catches up with *seen*.
  int? _runFor;

  /// The block that finished while the user was away, for the *while you
  /// were away* note, which stays until a choice is picked.
  LiveCycle? _away;

  /// The estimate card's fact line, while the card shows.
  String? _estimate;

  /// The last choice failed to write.
  var _failed = false;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _lookAgain);
    final pet = ref.read(petStandingProvider);
    final cycle = pet?.cycle;
    final state = project(cycle, _now()).state;
    // Opened on a block that ended unseen: it finished while away.
    if (cycle != null &&
        state != FocusState.focusRunning &&
        (pet!.owedRun.isNotEmpty || !cycle.isCredited)) {
      _away = cycle;
    }
    // A block that finished while Focus was away is settled as it opens.
    _reconcile();
  }

  @override
  void dispose() {
    _wake?.cancel();
    _lifecycle.dispose();
    _played?.player?.dispose();
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

  /// Minimising walks away from a run still playing: it is seen (§7.4).
  void _minimise() {
    final played = _played;
    if (played != null && played.forBlock && played.player?.ended == null) {
      unawaited(_cycles.markBeatRunSeen());
    }
    Navigator.of(context).pop();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // The beat run (spec §7.4, §7.5, §10.4).

  /// Plays the run the live cycle owes, once its facts are read.
  Future<void> _playOwed(PetStanding pet) async {
    final cycle = pet.cycle!;
    _runFor = cycle.blockRecordId;
    final run = pet.owedRun;
    final (live, stats) = await (
      ref.read(taskServiceProvider).cycleTask(),
      ref.read(statsReaderProvider).read(),
    ).wait;
    if (!mounted || live == null) return;
    final grant = run.whereType<BlockCredited>().first.exp;
    _play(
      run,
      pet: pet,
      expBefore: pet.exp - grant,
      task: live.task,
      totalMinutes: stats.minutesFocused,
      forBlock: true,
    );
  }

  /// Plays [run], earned on [task], from [expBefore] EXP, and speaks it once
  /// as it starts: the facts, then the pet's name and its line.
  void _play(
    List<Beat> run, {
    required PetStanding pet,
    required int expBefore,
    required Task task,
    required int totalMinutes,
    required bool forBlock,
  }) {
    final words = AppLocalizations.of(context);
    final line = petLine(
      words,
      moment: runMoment(
        run,
        expBefore: expBefore,
        taskTitle: task.title,
        taskBlocks: task.actualPomodoros,
        taskMinutes: task.cumulativeFocusMinutes,
        totalMinutes: totalMinutes,
      ),
      species: pet.species,
      personality: pet.personality,
    );
    final player = RunPlayer(
      script: RunScript(
        run,
        species: pet.species,
        expBefore: expBefore,
        theme: TomoTheme.of(context).palette.theme,
        movement: MediaQuery.disableAnimationsOf(context)
            ? Movement.reduced
            : Movement.full,
      ),
      vsync: this,
      haptics: ref.read(hapticPlayerProvider),
      onEnd: (_) => unawaited(_runEnded(forBlock: forBlock)),
    )..addListener(_nextFrame);
    var expAfter = expBefore;
    for (final beat in run) {
      if (beat
          case BlockCredited(exp: final grant) ||
              TaskCompleted(bonusExp: final grant)) {
        expAfter = addExp(expAfter, grant);
      }
    }
    _played?.player?.dispose();
    setState(() {
      _played = _Played(
        player: player,
        line: line,
        forBlock: forBlock,
        expAfter: expAfter,
      );
    });
    player.start();
    final away = _away;
    unawaited(
      SemanticsService.sendAnnouncement(
        View.of(context),
        runAnnouncement(
          words,
          facts: RunFacts.of(run, taskTitle: task.title),
          petName: pet.name ?? words.speciesName(pet.species.name),
          petLine: line,
          opening: forBlock && away != null ? _awayNote(away, pet) : null,
        ),
        Directionality.of(context),
      ),
    );
  }

  /// The run moved on a frame: paint it.
  void _nextFrame() {
    if (mounted) setState(() {});
  }

  /// The run reached its payload, or was skipped: a block's run is seen, and
  /// then, on a finished block, the estimate card may show (spec §4.9).
  Future<void> _runEnded({required bool forBlock}) async {
    if (!forBlock) return;
    final seen = await _cycles.markBeatRunSeen();
    if (seen case Success(
      value: CycleStanding(state: FocusState.focusComplete),
    )) {
      final due = await _cycles.takeEstimatePrompt();
      final estimate =
          (await ref.read(taskServiceProvider).cycleTask())?.task.estimate;
      if (due case Success(value: true) when estimate != null && mounted) {
        final pet = ref.read(petStandingProvider)!;
        setState(() {
          _estimate = petLine(
            AppLocalizations.of(context),
            moment: EstimateMoment(estimate: estimate),
            species: pet.species,
            personality: pet.personality,
          );
        });
      }
    }
  }

  /// The hatch stand-in's *Done*: back to Focus's choices.
  void _hatchNamed() {
    final played = _played;
    if (played == null) return;
    played.player?.dispose();
    setState(() => _played = _Played(line: played.line, forBlock: true));
  }

  /// The run is over and the screen has moved on: let it go.
  void _dropPlayed() {
    _played?.player?.dispose();
    _played = null;
  }

  String _awayNote(LiveCycle away, PetStanding pet) {
    final time = MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.fromDateTime(away.endAt.toLocal()),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
    return petLine(
      AppLocalizations.of(context),
      moment: AwayNoteMoment(time: time, minutes: away.focusMinutes),
      species: pet.species,
      personality: pet.personality,
    );
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

  // Commands and the choices (spec §8.5).

  /// A choice was picked: the note and the card go, and the screen moves on
  /// from the run it showed. Picking any choice counts as *Not yet*.
  void _picked() {
    _away = null;
    _estimate = null;
    _failed = false;
  }

  /// Runs a choice's command; a write that fails shows the error line.
  Future<void> _choose(Future<Result<Object?>> Function() command) =>
      _run(() async {
        final result = await command();
        if (!mounted) return;
        setState(() {
          if (result is Failure) {
            _failed = true;
          } else {
            _picked();
            _dropPlayed();
          }
        });
      });

  Future<void> _skipBreak() => _choose(_cycles.skipBreak);

  Future<void> _leave() async {
    await _cycles.leave();
    if (mounted) Navigator.of(context).pop();
  }

  /// Another block on the cycle's task, at the cycle's own lengths, with
  /// auto-start as it is set now (spec §4.8).
  Future<Result<CycleStanding>> _startNext(LiveCycle cycle) async {
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
    return started;
  }

  void _notYet() => setState(() => _countdownFrom = null);

  /// *Mark task done* (spec §5.4): a task write that leaves the cycle where
  /// it is. With the pet on screen, *Task done* plays, with any level-up and
  /// evolution its bonus reached (C26).
  Future<void> _markDone() => _run(() async {
    final pet = ref.read(petStandingProvider);
    final before = ref.read(cycleTaskProvider)?.task;
    if (pet == null || before == null) return;
    final done = await ref
        .read(taskServiceProvider)
        .updateTask(before.id, const TaskPatch(status: TaskStatus.done));
    if (!mounted) return;
    switch (done) {
      case Failure():
        setState(() => _failed = true);
      case Success(value: final task):
        final stats = await ref.read(statsReaderProvider).read();
        if (!mounted) return;
        _picked();
        final bonus = before.completionBonusGrantedAt == null
            ? completionBonus(
                cumulativeFocusMinutes: before.cumulativeFocusMinutes,
              )
            : 0;
        _play(
          taskCompletedRun(
            expBefore: pet.exp,
            bonusExp: bonus,
            petOnScreen: true,
          ),
          pet: pet,
          expBefore: pet.exp,
          task: task,
          totalMinutes: stats.minutesFocused,
          forBlock: false,
        );
    }
  });

  /// *Start another task*: the picker; a pick ends this cycle and takes
  /// Focus to Ready on that task.
  Future<void> _startAnotherTask() => _run(() async {
    final picked = await pickTask(
      context,
      current: ref.read(cycleTaskProvider)?.task,
    );
    if (picked == null || !mounted) return;
    await _cycles.leave();
    if (!mounted) return;
    final onReady = widget.onReady;
    if (onReady == null) {
      Navigator.of(context).pop();
    } else {
      onReady(picked);
    }
  });

  /// Android back (spec §8.1): minimises while a block or a break runs; on
  /// a finished state it is *Leave*. An open sheet closes first by itself.
  /// While the hatch has the screen, it waits for the naming (C5).
  void _back(FocusState state) {
    if (_played?.player case final player? when player.frame.cleared) {
      if (player.ended != null) _hatchNamed();
      return;
    }
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
      if (pet.owedRun.isNotEmpty &&
          cycle.blockRecordId != _runFor &&
          _played == null) {
        _runFor = cycle.blockRecordId;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) unawaited(_playOwed(pet));
        });
      }
      final played = _played;
      final player = played?.player;
      final playing = player != null && player.ended == null;
      // The block ended and its run is on its way.
      final owed =
          (state != FocusState.focusRunning && !cycle.isCredited) ||
          (pet.owedRun.isNotEmpty && played == null);
      final hatching = player != null && player.frame.cleared;
      final after =
          playing ||
          owed ||
          hatching ||
          state == FocusState.focusComplete ||
          (state == FocusState.breakComplete && !counting);
      if (played != null && !after) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _dropPlayed());
      }

      final header = FocusHeader(
        picked: PickedTask(live.task, live.project),
        leading: PixelIconButton(
          icon: PixelIcon(IconName.down, colour: colours.ink),
          semanticLabel: AppLocalizations.of(context).minimise,
          onPressed: _minimise,
        ),
        notificationsOff: access == NotificationAccess.denied,
      );
      final reduceMotion = MediaQuery.disableAnimationsOf(context);
      final look = pet.lookAt(
        now,
        calmPet: calmPet,
        reduceMotion: reduceMotion,
      );
      final label = petLabel(AppLocalizations.of(context), pet, look);
      final petView = Center(
        child: PetView(look: look, spot: PetSpot.focus, semanticLabel: label),
      );
      final away = _away;
      final notes = [if (away != null) _awayNote(away, pet)];
      body = switch (state) {
        _ when hatching => HatchStandIn(
          frame: player.frame,
          rest: _seen(pet)
              .lookAt(now, calmPet: calmPet, reduceMotion: reduceMotion),
          line: played!.line,
          onDone: _hatchNamed,
        ),
        _ when after => _after(
          pet: pet,
          cycle: cycle,
          live: live,
          state: state,
          header: header,
          notes: notes,
          petView: petView,
          label: label,
          played: played,
          waiting: owed,
          calmPet: calmPet,
          reduceMotion: reduceMotion,
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
          notes: notes,
          pet: petView,
          standing: pet,
          cycle: cycle,
          task: live.task,
          onSkip: _busy ? null : () => unawaited(_skipBreak()),
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
              : () => unawaited(_choose(() => _startNext(cycle))),
          onNotYet: _busy ? null : _notYet,
        ),
        FocusState.focusComplete ||
        FocusState.breakComplete ||
        FocusState.idle => const SizedBox.expand(),
      };
      // Until the hatch's burst, the accent stays the egg's grey.
      if (player != null && !player.frame.hatched) {
        body = TomoTheme(
          colours: TomoColours.of(colours.palette.theme, null),
          child: body,
        );
      }
      if (playing) body = SkipRun(player: player, child: body);
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back(state);
      },
      child: ColoredBox(color: colours.ground, child: body),
    );
  }

  /// [pet] with its owed run had: how it stands once the run is over.
  PetStanding _seen(PetStanding pet) => PetStanding(
    species: pet.species,
    personality: pet.personality,
    name: pet.name,
    exp: pet.exp,
    hatched: pet.hatched,
    cycle: pet.cycle,
  );

  /// The block or break has ended (spec §8.4, §8.5): the run, if one plays,
  /// then the line, the bar and the choices.
  Widget _after({
    required PetStanding pet,
    required LiveCycle cycle,
    required CycleTask live,
    required FocusState state,
    required Widget header,
    required List<String> notes,
    required Widget petView,
    required String label,
    required _Played? played,
    required bool waiting,
    required bool calmPet,
    required bool reduceMotion,
  }) {
    final words = AppLocalizations.of(context);
    final player = played?.player;
    final frame = player?.frame;
    String line(PetMoment moment) => petLine(
      words,
      moment: moment,
      species: pet.species,
      personality: pet.personality,
    );
    final taskDone = live.task.status == TaskStatus.done;
    final estimate = _estimate;
    void Function()? off(void Function() action) => _busy ? null : action;
    String choiceLabel(FocusChoice choice) => switch (choice) {
      FocusChoice.takeBreak => words.choiceBreak(cycle.breakMinutes),
      FocusChoice.anotherBlock => words.choiceAnotherBlock(cycle.focusMinutes),
      FocusChoice.startAnotherBlock => words.startAnotherBlock,
      FocusChoice.markTaskDone => words.markTaskDone,
      FocusChoice.startAnotherTask => words.startAnotherTask,
      FocusChoice.doneForNow => words.doneForNow,
    };
    VoidCallback choiceAction(FocusChoice choice) => switch (choice) {
      FocusChoice.takeBreak => () => unawaited(_choose(_cycles.takeBreak)),
      FocusChoice.anotherBlock || FocusChoice.startAnotherBlock =>
        () => unawaited(_choose(() => _startNext(cycle))),
      FocusChoice.markTaskDone => () => unawaited(_markDone()),
      FocusChoice.startAnotherTask => () => unawaited(_startAnotherTask()),
      FocusChoice.doneForNow => () => unawaited(_run(_leave)),
    };
    final shownLine = played?.line;
    final exp = played?.expAfter ?? pet.exp;
    return AfterBlock(
      header: header,
      notes: notes,
      pet: frame == null
          ? petView
          : Center(
              child: RewardPet(
                frame: frame,
                rest: _seen(
                  pet,
                ).lookAt(_now(), calmPet: calmPet, reduceMotion: reduceMotion),
                spot: PetSpot.focus,
                semanticLabel: label,
              ),
            ),
      line: switch (state) {
        _ when shownLine != null => PixelText(
          shownLine,
          textAlign: TextAlign.center,
        ),
        _ when waiting => null,
        FocusState.breakComplete => TodayLine(
          line: (today) => line(
            BreakOverMoment(
              breakMinutes: cycle.breakMinutes,
              todayBlocks: today.blocks,
              todayMinutes: today.minutes,
            ),
          ),
        ),
        _ => PixelText(
          line(
            BlockDoneMoment(
              minutes: cycle.focusMinutes,
              task: live.task.title,
              taskBlocks: live.task.actualPomodoros,
              taskMinutes: live.task.cumulativeFocusMinutes,
            ),
          ),
          textAlign: TextAlign.center,
        ),
      },
      level: frame?.level ?? levelForExp(exp),
      exp: exp,
      bar:
          frame?.bar ??
          BarShown(lit: exp % expPerLevel * ExpBar.blocks ~/ expPerLevel),
      plate: frame?.plate,
      dither: frame?.dither ?? false,
      card: estimate == null || taskDone
          ? null
          : EstimateCard(
              fact: estimate,
              onNotYet: off(() => setState(() => _estimate = null)),
              onMarkDone: off(() => unawaited(_markDone())),
            ),
      failed: _failed,
      choices: [
        for (final (choice, weight) in choicesAfter(
          state,
          taskDone: taskDone,
          estimateCard: estimate != null,
        ))
          (
            label: choiceLabel(choice),
            weight: weight,
            onPressed: off(choiceAction(choice)),
          ),
      ],
      stepIn: waiting
          ? null
          : frame == null
          ? const StepIn(dy: 0)
          : frame.payload,
    );
  }
}

/// A run this screen played: its player (gone once the hatch is named), the
/// line it showed, whether it was a block's, and the EXP it ended on.
final class _Played {
  _Played({
    this.player,
    required this.line,
    required this.forBlock,
    this.expAfter,
  });

  final RunPlayer? player;
  final String line;
  final bool forBlock;
  final int? expAfter;
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
/// began on its own, and any *while you were away* note; the pet, Drowsy,
/// and its break line; the clock in rest minutes over the muted line; the
/// **Break** chip; and *Skip break*, never confirmed.
class _Break extends StatelessWidget {
  const _Break({
    required this.header,
    required this.notes,
    required this.pet,
    required this.standing,
    required this.cycle,
    required this.task,
    required this.onSkip,
  });

  final Widget header;
  final List<String> notes;
  final Widget pet;
  final PetStanding standing;
  final LiveCycle cycle;
  final Task task;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    final words = AppLocalizations.of(context);
    final colours = TomoTheme.of(context);
    final u = UiPixel.of(context);
    return ScreenBody(
      content: [
        header,
        for (final note in [if (cycle.autoStart) words.autoNote, ...notes])
          PixelBox(
            fill: colours.sunken,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: u(7), vertical: u(5)),
              child: PixelText(note),
            ),
          ),
      ],
      middle: [
        pet,
        TodayLine(
          line: (today) => petLine(
            words,
            moment: OnBreakMoment(
              breakMinutes: cycle.breakMinutes,
              todayBlocks: today.blocks,
              todayMinutes: today.minutes,
            ),
            species: standing.species,
            personality: standing.personality,
          ),
        ),
        QuietClock(
          start: cycle.breakStartAt!,
          end: cycle.breakEndAt!,
          task: task.title,
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
          onPressed: onSkip,
        ),
      ],
    );
  }
}

/// The next block in 10 (spec §4.8, ADR-0011): the break ended while Focus
/// was on screen with auto-start on. The pet's break-over line, the
/// countdown line, *Start now* and *Not yet*. At zero the block starts, as
/// *Start now* would.
class _Countdown extends StatefulWidget {
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
  State<_Countdown> createState() => _CountdownState();
}

class _CountdownState extends State<_Countdown> {
  Timer? _tick;
  var _started = false;

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
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
        TodayLine(
          line: (today) => line(
            BreakOverMoment(
              breakMinutes: widget.cycle.breakMinutes,
              todayBlocks: today.blocks,
              todayMinutes: today.minutes,
            ),
          ),
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

import '../pet/beat.dart';
import '../rewards/rewards.dart';

/// A moment the pet has a line for, with the facts that line is made from
/// (spec §10, [#51](https://github.com/heichan2000/Tomo/issues/51)).
///
/// The words live in the app's copy file; this is only what they are about.
///
/// Some moments have a second line that adds a fact, said only when
/// `factHolds`; otherwise the pet says the moment's usual line. A fact is only
/// ever something that cannot go down: a count that grows, a first, this
/// cycle. Never a streak, a comparison or time away (ADR-0030).
sealed class PetMoment {
  const PetMoment();
}

/// A focus block was just credited.
final class BlockDoneMoment extends PetMoment {
  const BlockDoneMoment({
    required this.minutes,
    required this.task,
    required this.taskBlocks,
    required this.taskMinutes,
  });

  final int minutes;
  final String task;

  /// Finished blocks on this task, this one included.
  final int taskBlocks;

  /// Minutes focused on this task, this block included.
  final int taskMinutes;

  /// The fact line: this task has 2 or more blocks.
  bool get factHolds => taskBlocks >= 2;
}

/// The pet reached a level.
final class LevelUpMoment extends PetMoment {
  const LevelUpMoment({
    required this.level,
    required this.levelBefore,
    required this.totalMinutes,
  });

  final int level;
  final int levelBefore;

  /// Every finished block's minutes, added up.
  final int totalMinutes;

  /// Whole hours focused.
  int get hours => totalMinutes ~/ 60;

  /// The fact line: there is a whole hour to speak of.
  bool get factHolds => hours >= 1;
}

/// The pet changed stage.
final class EvolutionMoment extends PetMoment {
  const EvolutionMoment({required this.stage, required this.totalMinutes});

  final int stage;
  final int totalMinutes;

  int get hours => totalMinutes ~/ 60;

  /// The fact line: always, since by the first evolution there are hours to
  /// speak of.
  bool get factHolds => hours >= 2;
}

/// A task was marked done, with a pet on screen.
final class TaskDoneMoment extends PetMoment {
  const TaskDoneMoment({
    required this.task,
    required this.taskBlocks,
    required this.taskMinutes,
  });

  final String task;
  final int taskBlocks;
  final int taskMinutes;

  /// The fact line: the task has focus time.
  bool get factHolds => taskMinutes > 0;
}

/// A break is running.
final class OnBreakMoment extends PetMoment {
  const OnBreakMoment({
    required this.breakMinutes,
    required this.todayBlocks,
    required this.todayMinutes,
  });

  final int breakMinutes;

  /// Blocks finished today, by the local day they ended.
  final int todayBlocks;
  final int todayMinutes;

  /// The fact line: a block ended today. Almost always, since a break follows
  /// a block, unless that block ended yesterday.
  bool get factHolds => todayBlocks >= 1;
}

/// A break has ended.
final class BreakOverMoment extends PetMoment {
  const BreakOverMoment({
    required this.breakMinutes,
    required this.todayBlocks,
    required this.todayMinutes,
  });

  final int breakMinutes;
  final int todayBlocks;
  final int todayMinutes;

  /// The fact line: a block ended today.
  bool get factHolds => todayBlocks >= 1;
}

/// The egg hatched, at the end of the first finished block.
final class HatchMoment extends PetMoment {
  const HatchMoment({required this.minutes, required this.task});

  /// The first block's length.
  final int minutes;

  /// The first block's task.
  final String task;
}

/// The pet describing itself on onboarding's first screen.
final class SetupMoment extends PetMoment {
  const SetupMoment();
}

/// The egg's line on Home.
final class EggMoment extends PetMoment {
  const EggMoment();
}

/// A block finished while the user was away.
final class AwayNoteMoment extends PetMoment {
  const AwayNoteMoment({required this.time, required this.minutes});

  /// When the block ended, already written the way this phone writes times
  /// ("2:25 PM", or "14:25").
  final String time;
  final int minutes;
}

/// The auto-start countdown.
final class CountdownMoment extends PetMoment {
  const CountdownMoment({required this.seconds});

  final int seconds;
}

/// The estimate card's fact line.
final class EstimateMoment extends PetMoment {
  const EstimateMoment({required this.estimate});

  /// The task's planned blocks.
  final int estimate;
}

/// The moment whose line a beat run shows, and speaks after its facts
/// (spec §7.4, §10.4): its rarest beat's, by the reward ladder (§7.5). Hatch
/// over evolution over task done over level-up over the block. So a block
/// that levels up says the level-up line, and a task bonus that reaches a
/// level keeps the task-done line (§17, C116).
///
/// [expBefore] is the pet's EXP before the run's first beat. The task's
/// numbers are as they stand after the run was earned; [totalMinutes] is
/// every finished block's minutes, added up.
PetMoment runMoment(
  List<Beat> run, {
  required int expBefore,
  required String taskTitle,
  required int taskBlocks,
  required int taskMinutes,
  required int totalMinutes,
}) {
  int rank(Beat beat) => switch (beat) {
    BlockCredited() => 0,
    LevelUp() => 1,
    TaskCompleted() => 2,
    Evolution() => 3,
    Hatch() => 4,
  };
  final shown = run.reduce((a, b) => rank(b) > rank(a) ? b : a);
  return switch (shown) {
    BlockCredited(:final minutes) => BlockDoneMoment(
      minutes: minutes,
      task: taskTitle,
      taskBlocks: taskBlocks,
      taskMinutes: taskMinutes,
    ),
    LevelUp(:final level) => LevelUpMoment(
      level: level,
      levelBefore: levelForExp(expBefore),
      totalMinutes: totalMinutes,
    ),
    TaskCompleted() => TaskDoneMoment(
      task: taskTitle,
      taskBlocks: taskBlocks,
      taskMinutes: taskMinutes,
    ),
    Evolution(:final to) => EvolutionMoment(
      stage: to,
      totalMinutes: totalMinutes,
    ),
    Hatch() => HatchMoment(
      minutes: run.whereType<BlockCredited>().first.minutes,
      task: taskTitle,
    ),
  };
}

import '../rewards/rewards.dart';
import 'species.dart';

/// A momentary celebration (spec §7.4, ADR-0009). Five kinds.
///
/// A **run** is the list of beats one event is owed. It plays in order, one
/// beat at a time, never overlapping.
sealed class Beat {
  const Beat();
}

/// A focus block was credited.
final class BlockCredited extends Beat {
  const BlockCredited({required this.minutes, required this.exp});

  final int minutes;
  final int exp;

  @override
  bool operator ==(Object other) =>
      other is BlockCredited && other.minutes == minutes && other.exp == exp;

  @override
  int get hashCode => Object.hash(minutes, exp);

  @override
  String toString() => 'BlockCredited($minutes min, $exp EXP)';
}

/// The pet reached [level].
final class LevelUp extends Beat {
  const LevelUp({required this.level});

  final int level;

  @override
  bool operator ==(Object other) => other is LevelUp && other.level == level;

  @override
  int get hashCode => level.hashCode;

  @override
  String toString() => 'LevelUp($level)';
}

/// The pet changed evolution stage.
final class Evolution extends Beat {
  const Evolution({required this.from, required this.to});

  final int from;
  final int to;

  @override
  bool operator ==(Object other) =>
      other is Evolution && other.from == from && other.to == to;

  @override
  int get hashCode => Object.hash(from, to);

  @override
  String toString() => 'Evolution($from to $to)';
}

/// A task was marked done, paying [bonusExp].
final class TaskCompleted extends Beat {
  const TaskCompleted({required this.bonusExp});

  final int bonusExp;

  @override
  bool operator ==(Object other) =>
      other is TaskCompleted && other.bonusExp == bonusExp;

  @override
  int get hashCode => bonusExp.hashCode;

  @override
  String toString() => 'TaskCompleted($bonusExp EXP)';
}

/// The egg hatched. Once, ever.
final class Hatch extends Beat {
  const Hatch({required this.species});

  final Species species;

  @override
  bool operator ==(Object other) => other is Hatch && other.species == species;

  @override
  int get hashCode => species.hashCode;

  @override
  String toString() => 'Hatch(${species.name})';
}

/// The run a credited block is owed, rebuilt from the two numbers its block
/// record keeps. Nothing else stores it.
///
/// The hatch is the block whose EXP before was zero. That block's run ends on
/// the hatch: no level-up plays beside it, however long the block was.
List<Beat> beatRunFor({
  required int minutes,
  required int expGranted,
  required int petExpAfter,
  required Species species,
}) {
  final expBefore = petExpAfter - expGranted;
  final credited = BlockCredited(minutes: minutes, exp: expGranted);
  if (expBefore == 0) return [credited, Hatch(species: species)];
  return [credited, ..._growth(expBefore, petExpAfter)];
}

/// The run for marking a task done.
///
/// It plays only where a pet is on screen (Focus). Anywhere else it is
/// dropped: marking done on Work is quiet, and the bonus is still paid.
List<Beat> taskCompletedRun({
  required int expBefore,
  required int bonusExp,
  required bool petOnScreen,
}) {
  if (!petOnScreen) return const [];
  return [
    TaskCompleted(bonusExp: bonusExp),
    ..._growth(expBefore, addExp(expBefore, bonusExp)),
  ];
}

/// The level-up and evolution owed for going from [expBefore] to [expAfter].
/// One level-up, to the level reached, however many were crossed.
List<Beat> _growth(int expBefore, int expAfter) {
  final levelAfter = levelForExp(expAfter);
  final stageBefore = stageForExp(expBefore);
  final stageAfter = stageForExp(expAfter);
  return [
    if (levelAfter > levelForExp(expBefore)) LevelUp(level: levelAfter),
    if (stageAfter > stageBefore) Evolution(from: stageBefore, to: stageAfter),
  ];
}

/// The plain facts a screen reader speaks once, at the start of a run
/// (spec §10.4). The words come from the copy files.
final class RunFacts {
  const RunFacts({
    required this.taskTitle,
    required this.blockMinutes,
    required this.expGained,
    required this.levelReached,
    required this.stageReached,
    required this.hatched,
    required this.taskDone,
  });

  /// The facts in [run], which was earned on the task called [taskTitle].
  factory RunFacts.of(List<Beat> run, {required String taskTitle}) {
    int? blockMinutes;
    var expGained = 0;
    int? levelReached;
    int? stageReached;
    var hatched = false;
    var taskDone = false;
    for (final beat in run) {
      switch (beat) {
        case BlockCredited(:final minutes, :final exp):
          blockMinutes = minutes;
          expGained += exp;
        case TaskCompleted(:final bonusExp):
          taskDone = true;
          expGained += bonusExp;
        case LevelUp(:final level):
          levelReached = level;
        case Evolution(:final to):
          stageReached = to;
        case Hatch():
          hatched = true;
      }
    }
    return RunFacts(
      taskTitle: taskTitle,
      blockMinutes: blockMinutes,
      expGained: expGained,
      levelReached: levelReached,
      stageReached: stageReached,
      hatched: hatched,
      taskDone: taskDone,
    );
  }

  final String taskTitle;

  /// The finished block's length. Null when the run is not for a block.
  final int? blockMinutes;
  final int expGained;

  /// Null when no level was reached.
  final int? levelReached;

  /// Null when the stage did not change.
  final int? stageReached;
  final bool hatched;
  final bool taskDone;
}

import '../pet/species.dart';

/// A moment the pet has a line for, with the facts that line is made from
/// (spec §10, [#51](https://github.com/heichan2000/Tomo/issues/51)).
///
/// The words live in the app's copy file; this is only what they are about.
sealed class PetMoment {
  const PetMoment();

  /// Whether the Chatty entry's one extra detail is true right now. When it
  /// is not, or there is no Chatty entry, the pet says its Quiet line.
  ///
  /// Chatty adds only things that cannot go down: counts that grow, firsts,
  /// this cycle. Never a streak, a comparison or time away.
  bool chattyDetailHolds(Species species);
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

  /// "When this task has 2 or more blocks."
  @override
  bool chattyDetailHolds(Species species) => taskBlocks >= 2;
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

  /// "Always", as long as there is a whole hour to speak of.
  @override
  bool chattyDetailHolds(Species species) => hours >= 1;
}

/// The pet changed stage.
final class EvolutionMoment extends PetMoment {
  const EvolutionMoment({required this.stage, required this.totalMinutes});

  final int stage;
  final int totalMinutes;

  int get hours => totalMinutes ~/ 60;

  /// "Always": by the first evolution there are hours to speak of.
  @override
  bool chattyDetailHolds(Species species) => hours >= 2;
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

  /// "When the task has focus time." Lily's detail is "all N blocks of it",
  /// which needs more than one block to be said.
  @override
  bool chattyDetailHolds(Species species) =>
      taskMinutes > 0 && (species != Species.lily || taskBlocks >= 2);
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

  /// "Always (a break follows a block)", unless that block ended yesterday.
  @override
  bool chattyDetailHolds(Species species) => todayBlocks >= 1;
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

  @override
  bool chattyDetailHolds(Species species) => todayBlocks >= 1;
}

/// The egg hatched, at the end of the first finished block.
final class HatchMoment extends PetMoment {
  const HatchMoment({required this.minutes, required this.task});

  /// The first block's length.
  final int minutes;

  /// The first block's task.
  final String task;

  /// "Always (the first block's task)."
  @override
  bool chattyDetailHolds(Species species) => true;
}

/// The pet describing itself on onboarding's first screen.
final class SetupMoment extends PetMoment {
  const SetupMoment();

  /// "When Chatty is selected."
  @override
  bool chattyDetailHolds(Species species) => true;
}

/// The egg's line on Home. Quiet only.
final class EggMoment extends PetMoment {
  const EggMoment();

  @override
  bool chattyDetailHolds(Species species) => false;
}

/// A block finished while the user was away. Quiet only.
final class AwayNoteMoment extends PetMoment {
  const AwayNoteMoment({required this.time, required this.minutes});

  /// When the block ended, already written the way this phone writes times
  /// ("2:25 PM", or "14:25").
  final String time;
  final int minutes;

  @override
  bool chattyDetailHolds(Species species) => false;
}

/// The auto-start countdown. Quiet only.
final class CountdownMoment extends PetMoment {
  const CountdownMoment({required this.seconds});

  final int seconds;

  @override
  bool chattyDetailHolds(Species species) => false;
}

/// The estimate card's fact line. Quiet only.
final class EstimateMoment extends PetMoment {
  const EstimateMoment({required this.estimate});

  /// The task's planned blocks.
  final int estimate;

  @override
  bool chattyDetailHolds(Species species) => false;
}

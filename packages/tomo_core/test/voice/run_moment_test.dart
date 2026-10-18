import 'package:test/test.dart';
import 'package:tomo_core/pet/beat.dart';
import 'package:tomo_core/pet/species.dart';
import 'package:tomo_core/voice/pet_moment.dart';

/// Which line a beat run shows and speaks (spec §7.4, §10.4): the line of
/// its rarest beat, by the reward ladder (§7.5).
void main() {
  PetMoment moment(List<Beat> run, {int expBefore = 700}) => runMoment(
    run,
    expBefore: expBefore,
    taskTitle: 'Write the intro',
    taskBlocks: 3,
    taskMinutes: 75,
    totalMinutes: 610,
  );

  const block = BlockCredited(minutes: 25, exp: 250);

  test('a block alone shows the block-done line, with the task so far', () {
    expect(
      moment([block]),
      isA<BlockDoneMoment>()
          .having((m) => m.minutes, 'minutes', 25)
          .having((m) => m.task, 'task', 'Write the intro')
          .having((m) => m.taskBlocks, 'taskBlocks', 3)
          .having((m) => m.taskMinutes, 'taskMinutes', 75),
    );
  });

  test('a level-up outranks the block, and says the level it came from', () {
    expect(
      moment([block, const LevelUp(level: 3)], expBefore: 1100),
      isA<LevelUpMoment>()
          .having((m) => m.level, 'level', 3)
          .having((m) => m.levelBefore, 'levelBefore', 2)
          .having((m) => m.totalMinutes, 'totalMinutes', 610),
    );
  });

  test('an evolution outranks the level-up', () {
    expect(
      moment([
        block,
        const LevelUp(level: 10),
        const Evolution(from: 1, to: 2),
      ], expBefore: 5300),
      isA<EvolutionMoment>()
          .having((m) => m.stage, 'stage', 2)
          .having((m) => m.totalMinutes, 'totalMinutes', 610),
    );
  });

  test('a task done shows the task-done line', () {
    expect(
      moment([const TaskCompleted(bonusExp: 75)]),
      isA<TaskDoneMoment>()
          .having((m) => m.task, 'task', 'Write the intro')
          .having((m) => m.taskBlocks, 'taskBlocks', 3)
          .having((m) => m.taskMinutes, 'taskMinutes', 75),
    );
  });

  test('task done outranks the level-up its bonus reached (C26)', () {
    expect(
      moment([
        const TaskCompleted(bonusExp: 75),
        const LevelUp(level: 3),
      ], expBefore: 1150),
      isA<TaskDoneMoment>(),
    );
  });

  test('the evolution outranks task done', () {
    expect(
      moment([
        const TaskCompleted(bonusExp: 75),
        const LevelUp(level: 10),
        const Evolution(from: 1, to: 2),
      ], expBefore: 5350),
      isA<EvolutionMoment>(),
    );
  });

  test('the first block ends on the hatch line, with its minutes', () {
    expect(
      moment([
        const BlockCredited(minutes: 15, exp: 150),
        const Hatch(species: Species.joe),
      ], expBefore: 0),
      isA<HatchMoment>()
          .having((m) => m.minutes, 'minutes', 15)
          .having((m) => m.task, 'task', 'Write the intro'),
    );
  });
}

import 'package:test/test.dart';
import 'package:tomo_core/pet/beat.dart';
import 'package:tomo_core/pet/species.dart';

/// Which celebrations a credited block is owed (spec §7.4), rebuilt from the
/// two numbers its block record keeps. Promises 16 (Core) and 20.
void main() {
  List<Beat> run({
    required int minutes,
    required int expBefore,
    Species species = Species.geode,
  }) => beatRunFor(
    minutes: minutes,
    expGranted: minutes * 10,
    petExpAfter: expBefore + minutes * 10,
    species: species,
  );

  test('an ordinary block is one beat: the block credited', () {
    // 700 EXP is level 2, and so is 950.
    expect(run(minutes: 25, expBefore: 700), [
      const BlockCredited(minutes: 25, exp: 250),
    ]);
  });

  test('a block that crosses a level adds the level-up, after it', () {
    // Level 2 runs from 600 to 1199 EXP: 1100 plus 250 reaches level 3.
    expect(run(minutes: 25, expBefore: 700), hasLength(1));
    expect(run(minutes: 25, expBefore: 1100), [
      const BlockCredited(minutes: 25, exp: 250),
      const LevelUp(level: 3),
    ]);
  });

  test('a long block that crosses two levels has one level-up, to the '
      'level reached', () {
    // 600 EXP is level 2; 120 minutes later, 1800 is level 4.
    expect(run(minutes: 120, expBefore: 600), [
      const BlockCredited(minutes: 120, exp: 1200),
      const LevelUp(level: 4),
    ]);
  });

  test('the block that reaches level 10 fires three beats, in order', () {
    // Level 9 ends at 5400 EXP; stage 2 begins at level 10.
    expect(run(minutes: 25, expBefore: 5300), [
      const BlockCredited(minutes: 25, exp: 250),
      const LevelUp(level: 10),
      const Evolution(from: 1, to: 2),
    ]);
  });

  test('the later evolutions are at levels 40 and 100', () {
    expect(
      run(minutes: 10, expBefore: 39 * 600 - 50).last,
      const Evolution(from: 2, to: 3),
    );
    expect(
      run(minutes: 10, expBefore: 99 * 600 - 50).last,
      const Evolution(from: 3, to: 4),
    );
  });

  test('a level-up inside a stage is not an evolution', () {
    expect(run(minutes: 25, expBefore: 20 * 600 - 100), [
      const BlockCredited(minutes: 25, exp: 250),
      const LevelUp(level: 21),
    ]);
  });

  group('the hatch', () {
    test('is the block whose EXP before was zero', () {
      expect(run(minutes: 15, expBefore: 0, species: Species.joe), [
        const BlockCredited(minutes: 15, exp: 150),
        const Hatch(species: Species.joe),
      ]);
    });

    test('happens once: the second block is an ordinary one', () {
      expect(run(minutes: 15, expBefore: 150), [
        const BlockCredited(minutes: 15, exp: 150),
      ]);
    });

    test('a long first block still ends on the hatch, with no level-up '
        'beside it', () {
      expect(run(minutes: 120, expBefore: 0, species: Species.lily), [
        const BlockCredited(minutes: 120, exp: 1200),
        const Hatch(species: Species.lily),
      ]);
    });
  });

  group('finishing a task', () {
    test('with a pet on screen, the task-done beat plays', () {
      expect(
        taskCompletedRun(expBefore: 1000, bonusExp: 75, petOnScreen: true),
        [const TaskCompleted(bonusExp: 75)],
      );
    });

    test('with no pet on screen it is dropped: marking done on Work is '
        'quiet', () {
      expect(
        taskCompletedRun(expBefore: 1000, bonusExp: 75, petOnScreen: false),
        isEmpty,
      );
    });

    test('a bonus that crosses a level adds the level-up', () {
      expect(
        taskCompletedRun(expBefore: 1150, bonusExp: 75, petOnScreen: true),
        [const TaskCompleted(bonusExp: 75), const LevelUp(level: 3)],
      );
    });

    test('a bonus that crosses a stage adds the evolution too', () {
      expect(
        taskCompletedRun(expBefore: 5390, bonusExp: 25, petOnScreen: true),
        [
          const TaskCompleted(bonusExp: 25),
          const LevelUp(level: 10),
          const Evolution(from: 1, to: 2),
        ],
      );
    });

    test('a task with no focus still plays its beat, with nothing gained', () {
      expect(
        taskCompletedRun(expBefore: 1000, bonusExp: 0, petOnScreen: true),
        [const TaskCompleted(bonusExp: 0)],
      );
    });
  });

  group('what a screen reader is told at the start of a run', () {
    test('an ordinary block: the minutes, the task, the EXP', () {
      final facts = RunFacts.of(
        run(minutes: 25, expBefore: 700),
        taskTitle: 'Write the intro',
      );

      expect(facts.blockMinutes, 25);
      expect(facts.taskTitle, 'Write the intro');
      expect(facts.expGained, 250);
      expect(facts.levelReached, isNull);
      expect(facts.stageReached, isNull);
      expect(facts.hatched, isFalse);
      expect(facts.taskDone, isFalse);
    });

    test('a level-up and an evolution are in the same one line', () {
      final facts = RunFacts.of(
        run(minutes: 25, expBefore: 5300),
        taskTitle: 'Write the intro',
      );

      expect(facts.expGained, 250);
      expect(facts.levelReached, 10);
      expect(facts.stageReached, 2);
    });

    test('the hatch', () {
      final facts = RunFacts.of(
        run(minutes: 15, expBefore: 0),
        taskTitle: 'Write the intro',
      );

      expect(facts.hatched, isTrue);
      expect(facts.expGained, 150);
    });

    test('a finished task: the bonus, and no block', () {
      final facts = RunFacts.of(
        taskCompletedRun(expBefore: 1150, bonusExp: 75, petOnScreen: true),
        taskTitle: 'Write the intro',
      );

      expect(facts.taskDone, isTrue);
      expect(facts.blockMinutes, isNull);
      expect(facts.expGained, 75);
      expect(facts.levelReached, 3);
    });
  });
}

import 'package:test/test.dart';
import 'package:tomo_core/rewards/rewards.dart';

/// The reward numbers (spec §3). Promises 1 (the amount) and 3.
void main() {
  group('a finished block', () {
    test('earns 10 EXP per focus minute', () {
      expect(expForBlock(minutes: 25), 250);
      expect(expForBlock(minutes: 50), 500);
      expect(expForBlock(minutes: 10), 100);
      expect(expForBlock(minutes: 120), 1200);
    });

    test('earns the same for the same minutes, however they are split', () {
      expect(
        expForBlock(minutes: 25) + expForBlock(minutes: 25),
        expForBlock(minutes: 50),
      );
    });
  });

  group('level is hours focused', () {
    test('a new pet is level 1', () {
      expect(levelForExp(0), 1);
    });

    test('each 600 EXP, one hour of focus, is one level', () {
      expect(levelForExp(599), 1);
      expect(levelForExp(600), 2);
      expect(levelForExp(1199), 2);
      expect(levelForExp(1200), 3);
    });

    test('the curve is flat forever', () {
      // 99 hours of focus is level 100; so is 99 hours and 59 minutes.
      expect(levelForExp(99 * 600), 100);
      expect(levelForExp(99 * 600 + 590), 100);
      expect(levelForExp(1000 * 600), 1001);
    });
  });

  group('the four stages begin at levels 1, 10, 40 and 100', () {
    test('by level', () {
      expect(stageForLevel(1), 1);
      expect(stageForLevel(9), 1);
      expect(stageForLevel(10), 2);
      expect(stageForLevel(39), 2);
      expect(stageForLevel(40), 3);
      expect(stageForLevel(99), 3);
      expect(stageForLevel(100), 4);
      expect(stageForLevel(5000), 4);
    });

    test('by EXP', () {
      expect(stageForExp(0), 1);
      expect(stageForExp(9 * 600 - 10), 1);
      expect(stageForExp(9 * 600), 2);
      expect(stageForExp(39 * 600), 3);
      expect(stageForExp(99 * 600), 4);
    });
  });

  group('the completion bonus', () {
    test('is 10% of what the task earned: one EXP per focus minute', () {
      // Three 25-minute blocks earned 750 EXP; the bonus is 75.
      expect(completionBonus(cumulativeFocusMinutes: 75), 75);
    });

    test('is nothing for a task never focused on', () {
      expect(completionBonus(cumulativeFocusMinutes: 0), 0);
    });
  });

  group('EXP stays inside a 32-bit signed integer', () {
    test('a grant adds to the total', () {
      expect(addExp(1000, 250), 1250);
    });

    test('the total stops at the largest 32-bit value', () {
      expect(addExp(2147483647, 250), 2147483647);
      expect(addExp(2147483600, 250), 2147483647);
      expect(addExp(2147483397, 250), 2147483647);
      expect(addExp(2147483396, 250), 2147483646);
    });
  });
}

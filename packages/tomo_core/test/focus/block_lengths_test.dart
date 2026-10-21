import 'package:test/test.dart';
import 'package:tomo_core/focus/block_lengths.dart';

/// Block and break length (spec §4.7). Promises 2 and 40.
void main() {
  group('a focus block is 10 to 120 minutes', () {
    test('the limits themselves are allowed', () {
      expect(isValidFocusMinutes(10), isTrue);
      expect(isValidFocusMinutes(120), isTrue);
      expect(isValidFocusMinutes(25), isTrue);
    });

    test('nothing shorter than 10 minutes', () {
      expect(isValidFocusMinutes(9), isFalse);
      expect(isValidFocusMinutes(0), isFalse);
      expect(isValidFocusMinutes(-25), isFalse);
    });

    test('nothing longer than 120 minutes', () {
      expect(isValidFocusMinutes(121), isFalse);
    });
  });

  group('a break is 1 to 30 minutes', () {
    test('the limits', () {
      expect(isValidBreakMinutes(1), isTrue);
      expect(isValidBreakMinutes(30), isTrue);
      expect(isValidBreakMinutes(0), isFalse);
      expect(isValidBreakMinutes(31), isFalse);
    });
  });

  group('the presets carry their break', () {
    test('25 minutes comes with a 5-minute break', () {
      expect(BlockLengths.preset25.focusMinutes, 25);
      expect(BlockLengths.preset25.breakMinutes, 5);
    });

    test('50 minutes comes with a 10-minute break', () {
      expect(BlockLengths.preset50.focusMinutes, 50);
      expect(BlockLengths.preset50.breakMinutes, 10);
    });

    test('the first block ever is the 25-minute preset', () {
      expect(BlockLengths.firstEver.focusMinutes, 25);
      expect(BlockLengths.firstEver.breakMinutes, 5);
    });
  });

  group('how a pair shows on Ready', () {
    test('a pair equal to a preset shows as that preset', () {
      expect(
        const BlockLengths(focusMinutes: 25, breakMinutes: 5).choice,
        LengthChoice.preset25,
      );
      expect(
        const BlockLengths(focusMinutes: 50, breakMinutes: 10).choice,
        LengthChoice.preset50,
      );
    });

    test('any other pair shows as Custom', () {
      expect(BlockLengths.firstEver.choice, LengthChoice.preset25);
      expect(
        const BlockLengths(focusMinutes: 25, breakMinutes: 10).choice,
        LengthChoice.custom,
      );
      expect(
        const BlockLengths(focusMinutes: 50, breakMinutes: 5).choice,
        LengthChoice.custom,
      );
    });

    test('pairs with the same lengths are equal', () {
      expect(
        const BlockLengths(focusMinutes: 25, breakMinutes: 5),
        BlockLengths.preset25,
      );
      expect(BlockLengths.preset25, isNot(BlockLengths.preset50));
    });
  });

  group('the Custom steppers', () {
    test('Focus moves in steps of 5', () {
      expect(focusMinutesAfterStep(25, up: true), 30);
      expect(focusMinutesAfterStep(25, up: false), 20);
    });

    test('Focus stops at 10 and at 120', () {
      expect(focusMinutesAfterStep(10, up: false), 10);
      expect(focusMinutesAfterStep(120, up: true), 120);
      expect(focusMinutesAfterStep(115, up: true), 120);
      expect(focusMinutesAfterStep(15, up: false), 10);
    });

    test('a Focus value off the fives lands on the next five', () {
      expect(focusMinutesAfterStep(17, up: true), 20);
      expect(focusMinutesAfterStep(17, up: false), 15);
    });

    test('Break moves in steps of 1', () {
      expect(breakMinutesAfterStep(5, up: true), 6);
      expect(breakMinutesAfterStep(5, up: false), 4);
    });

    test('Break stops at 1 and at 30', () {
      expect(breakMinutesAfterStep(1, up: false), 1);
      expect(breakMinutesAfterStep(30, up: true), 30);
    });
  });
}

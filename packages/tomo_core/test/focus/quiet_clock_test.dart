import 'package:test/test.dart';
import 'package:tomo_core/focus/quiet_clock.dart';

/// The quiet clock (spec §8.4, ADR-0010): rough minutes while a block or a
/// break runs, the exact time only when asked. Promise 33.
void main() {
  Duration left(int minutes, [int seconds = 0]) =>
      Duration(minutes: minutes, seconds: seconds);

  group('rough minutes', () {
    test('rounds to the nearest minute: 18:42 is about 19', () {
      expect(roughMinutes(left(18, 42)), 19);
      expect(roughMinutes(left(25)), 25);
      expect(roughMinutes(left(4, 31)), 5);
    });

    test('on a half minute, already the lower number', () {
      // So a timer set for the change wakes to the new reading.
      expect(roughMinutes(left(4, 30)), 4);
    });

    test('more than a minute is never under a minute', () {
      expect(roughMinutes(left(1, 1)), 1);
      expect(roughMinutes(left(1, 30)), 1);
    });

    test('a minute or less has no number', () {
      expect(roughMinutes(left(1)), isNull);
      expect(roughMinutes(left(0, 59)), isNull);
      expect(roughMinutes(left(0, 1)), isNull);
      expect(roughMinutes(Duration.zero), isNull);
    });
  });

  group('when the rough minutes next change', () {
    final end = DateTime.utc(2026, 10, 18, 9, 25);

    test('at the next half minute, while minutes are left', () {
      // 18:42 left reads 19 until 18:30 left.
      final now = end.subtract(left(18, 42));
      expect(nextRoughChange(now: now, end: end), end.subtract(left(18, 30)));
    });

    test('exactly on a change, the one after', () {
      final now = end.subtract(left(18, 30));
      expect(nextRoughChange(now: now, end: end), end.subtract(left(17, 30)));
    });

    test('from about one minute, at a minute left', () {
      final now = end.subtract(left(1, 20));
      expect(nextRoughChange(now: now, end: end), end.subtract(left(1)));
    });

    test('under a minute, not before the end', () {
      expect(nextRoughChange(now: end.subtract(left(0, 40)), end: end), isNull);
      expect(nextRoughChange(now: end, end: end), isNull);
    });
  });

  group('the exact time', () {
    test('minutes and seconds, the seconds rounded up', () {
      expect(exactTimeLeft(left(18, 42)), '18:42');
      expect(
        exactTimeLeft(left(18, 41) + const Duration(milliseconds: 300)),
        '18:42',
      );
      expect(exactTimeLeft(left(4, 5)), '04:05');
      expect(exactTimeLeft(left(120)), '120:00');
      expect(exactTimeLeft(Duration.zero), '00:00');
    });
  });

  group('how far along', () {
    final start = DateTime.utc(2026, 10, 18, 9);
    final end = DateTime.utc(2026, 10, 18, 9, 20);

    test('the share of the time gone, from nothing to all', () {
      expect(progressBetween(start: start, end: end, now: start), 0);
      expect(
        progressBetween(
          start: start,
          end: end,
          now: start.add(const Duration(minutes: 5)),
        ),
        0.25,
      );
      expect(progressBetween(start: start, end: end, now: end), 1);
    });

    test('never outside nothing and all', () {
      expect(
        progressBetween(
          start: start,
          end: end,
          now: start.subtract(const Duration(minutes: 1)),
        ),
        0,
      );
      expect(
        progressBetween(
          start: start,
          end: end,
          now: end.add(const Duration(minutes: 1)),
        ),
        1,
      );
    });
  });
}

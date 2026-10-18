/// The quiet clock (spec §8.4, ADR-0010): while a block or a break runs, Tomo
/// shows rough minutes, never a ticking number. The exact time is shown only
/// when asked for.
library;

const _minute = Duration(minutes: 1);
const _halfMinute = Duration(seconds: 30);

/// [left] in rough minutes, rounded to the nearest: 18:42 is about 19. A
/// half minute already reads the lower number, so the reading changes at
/// the mark itself. Null for a minute or less, which reads "under a minute
/// left".
int? roughMinutes(Duration left) {
  if (left <= _minute) return null;
  return ((left - _halfMinute).inMicroseconds / _minute.inMicroseconds).ceil();
}

/// The next instant after [now] at which [roughMinutes] of the time left
/// before [end] reads differently, or null if it never will again: once
/// under a minute, it stays there.
///
/// Rough minutes change at each half minute, and at one minute left.
DateTime? nextRoughChange({required DateTime now, required DateTime end}) {
  final left = end.difference(now);
  if (left <= _minute) return null;
  if (left <= _minute + _halfMinute) return end.subtract(_minute);
  // The latest half-minute mark before the time left runs down past it.
  final halves = (left - _halfMinute).inMicroseconds ~/ _minute.inMicroseconds;
  final mark = _halfMinute + _minute * halves;
  return end.subtract(mark == left ? mark - _minute : mark);
}

/// [left] as `mm:ss`, the seconds rounded up, so a block reads `25:00` as it
/// starts and never `00:00` before it ends. Minutes past 99 take three
/// digits.
String exactTimeLeft(Duration left) {
  final seconds = (left.inMicroseconds / Duration.microsecondsPerSecond)
      .ceil()
      .clamp(0, 1 << 31);
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(seconds ~/ 60)}:${two(seconds % 60)}';
}

/// How much of the time from [start] to [end] has gone by at [now], from 0
/// to 1: the progress line under the clock.
double progressBetween({
  required DateTime start,
  required DateTime end,
  required DateTime now,
}) {
  final whole = end.difference(start).inMicroseconds;
  if (whole <= 0) return 1;
  return (now.difference(start).inMicroseconds / whole).clamp(0, 1).toDouble();
}

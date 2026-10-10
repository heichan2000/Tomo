import '../clock.dart';

/// A clock a test sets and moves by hand.
final class TestClock {
  TestClock(DateTime start) : now = start.toUtc();

  /// The time this clock tells. Assign to it, or use [advance].
  DateTime now;

  /// Pass this wherever a [Clock] is wanted.
  Clock get call =>
      () => now;

  void advance(Duration by) => now = now.add(by);
}

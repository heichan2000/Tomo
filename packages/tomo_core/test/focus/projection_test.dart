import 'package:test/test.dart';
import 'package:tomo_core/focus/live_cycle.dart';
import 'package:tomo_core/focus/projection.dart';

/// `project(cycle, now) -> (state, effects)` (spec §4.1, §4.2), row by row,
/// and then the reconciliation rules of §4.4 as scenarios over it.
void main() {
  // A 25-minute block starting at 09:00 UTC, with a 5-minute break.
  final start = DateTime.utc(2026, 10, 10, 9);
  final end = DateTime.utc(2026, 10, 10, 9, 25);

  LiveCycle cycle({
    bool autoStart = false,
    DateTime? breakStartAt,
    DateTime? breakSkippedAt,
    int? blockRecordId,
  }) => LiveCycle(
    taskId: 1,
    startAt: start,
    endAt: end,
    focusMinutes: 25,
    breakMinutes: 5,
    autoStart: autoStart,
    breakStartAt: breakStartAt,
    breakSkippedAt: breakSkippedAt,
    blockRecordId: blockRecordId,
  );

  DateTime at(int hour, int minute, [int second = 0]) =>
      DateTime.utc(2026, 10, 10, hour, minute, second);

  group('the projection table', () {
    test('no cycle is idle', () {
      final projection = project(null, at(9, 10));

      expect(projection.state, FocusState.idle);
      expect(projection.effects, isEmpty);
    });

    test('before the start, the cycle is discarded with the clock notice', () {
      final projection = project(cycle(), at(8, 59, 59));

      expect(projection.state, FocusState.idle);
      expect(projection.effects, {FocusEffect.clockNotice});
    });

    test('from the start until the end, the block is running', () {
      for (final now in [start, at(9, 10), at(9, 24, 59)]) {
        final projection = project(cycle(), now);

        expect(projection.state, FocusState.focusRunning, reason: '$now');
        expect(projection.effects, isEmpty, reason: '$now');
      }
    });

    test(
      'at the end with no break started, the block is complete and owed',
      () {
        for (final now in [end, at(9, 40), DateTime.utc(2026, 10, 14)]) {
          final projection = project(cycle(), now);

          expect(projection.state, FocusState.focusComplete, reason: '$now');
          expect(projection.effects, {FocusEffect.settle}, reason: '$now');
        }
      },
    );

    test('a credited block is complete and owes nothing', () {
      final projection = project(cycle(blockRecordId: 7), at(9, 30));

      expect(projection.state, FocusState.focusComplete);
      expect(projection.effects, isEmpty);
    });

    test('a break that has started and not run out is running', () {
      final onBreak = cycle(blockRecordId: 7, breakStartAt: at(9, 26));

      for (final now in [at(9, 26), at(9, 28), at(9, 30, 59)]) {
        final projection = project(onBreak, now);

        expect(projection.state, FocusState.breakRunning, reason: '$now');
        expect(projection.effects, isEmpty, reason: '$now');
      }
    });

    test('a break that has run its minutes is complete', () {
      final onBreak = cycle(blockRecordId: 7, breakStartAt: at(9, 26));

      for (final now in [at(9, 31), at(13, 0)]) {
        final projection = project(onBreak, now);

        expect(projection.state, FocusState.breakComplete, reason: '$now');
        expect(projection.effects, isEmpty, reason: '$now');
      }
    });

    test('a skipped break is complete at once', () {
      final skipped = cycle(
        blockRecordId: 7,
        breakStartAt: at(9, 26),
        breakSkippedAt: at(9, 27),
      );

      final projection = project(skipped, at(9, 27));

      expect(projection.state, FocusState.breakComplete);
      expect(projection.effects, isEmpty);
    });

    test('a break state still owes the settle if the block is uncredited', () {
      final running = project(cycle(breakStartAt: at(9, 26)), at(9, 28));
      final complete = project(cycle(breakStartAt: at(9, 26)), at(9, 40));

      expect(running.state, FocusState.breakRunning);
      expect(running.effects, {FocusEffect.settle});
      expect(complete.state, FocusState.breakComplete);
      expect(complete.effects, {FocusEffect.settle});
    });
  });

  group('the settle, as it changes the cycle', () {
    test('marks the block credited', () {
      final settled = cycle().afterSettle(blockRecordId: 7);

      expect(settled.blockRecordId, 7);
      expect(settled.breakStartAt, isNull);
    });

    test('with auto-start on, also starts the break at the block end', () {
      final settled = cycle(autoStart: true).afterSettle(blockRecordId: 7);

      expect(settled.blockRecordId, 7);
      expect(settled.breakStartAt, end);
    });

    test('never moves a break the user already started', () {
      final settled = cycle(
        autoStart: true,
        breakStartAt: at(9, 26),
      ).afterSettle(blockRecordId: 7);

      expect(settled.breakStartAt, at(9, 26));
    });
  });

  group('reconciliation', () {
    /// What opening the app does: project, settle if owed, project again.
    /// Returns where the cycle lands and how many blocks were credited.
    ({FocusState state, int credited}) reopen(LiveCycle before, DateTime now) {
      var live = before;
      var credited = 0;
      var projection = project(live, now);
      // A second settle would be a second credit; ten rounds would show it.
      for (var round = 0; round < 10; round++) {
        if (!projection.effects.contains(FocusEffect.settle)) break;
        live = live.afterSettle(blockRecordId: 100 + credited);
        credited++;
        projection = project(live, now);
      }
      return (state: projection.state, credited: credited);
    }

    test('killed mid-block and reopened days later: one block credits', () {
      final landed = reopen(cycle(), DateTime.utc(2026, 10, 13, 18));

      expect(landed.credited, 1);
      expect(landed.state, FocusState.focusComplete);
    });

    test('gone four hours with auto-start on: one block, its break counted as '
        'taken, and no second block', () {
      final landed = reopen(cycle(autoStart: true), at(13, 25));

      expect(landed.credited, 1);
      expect(landed.state, FocusState.breakComplete);
    });

    test('back during the auto-started break: the break is running', () {
      final landed = reopen(cycle(autoStart: true), at(9, 27));

      expect(landed.credited, 1);
      expect(landed.state, FocusState.breakRunning);
    });

    test('auto-start changes what happens next, never what is earned', () {
      for (final now in [end, at(9, 27), at(13, 25), DateTime.utc(2027)]) {
        expect(
          reopen(cycle(autoStart: true), now).credited,
          reopen(cycle(), now).credited,
          reason: '$now',
        );
      }
    });

    test('powered off across the end: it credits on the next start', () {
      final landed = reopen(cycle(), at(9, 25, 1));

      expect(landed.credited, 1);
    });

    test('reopened before the end: nothing is credited yet', () {
      final landed = reopen(cycle(), at(9, 24, 59));

      expect(landed.credited, 0);
      expect(landed.state, FocusState.focusRunning);
    });

    test('a timezone or daylight-saving change mid-block changes nothing', () {
      // The same instant, read on a phone that moved to another zone: the
      // anchors are absolute, so only the instant matters.
      final sameInstantElsewhere = DateTime.fromMillisecondsSinceEpoch(
        at(9, 10).millisecondsSinceEpoch,
      );

      expect(
        project(cycle(), sameInstantElsewhere).state,
        FocusState.focusRunning,
      );
      expect(project(cycle(), end.toLocal()).state, FocusState.focusComplete);
    });

    test('the clock moved backward past the start: discarded at zero', () {
      final landed = reopen(cycle(), at(8, 30));

      expect(landed.credited, 0);
      expect(landed.state, FocusState.idle);
      expect(project(cycle(), at(8, 30)).effects, {FocusEffect.clockNotice});
    });

    test('a small clock correction that stays past the start is absorbed', () {
      final projection = project(cycle(), at(9, 0, 1));

      expect(projection.state, FocusState.focusRunning);
      expect(projection.effects, isEmpty);
    });

    test('a forward jump is believed', () {
      final landed = reopen(cycle(), DateTime.utc(2030));

      expect(landed.credited, 1);
    });

    test('an already credited block is never credited again', () {
      for (final now in [at(9, 26), at(13, 0), DateTime.utc(2027)]) {
        expect(reopen(cycle(blockRecordId: 7), now).credited, 0);
        expect(
          reopen(
            cycle(blockRecordId: 7, breakStartAt: at(9, 26)),
            now,
          ).credited,
          0,
        );
      }
    });
  });
}

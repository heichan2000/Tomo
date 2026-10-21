import 'package:test/test.dart';
import 'package:tomo_core/focus/live_cycle.dart';
import 'package:tomo_core/notifications/haptics.dart';
import 'package:tomo_core/notifications/notification_schedule.dart';
import 'package:tomo_core/pet/beat.dart';
import 'package:tomo_core/pet/species.dart';

/// Which notifications should exist, and which haptic fires (spec §11).
/// Promises 22 and 23.
void main() {
  // A 25-minute block from 09:00 UTC with a 5-minute break.
  final start = DateTime.utc(2026, 10, 10, 9);
  final end = DateTime.utc(2026, 10, 10, 9, 25);
  DateTime at(int hour, int minute) => DateTime.utc(2026, 10, 10, hour, minute);

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

  const hatchedPet = NotificationSubject(
    species: Species.geode,
    hatched: true,
    petName: 'Pebble',
    taskTitle: 'Write the intro',
  );
  const egg = NotificationSubject(
    species: Species.geode,
    hatched: false,
    petName: null,
    taskTitle: 'Write the intro',
  );

  List<TimerNotification> desired(
    LiveCycle? live,
    DateTime now, {
    bool isForeground = false,
    NotificationSubject subject = hatchedPet,
  }) => desiredNotifications(
    cycle: live,
    now: now,
    isForeground: isForeground,
    subject: subject,
  );

  group('the desired set', () {
    test('is empty with no cycle', () {
      expect(desired(null, at(9, 10)), isEmpty);
    });

    test('is empty while Tomo is open, whatever the cycle', () {
      expect(desired(cycle(), at(9, 10), isForeground: true), isEmpty);
      expect(
        desired(
          cycle(blockRecordId: 7, breakStartAt: at(9, 26)),
          at(9, 27),
          isForeground: true,
        ),
        isEmpty,
      );
    });

    test('a running block has one: block complete, at the end', () {
      final only = desired(cycle(), at(9, 10)).single;

      expect(only.kind, NotificationKind.blockComplete);
      expect(only.slot, NotificationSlot.blockEnd);
      expect(only.fireAt, end);
      expect(only.fireAt.isUtc, isTrue);
      expect(only.channel, NotificationChannel.focusBlock);
    });

    test('with auto-start it has two: the block ending with its break '
        'begun, and the break ending', () {
      final both = desired(cycle(autoStart: true), at(9, 10));

      expect(both.map((n) => n.kind), [
        NotificationKind.blockCompleteBreakBegun,
        NotificationKind.breakComplete,
      ]);
      expect(both.first.fireAt, end);
      expect(both.first.channel, NotificationChannel.focusBlock);
      expect(both.last.fireAt, at(9, 30));
      expect(both.last.slot, NotificationSlot.breakEnd);
      expect(both.last.channel, NotificationChannel.breakOver);
    });

    test('a running break has one: break complete, when it runs out', () {
      final only = desired(
        cycle(blockRecordId: 7, breakStartAt: at(9, 27)),
        at(9, 28),
      ).single;

      expect(only.kind, NotificationKind.breakComplete);
      expect(only.fireAt, at(9, 32));
    });

    test('a stale one never fires: nothing whose time has passed', () {
      expect(desired(cycle(), end), isEmpty);
      expect(desired(cycle(), at(9, 40)), isEmpty);
      expect(
        desired(cycle(blockRecordId: 7, breakStartAt: at(9, 27)), at(9, 32)),
        isEmpty,
      );
    });

    test('with auto-start, back mid-break: only the break ending is left', () {
      final only = desired(cycle(autoStart: true), at(9, 27)).single;

      expect(only.kind, NotificationKind.breakComplete);
      expect(only.fireAt, at(9, 30));
    });

    test('a skipped break has nothing to announce', () {
      expect(
        desired(
          cycle(
            blockRecordId: 7,
            breakStartAt: at(9, 27),
            breakSkippedAt: at(9, 28),
          ),
          at(9, 28),
        ),
        isEmpty,
      );
    });

    test('a finished block with no break taken has nothing pending', () {
      expect(desired(cycle(blockRecordId: 7), at(9, 26)), isEmpty);
    });

    test('there are exactly three kinds, in two fixed slots', () {
      expect(NotificationKind.values, hasLength(3));
      expect(NotificationSlot.values.map((slot) => slot.id), [1, 2]);
      expect(NotificationChannel.focusBlock.androidId, 'focus_block_v1');
      expect(NotificationChannel.breakOver.androidId, 'break_v1');
      expect(NotificationChannel.focusBlock.iosCategory, 'focusBlock');
      expect(NotificationChannel.breakOver.iosCategory, 'break');
    });
  });

  group('when the timer runs out', () {
    // The same moments the notifications fire at; Tomo open, they buzz.
    List<TimerEnd> ends(LiveCycle live, DateTime after) =>
        timerEnds(cycle: live, after: after);

    test('a running block runs out at its end', () {
      expect(ends(cycle(), at(9, 10)), [
        (slot: NotificationSlot.blockEnd, at: end),
      ]);
    });

    test('with auto-start, the break that begins by itself runs out too', () {
      expect(ends(cycle(autoStart: true), at(9, 10)), [
        (slot: NotificationSlot.blockEnd, at: end),
        (slot: NotificationSlot.breakEnd, at: at(9, 30)),
      ]);
    });

    test('a taken break runs out when its minutes are up', () {
      expect(ends(cycle(blockRecordId: 7, breakStartAt: at(9, 27)), end), [
        (slot: NotificationSlot.breakEnd, at: at(9, 32)),
      ]);
    });

    test('only what is still ahead: the moment itself has passed', () {
      expect(ends(cycle(), end), isEmpty);
      expect(ends(cycle(autoStart: true), end), [
        (slot: NotificationSlot.breakEnd, at: at(9, 30)),
      ]);
    });

    test('nothing runs out after a skipped break, or with none taken', () {
      expect(
        ends(
          cycle(
            blockRecordId: 7,
            breakStartAt: at(9, 27),
            breakSkippedAt: at(9, 28),
          ),
          at(9, 28),
        ),
        isEmpty,
      );
      expect(ends(cycle(blockRecordId: 7), at(9, 26)), isEmpty);
    });
  });

  group('what a notification says, as data', () {
    test('the pet by name, the task and the minutes', () {
      final content = desired(cycle(), at(9, 10)).single.content;

      expect(content.petName, 'Pebble');
      expect(content.beforeHatch, isFalse);
      expect(content.taskTitle, 'Write the intro');
      expect(content.focusMinutes, 25);
      expect(content.breakMinutes, 5);
    });

    test('before the hatch it is the egg, and it has no name', () {
      final content = desired(cycle(), at(9, 10), subject: egg).single.content;

      expect(content.beforeHatch, isTrue);
      expect(content.petName, isNull);
    });

    test('a hatched pet not yet named goes by its species', () {
      const unnamed = NotificationSubject(
        species: Species.lily,
        hatched: true,
        petName: null,
        taskTitle: 'Write the intro',
      );

      final content = desired(
        cycle(),
        at(9, 10),
        subject: unnamed,
      ).single.content;

      expect(content.beforeHatch, isFalse);
      expect(content.petName, isNull);
      expect(content.species, Species.lily);
    });

    test('the payload carries only the start of its cycle', () {
      final notification = desired(cycle(), at(9, 10)).single;

      expect(notification.payload, '${start.millisecondsSinceEpoch}');
    });
  });

  group('syncing', () {
    late _FakeScheduler scheduler;

    setUp(() => scheduler = _FakeScheduler());

    Future<void> sync(
      LiveCycle? live,
      DateTime now, {
      bool isForeground = false,
    }) => syncNotifications(
      scheduler,
      cycle: live,
      now: now,
      isForeground: isForeground,
      subject: hatchedPet,
    );

    test('schedules what is desired and cancels the other slot', () async {
      await sync(cycle(), at(9, 10));

      expect(scheduler.pending.keys, [NotificationSlot.blockEnd]);
      expect(scheduler.cancelled, contains(NotificationSlot.breakEnd));
    });

    test('doing it twice leaves the same pending set', () async {
      await sync(cycle(autoStart: true), at(9, 10));
      final once = {...scheduler.pending};
      await sync(cycle(autoStart: true), at(9, 10));

      expect(scheduler.pending.keys, once.keys);
      expect(scheduler.pending.length, 2);
    });

    test('stopping early empties it', () async {
      await sync(cycle(), at(9, 10));
      await sync(null, at(9, 12));

      expect(scheduler.pending, isEmpty);
    });

    test('a new cycle overwrites the old one in the same slot', () async {
      await sync(cycle(), at(9, 10));
      final later = LiveCycle(
        taskId: 2,
        startAt: at(10, 0),
        endAt: at(10, 50),
        focusMinutes: 50,
        breakMinutes: 10,
        autoStart: false,
      );
      await sync(later, at(10, 1));

      expect(scheduler.pending.keys, [NotificationSlot.blockEnd]);
      expect(scheduler.pending[NotificationSlot.blockEnd]!.fireAt, at(10, 50));
    });

    test('coming to the foreground cancels everything and clears what was '
        'delivered', () async {
      await sync(cycle(autoStart: true), at(9, 10));
      await sync(cycle(autoStart: true), at(9, 11), isForeground: true);

      expect(scheduler.pending, isEmpty);
      expect(scheduler.clearedDelivered, 1);
    });

    test('in the background, delivered notifications are left alone', () async {
      await sync(cycle(), at(9, 10));

      expect(scheduler.clearedDelivered, 0);
    });
  });

  group('a tap on a notification', () {
    test('opens Focus when its cycle is still the live one', () {
      expect(
        tapOutcome(
          payload: '${start.millisecondsSinceEpoch}',
          cycle: cycle(blockRecordId: 7),
        ),
        NotificationTap.openFocus,
      );
    });

    test('is an ordinary start when that cycle is gone', () {
      expect(
        tapOutcome(payload: '${start.millisecondsSinceEpoch}', cycle: null),
        NotificationTap.ordinaryStart,
      );
    });

    test('is an ordinary start when a different cycle is live', () {
      final newer = LiveCycle(
        taskId: 1,
        startAt: at(11, 0),
        endAt: at(11, 25),
        focusMinutes: 25,
        breakMinutes: 5,
        autoStart: false,
      );

      expect(
        tapOutcome(payload: '${start.millisecondsSinceEpoch}', cycle: newer),
        NotificationTap.ordinaryStart,
      );
    });

    test('is an ordinary start when the payload is missing or not ours', () {
      expect(
        tapOutcome(payload: null, cycle: cycle()),
        NotificationTap.ordinaryStart,
      );
      expect(
        tapOutcome(payload: 'not a number', cycle: cycle()),
        NotificationTap.ordinaryStart,
      );
    });
  });

  group('the haptic for a block or break ending', () {
    test('a beat will play: the reward tap', () {
      expect(
        hapticFor(isForeground: true, beatWillPlay: true),
        Haptic.rewardTap,
      );
    });

    test('Tomo is open and no beat will play: the timer buzz', () {
      expect(
        hapticFor(isForeground: true, beatWillPlay: false),
        Haptic.timerBuzz,
      );
    });

    test('Tomo is not open: none; the notification speaks instead', () {
      expect(hapticFor(isForeground: false, beatWillPlay: false), Haptic.none);
    });

    test('a beat that will play always means the reward tap, never the buzz '
        'as well', () {
      expect(
        hapticFor(isForeground: false, beatWillPlay: true),
        Haptic.rewardTap,
      );
    });
  });

  group('the haptic each beat fires as it plays', () {
    test('an evolution: the long evolution buzz (C167)', () {
      expect(hapticForBeat(const Evolution(from: 1, to: 2)), Haptic.evolutionBuzz);
    });

    test('every other beat: the reward tap', () {
      for (final beat in const <Beat>[
        BlockCredited(minutes: 25, exp: 250),
        LevelUp(level: 3),
        TaskCompleted(bonusExp: 30),
        Hatch(species: Species.geode),
      ]) {
        expect(hapticForBeat(beat), Haptic.rewardTap, reason: '$beat');
      }
    });
  });
}

final class _FakeScheduler implements NotificationScheduler {
  final pending = <NotificationSlot, TimerNotification>{};
  final cancelled = <NotificationSlot>[];
  int clearedDelivered = 0;

  @override
  Future<void> schedule(TimerNotification notification) async =>
      pending[notification.slot] = notification;

  @override
  Future<void> cancel(NotificationSlot slot) async {
    pending.remove(slot);
    cancelled.add(slot);
  }

  @override
  Future<void> clearDelivered() async => clearedDelivered++;
}

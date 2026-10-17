import 'package:drift/drift.dart' show Value;
import 'package:test/test.dart';
import 'package:tomo_core/data/tomo_database.dart';
import 'package:tomo_core/diagnostics/diagnostic_entry.dart';
import 'package:tomo_core/diagnostics/log.dart';
import 'package:tomo_core/focus/block_lengths.dart';
import 'package:tomo_core/focus/focus_cycle_service.dart';
import 'package:tomo_core/notifications/notification_schedule.dart';
import 'package:tomo_core/notifications/notification_sync.dart';
import 'package:tomo_core/pet/species.dart';
import 'package:tomo_core/result.dart';
import 'package:tomo_core/tasks/task_service.dart';
import 'package:tomo_core/testing.dart';

/// The schedule against the stored cycle and pet: what the app calls on every
/// cycle write and every lifecycle change (spec §11.2). Promise 22, the
/// stored half.
void main() {
  final nine = DateTime.utc(2026, 10, 10, 9);

  late TestClock clock;
  late RecordingSink sink;
  late TomoDatabase db;
  late RecordingScheduler scheduler;
  late bool foreground;
  late NotificationSync sync;
  late int taskId;

  int ms(DateTime instant) => instant.millisecondsSinceEpoch;

  setUp(() async {
    clock = TestClock(nine);
    sink = RecordingSink();
    db = openTestDatabase(clock: clock.call);
    scheduler = RecordingScheduler();
    foreground = false;
    sync = NotificationSync(
      db,
      scheduler,
      log: Log(sinks: [sink]),
      isForeground: () => foreground,
    );
    final projectId = await db
        .into(db.projects)
        .insert(ProjectsCompanion.insert(name: 'Thesis', createdAt: ms(nine)));
    taskId = await db
        .into(db.tasks)
        .insert(
          TasksCompanion.insert(
            projectId: projectId,
            title: 'Outline',
            createdAt: ms(nine),
          ),
        );
    await db
        .into(db.pets)
        .insert(
          PetsCompanion.insert(species: Species.lily, createdAt: ms(nine)),
        );
  });

  tearDown(() => db.close());

  FocusCycleService focus() => FocusCycleService(
    db,
    log: Log(sinks: [sink]),
    afterWrite: sync.sync,
  );

  Future<void> startBlock({bool autoStart = false}) async {
    final started = await focus().startBlock(
      taskId: taskId,
      lengths: const BlockLengths(focusMinutes: 25, breakMinutes: 5),
      autoStart: autoStart,
    );
    expect(started, isA<Success<CycleStanding>>());
  }

  Future<void> hatch({String? name}) => db
      .update(db.pets)
      .write(PetsCompanion(hatchedAt: Value(ms(nine)), name: Value(name)));

  test('with no cycle, every slot is emptied', () async {
    await sync.sync();
    expect(scheduler.pending, isEmpty);
    expect(scheduler.cancelled, NotificationSlot.values.toSet());
  });

  test('in the background, a running block announces its end', () async {
    await startBlock();
    await sync.sync();

    final blockEnd = scheduler.pending[NotificationSlot.blockEnd]!;
    expect(blockEnd.kind, NotificationKind.blockComplete);
    expect(blockEnd.fireAt, nine.add(const Duration(minutes: 25)));
    expect(scheduler.pending, isNot(contains(NotificationSlot.breakEnd)));
  });

  test('in the foreground, nothing is pending and delivered ones '
      'are cleared', () async {
    await startBlock();
    await sync.sync();
    foreground = true;
    await sync.sync();

    expect(scheduler.pending, isEmpty);
    expect(scheduler.clearedDelivered, 1);
  });

  test('before the hatch, the subject is the egg', () async {
    await startBlock();
    await sync.sync();

    final content = scheduler.pending[NotificationSlot.blockEnd]!.content;
    expect(content.beforeHatch, isTrue);
    expect(content.species, Species.lily);
    expect(content.taskTitle, 'Outline');
  });

  test('after the hatch, the subject carries the name', () async {
    await hatch(name: 'Pip');
    await startBlock();
    await sync.sync();

    final content = scheduler.pending[NotificationSlot.blockEnd]!.content;
    expect(content.beforeHatch, isFalse);
    expect(content.petName, 'Pip');
  });

  test('under auto-start, the break is announced up front', () async {
    await startBlock(autoStart: true);
    await sync.sync();

    expect(
      scheduler.pending[NotificationSlot.blockEnd]!.kind,
      NotificationKind.blockCompleteBreakBegun,
    );
    expect(
      scheduler.pending[NotificationSlot.breakEnd]!.fireAt,
      nine.add(const Duration(minutes: 30)),
    );
  });

  test('a cycle whose start is ahead of the clock announces nothing, '
      'because the next open discards it', () async {
    await startBlock();
    clock.now = nine.subtract(const Duration(hours: 1));
    await sync.sync();

    expect(scheduler.pending, isEmpty);
  });

  test('every successful cycle write syncs', () async {
    await startBlock();
    await pumpEventQueue();
    expect(scheduler.pending, contains(NotificationSlot.blockEnd));

    expect(await focus().stopEarly(), isA<Success<CycleStanding>>());
    await pumpEventQueue();
    expect(scheduler.pending, isEmpty);
  });

  test('every successful task write syncs: deleting the cycle\'s task '
      'during its break empties the schedule', () async {
    await startBlock(autoStart: true);
    clock.advance(const Duration(minutes: 26));
    await sync.sync();
    expect(scheduler.pending, contains(NotificationSlot.breakEnd));

    final tasks = TaskService(
      db,
      log: Log(sinks: [sink]),
      afterWrite: sync.sync,
    );
    expect(await tasks.deleteTask(taskId), isA<Success<void>>());
    await pumpEventQueue();
    expect(scheduler.pending, isEmpty);
  });

  test('a refused write does not sync', () async {
    var calls = 0;
    final refused =
        await FocusCycleService(
          db,
          log: Log(sinks: [sink]),
          afterWrite: () async => calls++,
        ).startBlock(
          taskId: taskId,
          lengths: const BlockLengths(focusMinutes: 5, breakMinutes: 5),
          autoStart: false,
        );
    await pumpEventQueue();

    expect(refused, isA<Failure<CycleStanding>>());
    expect(calls, 0);
  });

  test(
    'syncs run one at a time, so the last one sees the last write',
    () async {
      await startBlock();
      scheduler.slow = true;
      final first = sync.sync();
      foreground = true;
      final second = sync.sync();
      await Future.wait([first, second]);

      expect(scheduler.pending, isEmpty);
      expect(scheduler.overlapped, isFalse);
    },
  );

  test('a phone that refuses never throws: it is recorded', () async {
    await startBlock();
    scheduler.fails = true;
    await sync.sync();

    expect(
      sink.entries.map((e) => e.code),
      contains(DiagnosticCode.notificationSyncFailed),
    );
  });
}

/// The phone's pending notifications, as a map from slot.
final class RecordingScheduler implements NotificationScheduler {
  final pending = <NotificationSlot, TimerNotification>{};
  final cancelled = <NotificationSlot>{};
  var clearedDelivered = 0;
  var fails = false;
  var slow = false;
  var overlapped = false;
  var _busy = false;

  Future<void> _call(void Function() change) async {
    if (fails) throw StateError('no notifications here');
    if (_busy) overlapped = true;
    _busy = true;
    if (slow) await Future<void>.delayed(const Duration(milliseconds: 5));
    change();
    _busy = false;
  }

  @override
  Future<void> schedule(TimerNotification notification) =>
      _call(() => pending[notification.slot] = notification);

  @override
  Future<void> cancel(NotificationSlot slot) => _call(() {
    pending.remove(slot);
    cancelled.add(slot);
  });

  @override
  Future<void> clearDelivered() => _call(() => clearedDelivered++);
}

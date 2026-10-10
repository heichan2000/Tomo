import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:test/test.dart';
import 'package:tomo_core/data/tomo_database.dart';
import 'package:tomo_core/diagnostics/diagnostic_entry.dart';
import 'package:tomo_core/diagnostics/log.dart';
import 'package:tomo_core/focus/block_lengths.dart';
import 'package:tomo_core/focus/focus_cycle_service.dart';
import 'package:tomo_core/focus/projection.dart';
import 'package:tomo_core/pet/species.dart';
import 'package:tomo_core/result.dart';
import 'package:tomo_core/tasks/task_status.dart';
import 'package:tomo_core/testing.dart';

/// The five commands and the settle, against the in-memory database
/// (spec §4.3 to §4.9). Promises 1, 5, 9, 12 (starting sets doing; a done task
/// can't be focused), 20 (the hatch block) and 39 (the cycle half).
void main() {
  // 09:00 UTC on a phone eight hours ahead of UTC.
  final nine = DateTime.utc(2026, 10, 10, 9);
  const eightHoursAhead = Duration(hours: 8);

  late TestClock clock;
  late RecordingSink sink;
  late TomoDatabase db;
  late FocusCycleService focus;
  late int projectId;
  late int taskId;
  late int petId;

  int ms(DateTime instant) => instant.millisecondsSinceEpoch;

  FocusCycleService serviceOn(TomoDatabase database) => FocusCycleService(
    database,
    log: Log(sinks: [sink]),
    utcOffsetAt: (_) => eightHoursAhead,
  );

  Future<void> seed(TomoDatabase database) async {
    projectId = await database
        .into(database.projects)
        .insert(ProjectsCompanion.insert(name: 'Thesis', createdAt: ms(nine)));
    taskId = await database
        .into(database.tasks)
        .insert(
          TasksCompanion.insert(
            projectId: projectId,
            title: 'Outline',
            createdAt: ms(nine),
          ),
        );
    petId = await database
        .into(database.pets)
        .insert(
          PetsCompanion.insert(species: Species.joe, createdAt: ms(nine)),
        );
  }

  setUp(() async {
    clock = TestClock(nine);
    sink = RecordingSink();
    db = openTestDatabase(clock: clock.call);
    focus = serviceOn(db);
    await seed(db);
  });

  tearDown(() => db.close());

  Future<TaskRow> task([int? id]) => (db.select(
    db.tasks,
  )..where((t) => t.id.equals(id ?? taskId))).getSingle();
  Future<PetRow> pet() => db.select(db.pets).getSingle();
  Future<List<BlockRecordRow>> records() => (db.select(
    db.blockRecords,
  )..orderBy([(r) => OrderingTerm(expression: r.id)])).get();
  Future<int> cycleRows() async =>
      (await db.select(db.focusCycle).get()).length;

  Future<int> addTask(String title, {TaskStatus? status}) => db
      .into(db.tasks)
      .insert(
        TasksCompanion.insert(
          projectId: projectId,
          title: title,
          status: status == null ? const Value.absent() : Value(status),
          createdAt: ms(nine),
        ),
      );

  /// Starts a block and returns where the cycle stands.
  Future<CycleStanding> start({
    int? onTask,
    BlockLengths lengths = BlockLengths.preset25,
    bool autoStart = false,
  }) async {
    final result = await focus.startBlock(
      taskId: onTask ?? taskId,
      lengths: lengths,
      autoStart: autoStart,
    );
    return switch (result) {
      Success(:final value) => value,
      Failure(:final error) => fail('startBlock failed: $error'),
    };
  }

  Future<CycleStanding> ok(Future<Result<CycleStanding>> command) async =>
      switch (await command) {
        Success(:final value) => value,
        Failure(:final error) => fail('command failed: $error'),
      };

  group('StartBlock', () {
    test('anchors the block at now and now plus its length', () async {
      final standing = await start();

      expect(standing.state, FocusState.focusRunning);
      expect(standing.cycle!.taskId, taskId);
      expect(standing.cycle!.startAt, nine);
      expect(standing.cycle!.endAt, nine.add(const Duration(minutes: 25)));
      expect(standing.cycle!.focusMinutes, 25);
      expect(standing.cycle!.breakMinutes, 5);
      expect(standing.cycle!.isCredited, isFalse);
    });

    test('sets a to-do task to doing', () async {
      await start();

      expect((await task()).status, TaskStatus.doing);
    });

    test('snapshots auto-start into the cycle', () async {
      final standing = await start(autoStart: true);

      expect(standing.cycle!.autoStart, isTrue);
    });

    test('refuses a block shorter than 10 minutes', () async {
      final result = await focus.startBlock(
        taskId: taskId,
        lengths: const BlockLengths(focusMinutes: 9, breakMinutes: 5),
        autoStart: false,
      );

      expect(
        (result as Failure).error,
        const Invalid(
          InvalidField.focusMinutes,
          InvalidRule.outOfRange,
          limit: 10,
        ),
      );
      expect(await cycleRows(), 0);
      expect((await task()).status, TaskStatus.todo);
    });

    test('refuses a block longer than 120 minutes', () async {
      final result = await focus.startBlock(
        taskId: taskId,
        lengths: const BlockLengths(focusMinutes: 121, breakMinutes: 5),
        autoStart: false,
      );

      expect(
        (result as Failure).error,
        const Invalid(
          InvalidField.focusMinutes,
          InvalidRule.outOfRange,
          limit: 120,
        ),
      );
    });

    test('refuses a break outside 1 to 30 minutes', () async {
      final result = await focus.startBlock(
        taskId: taskId,
        lengths: const BlockLengths(focusMinutes: 25, breakMinutes: 31),
        autoStart: false,
      );

      expect(
        (result as Failure).error,
        const Invalid(
          InvalidField.breakMinutes,
          InvalidRule.outOfRange,
          limit: 30,
        ),
      );
    });

    test('refuses a task that does not exist', () async {
      final result = await focus.startBlock(
        taskId: 999,
        lengths: BlockLengths.preset25,
        autoStart: false,
      );

      expect((result as Failure).error, const NotFound(EntityKind.task, 999));
    });

    test("a done task can't be focused", () async {
      final done = await addTask('Finished', status: TaskStatus.done);

      final result = await focus.startBlock(
        taskId: done,
        lengths: BlockLengths.preset25,
        autoStart: false,
      );

      expect((result as Failure).error, TaskDone(done));
      expect(await cycleRows(), 0);
      expect((await task(done)).status, TaskStatus.done);
    });
  });

  group('the settle', () {
    test('nothing is earned while the block is still running', () async {
      await start();
      clock.advance(const Duration(minutes: 24, seconds: 59));

      final standing = await ok(focus.reconcile());

      expect(standing.state, FocusState.focusRunning);
      expect(await records(), isEmpty);
      expect((await pet()).exp, 0);
    });

    test('a finished block earns 10 EXP per focus minute, once', () async {
      await start();
      clock.advance(const Duration(minutes: 25));

      final standing = await ok(focus.reconcile());

      expect(standing.state, FocusState.focusComplete);
      expect(standing.cycle!.isCredited, isTrue);
      expect((await pet()).exp, 250);

      final record = (await records()).single;
      expect(record.petId, petId);
      expect(record.taskId, taskId);
      expect(record.projectId, projectId);
      expect(record.startedAt, ms(nine));
      expect(record.endedAt, ms(nine.add(const Duration(minutes: 25))));
      expect(record.minutes, 25);
      expect(record.expGranted, 250);
      expect(record.petExpAfter, 250);
      expect(record.settledAt, ms(clock.now));
      expect(standing.cycle!.blockRecordId, record.id);
    });

    test("it counts toward the task's own numbers", () async {
      await start();
      clock.advance(const Duration(minutes: 30));
      await ok(focus.reconcile());

      final settled = await task();
      expect(settled.actualPomodoros, 1);
      expect(settled.cumulativeFocusMinutes, 25);
      expect(settled.lastFocusedAt, ms(clock.now));
    });

    test('however often the app looks again, it is credited once', () async {
      await start();
      clock.advance(const Duration(minutes: 25));

      await ok(focus.reconcile());
      await ok(focus.reconcile());
      clock.advance(const Duration(days: 3));
      await ok(focus.reconcile());
      await ok(serviceOn(db).reconcile());

      expect(await records(), hasLength(1));
      expect((await pet()).exp, 250);
      expect((await task()).actualPomodoros, 1);
      expect((await task()).cumulativeFocusMinutes, 25);
    });

    test(
      'killed mid-block and reopened days later: it still credits',
      () async {
        await start();
        clock.advance(const Duration(days: 4));

        // A new process: a new service over the same stored rows.
        final standing = await ok(serviceOn(db).reconcile());

        expect(standing.state, FocusState.focusComplete);
        expect((await pet()).exp, 250);
        expect(await records(), hasLength(1));
      },
    );

    test('the first finished block hatches the egg', () async {
      expect((await pet()).hatchedAt, isNull);

      await start();
      clock.advance(const Duration(minutes: 25));
      await ok(focus.reconcile());

      expect((await pet()).hatchedAt, ms(clock.now));
      final record = (await records()).single;
      expect(record.petExpAfter - record.expGranted, 0);
    });

    test(
      'a later block is not a hatch and leaves the hatch day alone',
      () async {
        await start();
        clock.advance(const Duration(minutes: 25));
        await ok(focus.reconcile());
        final hatchedAt = (await pet()).hatchedAt;

        await start(lengths: BlockLengths.preset50);
        clock.advance(const Duration(minutes: 50));
        await ok(focus.reconcile());

        expect((await pet()).hatchedAt, hatchedAt);
        expect((await pet()).exp, 750);
        final second = (await records()).last;
        expect(second.expGranted, 500);
        expect(second.petExpAfter, 750);
      },
    );

    test('it stores the local day the block ended and the UTC offset', () async {
      // Ends 15:55 UTC, which is 23:55 on the 10th, eight hours ahead.
      clock.now = DateTime.utc(2026, 10, 10, 15, 30);
      await start();
      // Opened again after local midnight: the day it ended is still the 10th.
      clock.now = DateTime.utc(2026, 10, 10, 18);
      await ok(focus.reconcile());

      final record = (await records()).single;
      expect(record.localDate, '2026-10-10');
      expect(record.utcOffsetMinutes, 480);
    });

    test(
      'a block ending just after local midnight belongs to the new day',
      () async {
        // Ends 16:05 UTC, which is 00:05 on the 11th, eight hours ahead.
        clock.now = DateTime.utc(2026, 10, 10, 15, 40);
        await start();
        clock.now = DateTime.utc(2026, 10, 10, 16, 5);
        await ok(focus.reconcile());

        expect((await records()).single.localDate, '2026-10-11');
      },
    );

    test('the block record keeps the project the task had at settle', () async {
      final other = await db
          .into(db.projects)
          .insert(ProjectsCompanion.insert(name: 'Other', createdAt: 0));
      await start();
      await (db.update(db.tasks)..where((t) => t.id.equals(taskId))).write(
        TasksCompanion(projectId: Value(other)),
      );
      clock.advance(const Duration(minutes: 25));
      await ok(focus.reconcile());

      expect((await records()).single.projectId, other);
    });

    test('EXP stops at the 32-bit bound', () async {
      await db
          .update(db.pets)
          .write(const PetsCompanion(exp: Value(2147483600)));
      await start();
      clock.advance(const Duration(minutes: 25));
      await ok(focus.reconcile());

      expect((await pet()).exp, 2147483647);
      expect((await records()).single.petExpAfter, 2147483647);
    });
  });

  group('StopEarly', () {
    test('a stopped block earns nothing and leaves no trace', () async {
      await start();
      clock.advance(const Duration(minutes: 24));

      final standing = await ok(focus.stopEarly());

      expect(standing.state, FocusState.idle);
      expect(standing.cycle, isNull);
      expect(await cycleRows(), 0);
      expect(await records(), isEmpty);
      expect((await pet()).exp, 0);
      expect((await pet()).hatchedAt, isNull);
      final stopped = await task();
      expect(stopped.actualPomodoros, 0);
      expect(stopped.cumulativeFocusMinutes, 0);
      expect(stopped.lastFocusedAt, isNull);
    });

    test('stopping costs that block and nothing before it', () async {
      await start();
      clock.advance(const Duration(minutes: 25));
      await ok(focus.reconcile());
      await start();
      clock.advance(const Duration(minutes: 5));

      await ok(focus.stopEarly());

      expect((await pet()).exp, 250);
      expect(await records(), hasLength(1));
      expect((await task()).actualPomodoros, 1);
    });

    test('the task it started stays doing', () async {
      await start();
      await ok(focus.stopEarly());

      expect((await task()).status, TaskStatus.doing);
    });

    test('if the end passed while the confirmation was open, the block '
        'completed and is credited', () async {
      await start();
      clock.advance(const Duration(minutes: 25));

      final standing = await ok(focus.stopEarly());

      expect(standing.state, FocusState.focusComplete);
      expect(standing.cycle!.isCredited, isTrue);
      expect((await pet()).exp, 250);
      expect(await records(), hasLength(1));
    });

    test('with nothing running it is a mistake: loud in debug and tests', () {
      expect(focus.stopEarly, throwsA(isA<AssertionError>()));
    });
  });

  group('TakeBreak and SkipBreak', () {
    test('a break starts when taken and runs its minutes', () async {
      await start();
      clock.advance(const Duration(minutes: 26));

      final taken = await ok(focus.takeBreak());

      expect(taken.state, FocusState.breakRunning);
      expect(taken.cycle!.breakStartAt, clock.now);

      clock.advance(const Duration(minutes: 5));
      expect((await ok(focus.reconcile())).state, FocusState.breakComplete);
    });

    test('a skipped break is over at once and costs nothing', () async {
      await start();
      clock.advance(const Duration(minutes: 26));
      await ok(focus.takeBreak());
      clock.advance(const Duration(minutes: 1));

      final skipped = await ok(focus.skipBreak());

      expect(skipped.state, FocusState.breakComplete);
      expect(skipped.cycle!.breakSkippedAt, clock.now);
      expect((await pet()).exp, 250);
    });

    test('taking a break settles a block that is still owed', () async {
      await start();
      clock.advance(const Duration(minutes: 26));

      final taken = await ok(focus.takeBreak());

      expect(taken.cycle!.isCredited, isTrue);
      expect((await pet()).exp, 250);
    });

    test('a break cannot be taken while the block is running', () async {
      await start();

      expect(focus.takeBreak, throwsA(isA<AssertionError>()));
    });
  });

  group('Leave', () {
    test('ends the cycle and keeps what was earned', () async {
      await start();
      clock.advance(const Duration(minutes: 25));

      final left = await ok(focus.leave());

      expect(left.state, FocusState.idle);
      expect(await cycleRows(), 0);
      expect((await pet()).exp, 250);
      expect(await records(), hasLength(1));
    });

    test('ends the cycle from a break too', () async {
      await start();
      clock.advance(const Duration(minutes: 26));
      await ok(focus.takeBreak());

      expect((await ok(focus.leave())).state, FocusState.idle);
      expect(await cycleRows(), 0);
    });

    test('is not a way out of a running block', () async {
      await start();

      await expectLater(focus.leave, throwsA(isA<AssertionError>()));
      expect(await cycleRows(), 1);
    });
  });

  group('the next block', () {
    test(
      'replaces a finished cycle, settling it first if still owed',
      () async {
        await start();
        clock.advance(const Duration(minutes: 40));

        // Never looked at since it ended: starting again must not lose it.
        final next = await start(lengths: BlockLengths.preset50);

        expect(next.state, FocusState.focusRunning);
        expect(next.cycle!.focusMinutes, 50);
        expect(next.cycle!.isCredited, isFalse);
        expect(await cycleRows(), 1);
        expect((await pet()).exp, 250);
        expect(await records(), hasLength(1));
      },
    );

    test('may start during a break, on a different task', () async {
      final other = await addTask('Chapter two');
      await start();
      clock.advance(const Duration(minutes: 26));
      await ok(focus.takeBreak());

      final next = await start(onTask: other);

      expect(next.state, FocusState.focusRunning);
      expect(next.cycle!.taskId, other);
      expect((await task(other)).status, TaskStatus.doing);
    });

    test('cannot start while a block is running', () async {
      await start();
      clock.advance(const Duration(minutes: 5));

      await expectLater(
        () => focus.startBlock(
          taskId: taskId,
          lengths: BlockLengths.preset50,
          autoStart: false,
        ),
        throwsA(isA<AssertionError>()),
      );
      final still = await ok(focus.reconcile());
      expect(still.cycle!.focusMinutes, 25);
      expect(still.cycle!.startAt, nine);
    });

    test('no next block on a task marked done after its block; the break '
        'can still be taken', () async {
      await start();
      clock.advance(const Duration(minutes: 25));
      await ok(focus.reconcile());
      await (db.update(db.tasks)..where((t) => t.id.equals(taskId))).write(
        const TasksCompanion(status: Value(TaskStatus.done)),
      );

      final again = await focus.startBlock(
        taskId: taskId,
        lengths: BlockLengths.preset25,
        autoStart: false,
      );
      final onBreak = await ok(focus.takeBreak());

      expect((again as Failure).error, TaskDone(taskId));
      expect(onBreak.state, FocusState.breakRunning);
    });

    test('a refused next block leaves the finished cycle in place', () async {
      await start();
      clock.advance(const Duration(minutes: 25));

      final refused = await focus.startBlock(
        taskId: 999,
        lengths: BlockLengths.preset25,
        autoStart: false,
      );

      expect((refused as Failure).error, const NotFound(EntityKind.task, 999));
      final standing = await ok(focus.reconcile());
      expect(standing.state, FocusState.focusComplete);
      expect((await pet()).exp, 250);
    });
  });

  group('auto-start', () {
    test('the settle starts the break by itself, at the block end', () async {
      await start(autoStart: true);
      clock.advance(const Duration(minutes: 27));

      final standing = await ok(focus.reconcile());

      expect(standing.state, FocusState.breakRunning);
      expect(
        standing.cycle!.breakStartAt,
        nine.add(const Duration(minutes: 25)),
      );
    });

    test('gone four hours: one block credited, the break counted as taken, '
        'and no block started in the absence', () async {
      await start(autoStart: true);
      clock.advance(const Duration(hours: 4));

      final standing = await ok(focus.reconcile());

      expect(standing.state, FocusState.breakComplete);
      expect(await records(), hasLength(1));
      expect((await pet()).exp, 250);
      expect((await task()).actualPomodoros, 1);
    });

    test('earns exactly what the same block earns without it', () async {
      await start(autoStart: true);
      clock.advance(const Duration(days: 2));
      await ok(focus.reconcile());

      expect((await pet()).exp, 250);
    });
  });

  group('the clock moved backward past the start', () {
    test('the block is discarded at zero, with the clock notice', () async {
      await start();
      clock.now = nine.subtract(const Duration(minutes: 30));

      final standing = await ok(focus.reconcile());

      expect(standing.state, FocusState.idle);
      expect(standing.clockNotice, isTrue);
      expect(await cycleRows(), 0);
      expect(await records(), isEmpty);
      expect((await pet()).exp, 0);
    });

    test('the notice is reported once', () async {
      await start();
      clock.now = nine.subtract(const Duration(minutes: 30));
      await ok(focus.reconcile());

      expect((await ok(focus.reconcile())).clockNotice, isFalse);
    });
  });

  group('the beat run', () {
    test('is unseen when a block is credited', () async {
      await start();
      clock.advance(const Duration(minutes: 25));

      expect((await ok(focus.reconcile())).cycle!.seenAt, isNull);
    });

    test('once marked seen, stays seen at that moment', () async {
      await start();
      clock.advance(const Duration(minutes: 25));
      await ok(focus.reconcile());
      clock.advance(const Duration(seconds: 4));
      final seenAt = clock.now;

      final marked = await ok(focus.markBeatRunSeen());
      clock.advance(const Duration(minutes: 1));
      final again = await ok(focus.markBeatRunSeen());

      expect(marked.cycle!.seenAt, seenAt);
      expect(again.cycle!.seenAt, seenAt);
    });

    test(
      'a kill before it is marked leaves it unseen, to replay once',
      () async {
        await start();
        clock.advance(const Duration(minutes: 25));
        await ok(focus.reconcile());

        // A new process over the same rows.
        expect((await ok(serviceOn(db).reconcile())).cycle!.seenAt, isNull);
      },
    );

    test('there is nothing to mark while a block is running', () async {
      await start();

      expect((await ok(focus.markBeatRunSeen())).cycle!.seenAt, isNull);
    });
  });

  group('the estimate prompt', () {
    Future<void> plan(int blocks) =>
        (db.update(db.tasks)..where((t) => t.id.equals(taskId))).write(
          TasksCompanion(estimatedPomodoros: Value(blocks)),
        );

    Future<bool> prompt() async => switch (await focus.takeEstimatePrompt()) {
      Success(:final value) => value,
      Failure(:final error) => fail('$error'),
    };

    Future<void> finishABlock() async {
      await start();
      clock.advance(const Duration(minutes: 25));
      await ok(focus.reconcile());
    }

    test('fires when the finished blocks reach the plan', () async {
      await plan(1);
      await finishABlock();

      expect(await prompt(), isTrue);
      expect((await task()).estimatePromptedAt, ms(clock.now));
    });

    test('fires once per task, ever', () async {
      await plan(1);
      await finishABlock();
      expect(await prompt(), isTrue);
      final firstAt = (await task()).estimatePromptedAt;

      expect(await prompt(), isFalse);
      await plan(2);
      await finishABlock();
      expect(await prompt(), isFalse);
      expect((await task()).estimatePromptedAt, firstAt);
    });

    test('does not fire while blocks remain in the plan', () async {
      await plan(3);
      await finishABlock();

      expect(await prompt(), isFalse);
      expect((await task()).estimatePromptedAt, isNull);
    });

    test('does not fire for a task with no plan', () async {
      await finishABlock();

      expect(await prompt(), isFalse);
    });

    test('does not fire before the block is finished', () async {
      await plan(1);
      await (db.update(db.tasks)..where((t) => t.id.equals(taskId))).write(
        const TasksCompanion(actualPomodoros: Value(1)),
      );
      await start();

      expect(await prompt(), isFalse);
    });
  });

  group('a settle that is cut off', () {
    test('rolls back whole, and the block is settled the next time', () async {
      final failing = _FailOnce();
      final cutOff = openTomoDatabase(
        NativeDatabase.memory().interceptWith(failing),
        clock: clock.call,
        log: Log(sinks: const []),
      );
      addTearDown(cutOff.close);
      await seed(cutOff);
      final service = serviceOn(cutOff);
      final started = await service.startBlock(
        taskId: taskId,
        lengths: BlockLengths.preset25,
        autoStart: false,
      );
      expect(started, isA<Success<CycleStanding>>());
      clock.advance(const Duration(minutes: 25));

      // The settle's last write, marking the cycle credited, fails: as if the
      // process died just before it.
      failing.failNextUpdateOf = 'focus_cycle';
      final first = await service.reconcile();

      expect((first as Failure).error, const StorageFailed());
      expect(sink.entries.single.code, DiagnosticCode.focusWriteFailed);
      expect(await cutOff.select(cutOff.blockRecords).get(), isEmpty);
      expect((await cutOff.select(cutOff.pets).getSingle()).exp, 0);
      expect((await cutOff.select(cutOff.pets).getSingle()).hatchedAt, isNull);
      final untouched = await cutOff.select(cutOff.tasks).getSingle();
      expect(untouched.actualPomodoros, 0);
      expect(untouched.cumulativeFocusMinutes, 0);

      // Next launch.
      final second = await ok(serviceOn(cutOff).reconcile());

      expect(second.cycle!.isCredited, isTrue);
      expect(await cutOff.select(cutOff.blockRecords).get(), hasLength(1));
      expect((await cutOff.select(cutOff.pets).getSingle()).exp, 250);
      expect(
        (await cutOff.select(cutOff.tasks).getSingle()).actualPomodoros,
        1,
      );
    });
  });
}

/// Makes one chosen write fail, the way a process killed mid-transaction
/// leaves it unfinished.
final class _FailOnce extends QueryInterceptor {
  /// When set, the next `UPDATE` of this table throws, once.
  String? failNextUpdateOf;

  @override
  Future<int> runUpdate(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    final table = failNextUpdateOf;
    if (table != null && statement.startsWith('UPDATE "$table"')) {
      failNextUpdateOf = null;
      throw StateError('killed mid-settle');
    }
    return super.runUpdate(executor, statement, args);
  }
}

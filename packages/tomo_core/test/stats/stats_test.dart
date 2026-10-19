import 'package:test/test.dart';
import 'package:tomo_core/data/tomo_database.dart';
import 'package:tomo_core/diagnostics/log.dart';
import 'package:tomo_core/focus/block_lengths.dart';
import 'package:tomo_core/focus/focus_cycle_service.dart';
import 'package:tomo_core/pet/species.dart';
import 'package:tomo_core/result.dart';
import 'package:tomo_core/stats/stats.dart';
import 'package:tomo_core/tasks/task.dart';
import 'package:tomo_core/tasks/task_service.dart';
import 'package:tomo_core/tasks/task_status.dart';
import 'package:tomo_core/testing.dart';

/// The four Stats numbers (spec §8.9, ADR-0026), counted fresh from block
/// records every time. Promises 14 and 15.
void main() {
  // A phone eight hours ahead of UTC.
  const eightHoursAhead = Duration(hours: 8);

  late TestClock clock;
  late TomoDatabase db;
  late FocusCycleService focus;
  late TaskService tasks;
  late StatsReader stats;
  late Project project;
  late Task task;

  T ok<T>(Result<T> result) => switch (result) {
    Success(:final value) => value,
    Failure(:final error) => fail('expected success, got $error'),
  };

  setUp(() async {
    clock = TestClock(DateTime.utc(2026, 10, 10, 1));
    db = openTestDatabase(clock: clock.call);
    final log = Log(sinks: const []);
    focus = FocusCycleService(
      db,
      log: log,
      utcOffsetAt: (_) => eightHoursAhead,
    );
    tasks = TaskService(db, log: log, utcOffsetAt: (_) => eightHoursAhead);
    stats = StatsReader(db);
    await db
        .into(db.pets)
        .insert(PetsCompanion.insert(species: Species.geode, createdAt: 0));
    project = ok(await tasks.createProject('Thesis'));
    task = ok(await tasks.createTask(projectId: project.id, title: 'Outline'));
  });

  tearDown(() => db.close());

  /// Runs one whole block starting at [startUtc] and leaves the cycle.
  Future<void> block(DateTime startUtc, BlockLengths lengths, {int? on}) async {
    clock.now = startUtc;
    ok(
      await focus.startBlock(
        taskId: on ?? task.id,
        lengths: lengths,
        autoStart: false,
      ),
    );
    clock.advance(Duration(minutes: lengths.focusMinutes));
    ok(await focus.leave());
  }

  /// Three blocks: two on the 10th (local), one on the 11th. 125 minutes.
  Future<void> threeBlocks() async {
    await block(DateTime.utc(2026, 10, 10, 1), BlockLengths.preset25);
    await block(DateTime.utc(2026, 10, 10, 3), BlockLengths.preset50);
    await block(DateTime.utc(2026, 10, 11, 2), BlockLengths.preset50);
  }

  test('the four numbers, counted from the block records', () async {
    await threeBlocks();

    final numbers = await stats.read();

    // 1250 EXP: past 1200, so level 3.
    expect(numbers.level, 3);
    expect(numbers.minutesFocused, 125);
    expect(numbers.blocksFinished, 3);
    expect(numbers.daysFocused, 2);
  });

  test('a stopped block counts for nothing', () async {
    await block(DateTime.utc(2026, 10, 10, 1), BlockLengths.preset25);
    ok(
      await focus.startBlock(
        taskId: task.id,
        lengths: BlockLengths.preset50,
        autoStart: false,
      ),
    );
    clock.advance(const Duration(minutes: 40));
    ok(await focus.stopEarly());

    final numbers = await stats.read();

    expect(numbers.minutesFocused, 25);
    expect(numbers.blocksFinished, 1);
    expect(numbers.daysFocused, 1);
  });

  group('days focused', () {
    test('counts a day once, however many blocks it holds', () async {
      await block(DateTime.utc(2026, 10, 10, 1), BlockLengths.preset25);
      await block(DateTime.utc(2026, 10, 10, 2), BlockLengths.preset25);
      await block(DateTime.utc(2026, 10, 10, 3), BlockLengths.preset25);

      expect((await stats.read()).daysFocused, 1);
    });

    test('goes by the local day the block ended, not the UTC day', () async {
      // 15:50 UTC is 23:50 on the 10th locally; the block ends at 00:15 on
      // the 11th. A second block later on the UTC 10th is also the local 11th.
      await block(DateTime.utc(2026, 10, 10, 15, 50), BlockLengths.preset25);
      await block(DateTime.utc(2026, 10, 10, 17), BlockLengths.preset25);

      expect((await stats.read()).daysFocused, 1);
    });

    test('a block across local midnight belongs to the day it ended', () async {
      await block(DateTime.utc(2026, 10, 10, 1), BlockLengths.preset25);
      await block(DateTime.utc(2026, 10, 10, 15, 50), BlockLengths.preset25);

      // The 10th, and the 11th.
      expect((await stats.read()).daysFocused, 2);
    });

    test('only grows: a missed day takes nothing away', () async {
      await block(DateTime.utc(2026, 10, 10, 1), BlockLengths.preset25);
      final before = (await stats.read()).daysFocused;

      await block(DateTime.utc(2026, 10, 20, 1), BlockLengths.preset25);

      expect((await stats.read()).daysFocused, before + 1);
    });
  });

  group('none of them can go down', () {
    late int level;
    late int minutes;
    late int blocks;
    late int days;

    setUp(() async {
      await threeBlocks();
      final before = await stats.read();
      level = before.level;
      minutes = before.minutesFocused;
      blocks = before.blocksFinished;
      days = before.daysFocused;
    });

    Future<void> expectUnchanged() async {
      final after = await stats.read();
      expect(after.level, greaterThanOrEqualTo(level));
      expect(after.minutesFocused, minutes);
      expect(after.blocksFinished, blocks);
      expect(after.daysFocused, days);
    }

    test('when the task is deleted', () async {
      ok(await tasks.deleteTask(task.id));

      await expectUnchanged();
    });

    test('when the project is deleted', () async {
      ok(await tasks.deleteProject(project.id));

      await expectUnchanged();
    });

    test('when a done task is reopened', () async {
      ok(
        await tasks.updateTask(
          task.id,
          const TaskPatch(status: TaskStatus.done),
        ),
      );
      ok(
        await tasks.updateTask(
          task.id,
          const TaskPatch(status: TaskStatus.doing),
        ),
      );

      await expectUnchanged();
    });
  });

  test('the completion bonus raises the level and no other number', () async {
    // 500 minutes of focus is 5000 EXP, level 9; the bonus adds 500 more.
    for (var i = 0; i < 10; i++) {
      await block(
        DateTime.utc(2026, 10, 10, 1).add(Duration(hours: i)),
        BlockLengths.preset50,
      );
    }
    final before = await stats.read();
    expect(before.level, 9);

    ok(
      await tasks.updateTask(task.id, const TaskPatch(status: TaskStatus.done)),
    );
    final after = await stats.read();

    expect(after.level, 10);
    expect(after.minutesFocused, before.minutesFocused);
    expect(after.blocksFinished, before.blocksFinished);
    expect(after.daysFocused, before.daysFocused);
  });

  group('the day so far, for the break lines', () {
    test('the blocks and minutes that ended on the local day of now', () async {
      await threeBlocks();

      // 09:00 local on the 10th.
      final tenth = await stats.dayOf(
        DateTime.utc(2026, 10, 10, 1),
        utcOffsetAt: (_) => eightHoursAhead,
      );
      expect((tenth.blocks, tenth.minutes), (2, 75));

      // 23:00 UTC on the 10th is already the 11th locally.
      final eleventh = await stats.dayOf(
        DateTime.utc(2026, 10, 10, 23),
        utcOffsetAt: (_) => eightHoursAhead,
      );
      expect((eleventh.blocks, eleventh.minutes), (1, 50));
    });

    test('nothing finished that day is nothing', () async {
      await threeBlocks();

      final day = await stats.dayOf(
        DateTime.utc(2026, 10, 20, 1),
        utcOffsetAt: (_) => eightHoursAhead,
      );
      expect((day.blocks, day.minutes), (0, 0));
    });
  });
}

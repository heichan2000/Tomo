import 'package:test/test.dart';
import 'package:tomo_core/data/tomo_database.dart';
import 'package:tomo_core/diagnostics/log.dart';
import 'package:tomo_core/focus/block_lengths.dart';
import 'package:tomo_core/focus/focus_cycle_service.dart';
import 'package:tomo_core/pet/beat.dart';
import 'package:tomo_core/pet/beat_queue.dart';
import 'package:tomo_core/pet/species.dart';
import 'package:tomo_core/result.dart';
import 'package:tomo_core/testing.dart';

/// The beat queue against the database (spec §7.4): a run is owed while the
/// live cycle is credited and unseen, and is rebuilt from its block record.
/// Promises 16 (Data) and 20 (Data).
void main() {
  late TestClock clock;
  late TomoDatabase db;
  late FocusCycleService focus;
  late BeatQueue beats;
  late int taskId;

  T ok<T>(Result<T> result) => switch (result) {
    Success(:final value) => value,
    Failure(:final error) => fail('expected success, got $error'),
  };

  setUp(() async {
    clock = TestClock(DateTime.utc(2026, 10, 10, 9));
    db = openTestDatabase(clock: clock.call);
    focus = FocusCycleService(
      db,
      log: Log(sinks: const []),
      utcOffsetAt: (_) => Duration.zero,
    );
    beats = BeatQueue(db);
    final project = await db
        .into(db.projects)
        .insert(ProjectsCompanion.insert(name: 'Thesis', createdAt: 0));
    taskId = await db
        .into(db.tasks)
        .insert(
          TasksCompanion.insert(
            projectId: project,
            title: 'Outline',
            createdAt: 0,
          ),
        );
    await db
        .into(db.pets)
        .insert(PetsCompanion.insert(species: Species.lily, createdAt: 0));
  });

  tearDown(() => db.close());

  Future<void> start([BlockLengths lengths = BlockLengths.preset25]) async =>
      ok(
        await focus.startBlock(
          taskId: taskId,
          lengths: lengths,
          autoStart: false,
        ),
      );

  Future<void> finishABlock([
    BlockLengths lengths = BlockLengths.preset25,
  ]) async {
    await start(lengths);
    clock.advance(Duration(minutes: lengths.focusMinutes));
    ok(await focus.reconcile());
  }

  test('nothing is owed with no cycle', () async {
    expect(await beats.owedRun(), isEmpty);
  });

  test('nothing is owed while the block is running', () async {
    await start();

    expect(await beats.owedRun(), isEmpty);
  });

  test('the first finished block is owed its beat and the hatch', () async {
    await finishABlock(BlockLengths.firstEver);

    expect(await beats.owedRun(), [
      const BlockCredited(minutes: 15, exp: 150),
      const Hatch(species: Species.lily),
    ]);
  });

  test(
    'a later block is owed an ordinary run, rebuilt from its record',
    () async {
      await finishABlock(BlockLengths.firstEver);
      ok(await focus.markBeatRunSeen());
      // 150 EXP so far; 50 more minutes reaches 650, level 2.
      await finishABlock(BlockLengths.preset50);

      expect(await beats.owedRun(), [
        const BlockCredited(minutes: 50, exp: 500),
        const LevelUp(level: 2),
      ]);
    },
  );

  test('once the run is seen, nothing is owed', () async {
    await finishABlock();

    ok(await focus.markBeatRunSeen());

    expect(await beats.owedRun(), isEmpty);
  });

  test('killed before the run was seen: it is owed again, the same', () async {
    await finishABlock();
    final first = await beats.owedRun();

    // A new process over the same rows.
    final afterRestart = await BeatQueue(db).owedRun();

    expect(afterRestart, first);
    expect(afterRestart, isNotEmpty);
  });

  test('it replays exactly once: seen after the replay, it is gone', () async {
    await finishABlock();
    await BeatQueue(db).owedRun();
    ok(await focus.markBeatRunSeen());

    expect(await BeatQueue(db).owedRun(), isEmpty);
  });

  test(
    'leaving without returning to Focus drops the run; the EXP stays',
    () async {
      await finishABlock();

      ok(await focus.leave());

      expect(await beats.owedRun(), isEmpty);
      expect((await db.select(db.pets).getSingle()).exp, 250);
    },
  );

  test('starting the next block drops an unseen run too', () async {
    await finishABlock();

    await start();

    expect(await beats.owedRun(), isEmpty);
    expect((await db.select(db.pets).getSingle()).exp, 250);
  });
}

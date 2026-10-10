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
import 'package:tomo_core/tasks/task.dart';
import 'package:tomo_core/tasks/task_service.dart';
import 'package:tomo_core/tasks/task_status.dart';
import 'package:tomo_core/testing.dart';

/// The one service that owns every task and project write (spec §5).
/// Promises 4, 10, 12, 13, 39 and 41.
void main() {
  final nine = DateTime.utc(2026, 10, 10, 9);

  late TestClock clock;
  late RecordingSink sink;
  late TomoDatabase db;
  late TaskService tasks;
  late FocusCycleService focus;
  late int projectId;

  T ok<T>(Result<T> result) => switch (result) {
    Success(:final value) => value,
    Failure(:final error) => fail('expected success, got $error'),
  };

  WriteError errorOf<T>(Result<T> result) => switch (result) {
    Success(:final value) => fail('expected an error, got $value'),
    Failure(:final error) => error,
  };

  setUp(() async {
    clock = TestClock(nine);
    sink = RecordingSink();
    db = openTestDatabase(clock: clock.call);
    final log = Log(sinks: [sink]);
    tasks = TaskService(db, log: log, utcOffsetAt: (_) => Duration.zero);
    focus = FocusCycleService(db, log: log, utcOffsetAt: (_) => Duration.zero);
    await db
        .into(db.pets)
        .insert(
          PetsCompanion.insert(
            species: Species.lily,
            createdAt: nine.millisecondsSinceEpoch,
          ),
        );
    projectId = ok(await tasks.createProject('Thesis')).id;
  });

  tearDown(() => db.close());

  Future<Task> add(String title, {int? inProject, int? estimate}) async => ok(
    await tasks.createTask(
      projectId: inProject ?? projectId,
      title: title,
      estimate: estimate,
    ),
  );

  Future<Task> read(int id) async => (await tasks.watchTask(id).first)!;
  Future<int> petExp() async => (await db.select(db.pets).getSingle()).exp;
  Future<List<BlockRecordRow>> records() => db.select(db.blockRecords).get();
  Future<int> cycleRows() async =>
      (await db.select(db.focusCycle).get()).length;

  Future<void> startBlock(int taskId) async => ok(
    await focus.startBlock(
      taskId: taskId,
      lengths: BlockLengths.preset25,
      autoStart: false,
    ),
  );

  /// Runs a whole 25-minute block on [taskId] and settles it.
  Future<void> finishBlock(int taskId) async {
    await startBlock(taskId);
    clock.advance(const Duration(minutes: 25));
    ok(await focus.reconcile());
  }

  Future<Task> markDone(int id) async =>
      ok(await tasks.updateTask(id, const TaskPatch(status: TaskStatus.done)));

  group('projects', () {
    test('a new project keeps its trimmed name', () async {
      final project = ok(await tasks.createProject('  Garden  '));

      expect(project.name, 'Garden');
      expect(project.createdAt, nine);
    });

    test('a name must not be empty', () async {
      expect(
        errorOf(await tasks.createProject('   ')),
        const Invalid(InvalidField.projectName, InvalidRule.empty),
      );
    });

    test('a name may be 60 characters and no more', () async {
      expect(ok(await tasks.createProject('n' * 60)).name, hasLength(60));
      expect(
        errorOf(await tasks.createProject('n' * 61)),
        const Invalid(InvalidField.projectName, InvalidRule.tooLong, limit: 60),
      );
    });

    test('two projects may share a name', () async {
      final first = ok(await tasks.createProject('Garden'));
      final second = ok(await tasks.createProject('Garden'));

      expect(second.id, isNot(first.id));
    });

    test('renaming changes the name and is checked the same way', () async {
      expect(
        ok(await tasks.renameProject(projectId, ' Dissertation ')).name,
        'Dissertation',
      );
      expect(
        errorOf(await tasks.renameProject(projectId, '')),
        const Invalid(InvalidField.projectName, InvalidRule.empty),
      );
    });

    test('renaming a project that is not there says so', () async {
      expect(
        errorOf(await tasks.renameProject(999, 'Ghost')),
        const NotFound(EntityKind.project, 999),
      );
    });

    test('deleting a project deletes its tasks', () async {
      final task = await add('Outline');

      ok(await tasks.deleteProject(projectId));

      expect(await tasks.watchTask(task.id).first, isNull);
      expect(await tasks.watchProjects().first, isEmpty);
    });

    test('deleting a project that is not there says so', () async {
      expect(
        errorOf(await tasks.deleteProject(999)),
        const NotFound(EntityKind.project, 999),
      );
    });
  });

  group('creating a task', () {
    test('it is always to-do, with nothing earned', () async {
      final task = await add('  Outline  ');

      expect(task.title, 'Outline');
      expect(task.projectId, projectId);
      expect(task.status, TaskStatus.todo);
      expect(task.notes, isNull);
      expect(task.estimate, isNull);
      expect(task.actualPomodoros, 0);
      expect(task.cumulativeFocusMinutes, 0);
      expect(task.createdAt, nine);
      expect(task.completedAt, isNull);
    });

    test('notes are trimmed, and blank notes are no notes', () async {
      final withNotes = ok(
        await tasks.createTask(
          projectId: projectId,
          title: 'A',
          notes: '  see ch. 2  ',
        ),
      );
      final blank = ok(
        await tasks.createTask(projectId: projectId, title: 'B', notes: '  '),
      );

      expect(withNotes.notes, 'see ch. 2');
      expect(blank.notes, isNull);
    });

    test('its project must exist', () async {
      expect(
        errorOf(await tasks.createTask(projectId: 999, title: 'Lost')),
        const NotFound(EntityKind.project, 999),
      );
    });

    test('a title must not be empty', () async {
      expect(
        errorOf(await tasks.createTask(projectId: projectId, title: ' ')),
        const Invalid(InvalidField.taskTitle, InvalidRule.empty),
      );
    });

    test('a title may be 200 characters as a reader counts them', () async {
      // A family emoji is one character to a reader and many to a computer.
      const family = '👨‍👩‍👧';
      expect(family.length, greaterThan(1));

      expect(
        ok(await tasks.createTask(projectId: projectId, title: family * 200))
            .title,
        family * 200,
      );
      expect(
        errorOf(
          await tasks.createTask(projectId: projectId, title: family * 201),
        ),
        const Invalid(InvalidField.taskTitle, InvalidRule.tooLong, limit: 200),
      );
    });

    test('notes may be 5,000 characters and no more', () async {
      expect(
        errorOf(
          await tasks.createTask(
            projectId: projectId,
            title: 'A',
            notes: 'n' * 5001,
          ),
        ),
        const Invalid(InvalidField.notes, InvalidRule.tooLong, limit: 5000),
      );
      expect(
        ok(
          await tasks.createTask(
            projectId: projectId,
            title: 'A',
            notes: 'n' * 5000,
          ),
        ).notes,
        hasLength(5000),
      );
    });

    test('planned blocks are 1 to 20; zero is refused', () async {
      expect((await add('One', estimate: 1)).estimate, 1);
      expect((await add('Twenty', estimate: 20)).estimate, 20);
      expect(
        errorOf(
          await tasks.createTask(projectId: projectId, title: 'Z', estimate: 0),
        ),
        const Invalid(InvalidField.estimate, InvalidRule.outOfRange, limit: 1),
      );
      expect(
        errorOf(
          await tasks.createTask(
            projectId: projectId,
            title: 'Z',
            estimate: 21,
          ),
        ),
        const Invalid(InvalidField.estimate, InvalidRule.outOfRange, limit: 20),
      );
    });
  });

  group('updating a task', () {
    test('changes only what the patch names', () async {
      final task = await add('Outline', estimate: 4);

      final updated = ok(
        await tasks.updateTask(task.id, const TaskPatch(title: ' Draft ')),
      );

      expect(updated.title, 'Draft');
      expect(updated.estimate, 4);
      expect(updated.status, TaskStatus.todo);
      expect(updated.projectId, projectId);
    });

    test('notes and planned blocks can be set and cleared', () async {
      final task = await add('Outline', estimate: 4);

      final set = ok(
        await tasks.updateTask(
          task.id,
          const TaskPatch(notes: Edit('ch. 2'), estimate: Edit(6)),
        ),
      );
      final cleared = ok(
        await tasks.updateTask(
          task.id,
          const TaskPatch(notes: Edit('  '), estimate: Edit(null)),
        ),
      );

      expect(set.notes, 'ch. 2');
      expect(set.estimate, 6);
      expect(cleared.notes, isNull);
      expect(cleared.estimate, isNull);
    });

    test('is checked like a new task', () async {
      final task = await add('Outline');

      expect(
        errorOf(await tasks.updateTask(task.id, const TaskPatch(title: ''))),
        const Invalid(InvalidField.taskTitle, InvalidRule.empty),
      );
      expect(
        errorOf(
          await tasks.updateTask(task.id, const TaskPatch(estimate: Edit(0))),
        ),
        const Invalid(InvalidField.estimate, InvalidRule.outOfRange, limit: 1),
      );
      expect((await read(task.id)).title, 'Outline');
    });

    test('a task that is not there says so', () async {
      expect(
        errorOf(await tasks.updateTask(999, const TaskPatch(title: 'Ghost'))),
        const NotFound(EntityKind.task, 999),
      );
    });

    test('can move it to another project that exists', () async {
      final other = ok(await tasks.createProject('Other'));
      final task = await add('Outline');

      expect(
        ok(await tasks.updateTask(task.id, TaskPatch(projectId: other.id)))
            .projectId,
        other.id,
      );
      expect(
        errorOf(
          await tasks.updateTask(task.id, const TaskPatch(projectId: 999)),
        ),
        const NotFound(EntityKind.project, 999),
      );
    });

    test(
      'writing what is already there succeeds and changes nothing',
      () async {
        final task = await add('Outline');

        final again = ok(
          await tasks.updateTask(
            task.id,
            const TaskPatch(title: 'Outline', status: TaskStatus.todo),
          ),
        );

        expect(again, task);
      },
    );

    test(
      'every status change is allowed, to-do straight to done too',
      () async {
        final task = await add('Outline');

        expect((await markDone(task.id)).status, TaskStatus.done);
        expect(
          ok(
            await tasks.updateTask(
              task.id,
              const TaskPatch(status: TaskStatus.doing),
            ),
          ).status,
          TaskStatus.doing,
        );
        expect(
          ok(
            await tasks.updateTask(
              task.id,
              const TaskPatch(status: TaskStatus.todo),
            ),
          ).status,
          TaskStatus.todo,
        );
      },
    );
  });

  group('the completion bonus lives in the status change', () {
    test(
      'marking done pays one EXP per minute the task was focused on',
      () async {
        final task = await add('Outline');
        await finishBlock(task.id);
        await finishBlock(task.id);
        expect(await petExp(), 500);

        final done = await markDone(task.id);

        expect(await petExp(), 550);
        expect(done.status, TaskStatus.done);
        expect(done.completedAt, clock.now);
        expect(done.completionBonusGrantedAt, clock.now);
      },
    );

    test('it is paid once per task, ever', () async {
      final task = await add('Outline');
      await finishBlock(task.id);
      await markDone(task.id);
      final grantedAt = (await read(task.id)).completionBonusGrantedAt;

      ok(
        await tasks.updateTask(
          task.id,
          const TaskPatch(status: TaskStatus.doing),
        ),
      );
      await finishBlock(task.id);
      clock.advance(const Duration(hours: 1));
      await markDone(task.id);

      // 250 + 25 bonus + 250 for the second block, and no second bonus.
      expect(await petExp(), 525);
      expect((await read(task.id)).completionBonusGrantedAt, grantedAt);
    });

    test(
      'a task never focused on pays nothing, and that was its one bonus',
      () async {
        final task = await add('Outline');

        await markDone(task.id);
        expect(await petExp(), 0);

        ok(
          await tasks.updateTask(
            task.id,
            const TaskPatch(status: TaskStatus.doing),
          ),
        );
        await finishBlock(task.id);
        await markDone(task.id);

        expect(await petExp(), 250);
      },
    );

    test(
      'leaving done clears when it was completed, and nothing else',
      () async {
        final task = await add('Outline');
        await finishBlock(task.id);
        final done = await markDone(task.id);

        final reopened = ok(
          await tasks.updateTask(
            task.id,
            const TaskPatch(status: TaskStatus.doing),
          ),
        );

        expect(reopened.completedAt, isNull);
        expect(
          reopened.completionBonusGrantedAt,
          done.completionBonusGrantedAt,
        );
        expect(reopened.actualPomodoros, 1);
        expect(reopened.cumulativeFocusMinutes, 25);
        expect(await petExp(), 275);
      },
    );

    test('marking a done task done again changes nothing', () async {
      final task = await add('Outline');
      await finishBlock(task.id);
      final done = await markDone(task.id);
      clock.advance(const Duration(hours: 2));

      final again = await markDone(task.id);

      expect(again.completedAt, done.completedAt);
      expect(await petExp(), 275);
    });
  });

  group('reopening from the ring', () {
    test('a done task with finished blocks reopens to doing', () async {
      final task = await add('Outline');
      await finishBlock(task.id);
      final done = await markDone(task.id);

      final reopened = ok(
        await tasks.updateTask(task.id, TaskPatch(status: done.reopensTo)),
      );

      expect(reopened.status, TaskStatus.doing);
    });

    test('a done task never focused on reopens to to-do', () async {
      final done = await markDone((await add('Outline')).id);

      final reopened = ok(
        await tasks.updateTask(done.id, TaskPatch(status: done.reopensTo)),
      );

      expect(reopened.status, TaskStatus.todo);
    });
  });

  group('the task lock, while a block is running', () {
    late Task task;

    setUp(() async {
      task = await add('Outline');
      await startBlock(task.id);
      clock.advance(const Duration(minutes: 10));
    });

    test('its task cannot be deleted', () async {
      expect(errorOf(await tasks.deleteTask(task.id)), BlockRunning(task.id));
      expect(await tasks.watchTask(task.id).first, isNotNull);
      expect(await cycleRows(), 1);
    });

    test('its task cannot be marked done', () async {
      expect(
        errorOf(
          await tasks.updateTask(
            task.id,
            const TaskPatch(status: TaskStatus.done),
          ),
        ),
        BlockRunning(task.id),
      );
      expect((await read(task.id)).status, TaskStatus.doing);
    });

    test('its project cannot be deleted', () async {
      expect(
        errorOf(await tasks.deleteProject(projectId)),
        BlockRunning(task.id),
      );
      expect(await tasks.watchProjects().first, hasLength(1));
    });

    test('a refused change changes nothing else in the same patch', () async {
      errorOf(
        await tasks.updateTask(
          task.id,
          const TaskPatch(title: 'Renamed', status: TaskStatus.done),
        ),
      );

      expect((await read(task.id)).title, 'Outline');
    });

    test('its words can still be edited, and it can be moved', () async {
      final other = ok(await tasks.createProject('Other'));

      final edited = ok(
        await tasks.updateTask(
          task.id,
          TaskPatch(
            title: 'Draft',
            notes: const Edit('ch. 2'),
            projectId: other.id,
          ),
        ),
      );

      expect(edited.title, 'Draft');
      expect(edited.projectId, other.id);
      expect((ok(await focus.reconcile())).state, FocusState.focusRunning);
    });

    test('other tasks and projects are not locked', () async {
      final otherProject = ok(await tasks.createProject('Other'));
      final bystander = await add('Bystander', inProject: otherProject.id);

      await markDone(bystander.id);
      ok(await tasks.deleteTask(bystander.id));
      ok(await tasks.deleteProject(otherProject.id));

      expect((ok(await focus.reconcile())).state, FocusState.focusRunning);
    });

    test('the lock lifts the moment the block ends', () async {
      clock.advance(const Duration(minutes: 15));

      ok(await tasks.deleteTask(task.id));

      expect(await tasks.watchTask(task.id).first, isNull);
    });
  });

  group('after the block', () {
    late Task task;

    setUp(() async {
      task = await add('Outline');
      await startBlock(task.id);
      // The block ends, and nothing has looked at it since: still owed.
      clock.advance(const Duration(minutes: 30));
    });

    test('deleting the task settles the block first, then ends the cycle; '
        'the block record stays, unlinked', () async {
      ok(await tasks.deleteTask(task.id));

      expect(await tasks.watchTask(task.id).first, isNull);
      expect(await cycleRows(), 0);
      expect(await petExp(), 250);
      final record = (await records()).single;
      expect(record.taskId, isNull);
      expect(record.projectId, projectId);
      expect(record.minutes, 25);
    });

    test('deleting the project does the same', () async {
      ok(await tasks.deleteProject(projectId));

      expect(await cycleRows(), 0);
      expect(await petExp(), 250);
      final record = (await records()).single;
      expect(record.taskId, isNull);
      expect(record.projectId, isNull);
    });

    test(
      'marking done settles the block first, so the bonus counts it',
      () async {
        final done = await markDone(task.id);

        // 250 for the block, and 25 bonus that includes that block's minutes.
        expect(await petExp(), 275);
        expect(done.actualPomodoros, 1);
        expect(done.cumulativeFocusMinutes, 25);
      },
    );

    test('marking done never ends the cycle: the break can still be taken, '
        'but no block can start on that task', () async {
      await markDone(task.id);

      final standing = ok(await focus.reconcile());
      expect(standing.state, FocusState.focusComplete);
      expect(standing.cycle!.taskId, task.id);

      expect(
        errorOf(
          await focus.startBlock(
            taskId: task.id,
            lengths: BlockLengths.preset25,
            autoStart: false,
          ),
        ),
        TaskDone(task.id),
      );
      expect(ok(await focus.takeBreak()).state, FocusState.breakRunning);
    });

    test('deleting some other task leaves the cycle alone', () async {
      final other = await add('Other');

      ok(await tasks.deleteTask(other.id));

      expect(await cycleRows(), 1);
      expect(ok(await focus.reconcile()).cycle!.taskId, task.id);
    });

    test('edits and moves leave the cycle alone', () async {
      final otherProject = ok(await tasks.createProject('Other'));
      ok(
        await tasks.updateTask(
          task.id,
          TaskPatch(title: 'Draft', projectId: otherProject.id),
        ),
      );

      expect(await cycleRows(), 1);
    });
  });

  test('a database failure comes back as storageFailed, with a diagnostic '
      'entry, and nothing half-written', () async {
    final failing = _FailWrites();
    final broken = openTomoDatabase(
      NativeDatabase.memory().interceptWith(failing),
      clock: clock.call,
      log: Log(sinks: const []),
    );
    addTearDown(broken.close);
    final service = TaskService(broken, log: Log(sinks: [sink]));
    final project = ok(await service.createProject('Thesis'));

    failing.on = true;
    final result = await service.createTask(projectId: project.id, title: 'A');
    failing.on = false;

    expect(errorOf(result), const StorageFailed());
    expect(sink.entries.single.code, DiagnosticCode.taskWriteFailed);
    expect(await service.watchTasksInProject(project.id).first, isEmpty);
  });
}

/// Makes every insert fail while [on], like a full or broken disk.
final class _FailWrites extends QueryInterceptor {
  bool on = false;

  @override
  Future<int> runInsert(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    if (on) throw StateError('disk full');
    return super.runInsert(executor, statement, args);
  }
}

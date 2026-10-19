import 'package:test/test.dart';
import 'package:tomo_core/data/tomo_database.dart';
import 'package:tomo_core/diagnostics/log.dart';
import 'package:tomo_core/focus/block_lengths.dart';
import 'package:tomo_core/focus/focus_cycle_service.dart';
import 'package:tomo_core/pet/species.dart';
import 'package:tomo_core/result.dart';
import 'package:tomo_core/tasks/task.dart';
import 'package:tomo_core/tasks/task_service.dart';
import 'package:tomo_core/tasks/task_status.dart';
import 'package:tomo_core/testing.dart';

/// The four watched reads and their orderings (spec §5.1), and the two read
/// once for the task picker.
void main() {
  late TestClock clock;
  late TomoDatabase db;
  late TaskService tasks;
  late FocusCycleService focus;

  T ok<T>(Result<T> result) => switch (result) {
    Success(:final value) => value,
    Failure(:final error) => fail('expected success, got $error'),
  };

  setUp(() async {
    clock = TestClock(DateTime.utc(2026, 10, 10, 9));
    db = openTestDatabase(clock: clock.call);
    final log = Log(sinks: const []);
    tasks = TaskService(db, log: log, utcOffsetAt: (_) => Duration.zero);
    focus = FocusCycleService(db, log: log, utcOffsetAt: (_) => Duration.zero);
    await db
        .into(db.pets)
        .insert(PetsCompanion.insert(species: Species.geode, createdAt: 0));
  });

  tearDown(() => db.close());

  /// Each thing made a minute after the last, so "most recent" is never a tie.
  Future<Project> project(String name) async {
    clock.advance(const Duration(minutes: 1));
    return ok(await tasks.createProject(name));
  }

  Future<Task> task(Project project, String title) async {
    clock.advance(const Duration(minutes: 1));
    return ok(await tasks.createTask(projectId: project.id, title: title));
  }

  Future<void> setStatus(Task task, TaskStatus status) async {
    clock.advance(const Duration(minutes: 1));
    ok(await tasks.updateTask(task.id, TaskPatch(status: status)));
  }

  Future<void> focusOn(Task task) async {
    clock.advance(const Duration(minutes: 1));
    ok(
      await focus.startBlock(
        taskId: task.id,
        lengths: BlockLengths.preset25,
        autoStart: false,
      ),
    );
    clock.advance(const Duration(minutes: 25));
    ok(await focus.leave());
  }

  Future<List<String>> projectNames() async => [
    for (final p in await tasks.watchProjects().first) p.name,
  ];

  Future<List<String>> titles(Stream<List<Task>> stream) async => [
    for (final t in await stream.first) t.title,
  ];

  group('projects, most recent activity first', () {
    test('a newer project comes before an older one', () async {
      await project('Older');
      await project('Newer');

      expect(await projectNames(), ['Newer', 'Older']);
    });

    test('adding a task brings its project to the top', () async {
      final older = await project('Older');
      await project('Newer');

      await task(older, 'Something');

      expect(await projectNames(), ['Older', 'Newer']);
    });

    test('focusing on a task brings its project to the top', () async {
      final a = await project('A');
      final b = await project('B');
      final inA = await task(a, 'In A');
      await task(b, 'In B');
      expect(await projectNames(), ['B', 'A']);

      await focusOn(inA);

      expect(await projectNames(), ['A', 'B']);
    });

    test('finishing a task brings its project to the top', () async {
      final a = await project('A');
      final b = await project('B');
      final inA = await task(a, 'In A');
      await task(b, 'In B');

      await setStatus(inA, TaskStatus.done);

      expect(await projectNames(), ['A', 'B']);
    });

    test('a project with no tasks is still listed', () async {
      await project('Empty');

      expect(await projectNames(), ['Empty']);
    });
  });

  group("Work's projects, with their open and done tasks counted", () {
    Future<List<(String, int, int)>> summaries() async => [
      for (final s in await tasks.watchProjectSummaries().first)
        (s.project.name, s.open, s.done),
    ];

    test('to-do and doing count as open', () async {
      final p = await project('Thesis');
      final doing = await task(p, 'doing');
      final done = await task(p, 'done');
      await task(p, 'todo');
      await setStatus(doing, TaskStatus.doing);
      await setStatus(done, TaskStatus.done);

      expect(await summaries(), [('Thesis', 2, 1)]);
    });

    test('a project with no tasks counts none', () async {
      await project('Empty');

      expect(await summaries(), [('Empty', 0, 0)]);
    });

    test("only a project's own tasks count", () async {
      final a = await project('A');
      final b = await project('B');
      await task(a, 'in A');
      await setStatus(await task(b, 'in B'), TaskStatus.done);

      expect(await summaries(), [('B', 0, 1), ('A', 1, 0)]);
    });

    test('in the same order as the projects, read once too', () async {
      final older = await project('Older');
      await project('Newer');
      await task(older, 'Something');

      expect(await summaries(), [('Older', 1, 0), ('Newer', 0, 0)]);
      expect(
        [for (final s in await tasks.projectSummaries()) s.project.name],
        await projectNames(),
      );
    });

    test('a change shows at once', () async {
      final p = await project('P');
      final open = await task(p, 'open');
      final seen = tasks.watchProjectSummaries().map(
        (list) => (list.single.open, list.single.done),
      );
      final changes = seen.take(2).toList();
      await Future<void>.delayed(Duration.zero);

      await setStatus(open, TaskStatus.done);

      expect(await changes, [(1, 0), (0, 1)]);
    });
  });

  group("a project's tasks", () {
    test('doing, then to-do, then done', () async {
      final p = await project('P');
      final done = await task(p, 'done');
      final todo = await task(p, 'todo');
      final doing = await task(p, 'doing');
      await setStatus(done, TaskStatus.done);
      await setStatus(doing, TaskStatus.doing);
      expect(todo.status, TaskStatus.todo);

      expect(await titles(tasks.watchTasksInProject(p.id)), [
        'doing',
        'todo',
        'done',
      ]);
    });

    test('within a status, the most recently touched first', () async {
      final p = await project('P');
      final first = await task(p, 'first');
      await task(p, 'second');
      await task(p, 'third');
      expect(await titles(tasks.watchTasksInProject(p.id)), [
        'third',
        'second',
        'first',
      ]);

      // Focused on and then set back to to-do: it is the freshest to-do.
      await focusOn(first);
      await setStatus(first, TaskStatus.todo);

      expect(await titles(tasks.watchTasksInProject(p.id)), [
        'first',
        'third',
        'second',
      ]);
    });

    test("only that project's tasks", () async {
      final p = await project('P');
      final other = await project('Other');
      await task(p, 'mine');
      await task(other, 'theirs');

      expect(await titles(tasks.watchTasksInProject(p.id)), ['mine']);
    });
  });

  group('the task picker', () {
    test('doing before to-do, from every project, and never done', () async {
      final a = await project('A');
      final b = await project('B');
      final todo = await task(a, 'todo in A');
      final doing = await task(b, 'doing in B');
      final done = await task(a, 'done in A');
      await setStatus(doing, TaskStatus.doing);
      await setStatus(done, TaskStatus.done);
      expect(todo.status, TaskStatus.todo);

      expect(await titles(tasks.watchPickerTasks()), [
        'doing in B',
        'todo in A',
      ]);
    });

    test('within a status, the most recently focused first', () async {
      final p = await project('P');
      final early = await task(p, 'focused first');
      final late = await task(p, 'focused last');
      await task(p, 'never focused');
      await focusOn(early);
      await focusOn(late);

      expect(await titles(tasks.watchPickerTasks()), [
        'focused last',
        'focused first',
        'never focused',
      ]);
    });
  });

  group('read once', () {
    test("the picker's tasks, in the order the picker watches", () async {
      final a = await project('A');
      final b = await project('B');
      await task(a, 'todo in A');
      final doing = await task(b, 'doing in B');
      await setStatus(await task(a, 'done in A'), TaskStatus.done);
      await setStatus(doing, TaskStatus.doing);

      expect(
        [for (final t in await tasks.pickerTasks()) t.title],
        ['doing in B', 'todo in A'],
      );
      expect(await tasks.pickerTasks(), await tasks.watchPickerTasks().first);
    });

    test('the projects, the most recently active first', () async {
      final older = await project('Older');
      await project('Newer');
      await task(older, 'Something');

      expect(
        [for (final p in await tasks.projects()) p.name],
        ['Older', 'Newer'],
      );
      expect(await tasks.projects(), await tasks.watchProjects().first);
    });
  });

  group('watching', () {
    test('a watched task changes as it is edited, and ends as null when '
        'deleted', () async {
      final watched = await task(await project('P'), 'Outline');
      final seen = <String?>[];
      final subscription = tasks
          .watchTask(watched.id)
          .listen((t) => seen.add(t?.title));
      addTearDown(subscription.cancel);
      await pumpEventQueue();

      ok(await tasks.updateTask(watched.id, const TaskPatch(title: 'Draft')));
      await pumpEventQueue();
      ok(await tasks.deleteTask(watched.id));
      await pumpEventQueue();

      expect(seen, ['Outline', 'Draft', null]);
    });

    test('the project list follows a new project', () async {
      final seen = <List<String>>[];
      final subscription = tasks.watchProjects().listen(
        (list) => seen.add([for (final p in list) p.name]),
      );
      addTearDown(subscription.cancel);
      await pumpEventQueue();

      await project('First');
      await pumpEventQueue();

      expect(seen, [
        <String>[],
        ['First'],
      ]);
    });
  });

  group("the live cycle's task", () {
    Future<void> startOn(Task task) async => ok(
      await focus.startBlock(
        taskId: task.id,
        lengths: BlockLengths.preset25,
        autoStart: false,
      ),
    );

    test('the task the cycle is on, and its project', () async {
      final thesis = await project('Thesis');
      final outline = await task(thesis, 'Outline');
      await startOn(outline);

      final live = await tasks.cycleTask();

      expect((live?.task.title, live?.project.name), ('Outline', 'Thesis'));
    });

    test('none without a cycle', () async {
      final thesis = await project('Thesis');
      await task(thesis, 'Outline');

      expect(await tasks.cycleTask(), isNull);
    });

    test(
      'watched, it follows a rename, a move and the end of the cycle',
      () async {
        final thesis = await project('Thesis');
        final moving = await project('Moving');
        final outline = await task(thesis, 'Outline');
        final seen = <(String, String)?>[];
        final subscription = tasks.watchCycleTask().listen(
          (live) => seen.add(
            live == null ? null : (live.task.title, live.project.name),
          ),
        );
        addTearDown(subscription.cancel);
        await pumpEventQueue();

        await startOn(outline);
        await pumpEventQueue();
        ok(await tasks.updateTask(outline.id, const TaskPatch(title: 'Draft')));
        await pumpEventQueue();
        ok(await tasks.updateTask(outline.id, TaskPatch(projectId: moving.id)));
        await pumpEventQueue();
        ok(await tasks.renameProject(moving.id, 'Move'));
        await pumpEventQueue();
        clock.advance(const Duration(minutes: 25));
        ok(await focus.leave());
        await pumpEventQueue();

        expect(seen, [
          null,
          ('Outline', 'Thesis'),
          ('Draft', 'Thesis'),
          ('Draft', 'Moving'),
          ('Draft', 'Move'),
          null,
        ]);
      },
    );
  });
}

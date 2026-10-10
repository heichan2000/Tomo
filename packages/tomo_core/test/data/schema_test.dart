import 'package:drift/drift.dart' hide isNull;
import 'package:test/test.dart';
import 'package:tomo_core/data/tomo_database.dart';
import 'package:tomo_core/pet/personality.dart';
import 'package:tomo_core/pet/species.dart';
import 'package:tomo_core/tasks/task_status.dart';
import 'package:tomo_core/testing.dart';

/// What the version-1 schema itself guarantees (spec §6.2), seen through the
/// database every rule will use.
void main() {
  late TomoDatabase db;

  setUp(() => db = openTestDatabase());
  tearDown(() => db.close());

  Future<int> addProject([String name = 'Thesis']) => db
      .into(db.projects)
      .insert(ProjectsCompanion.insert(name: name, createdAt: 1000));

  Future<int> addTask(int projectId, [String title = 'Outline']) => db
      .into(db.tasks)
      .insert(
        TasksCompanion.insert(
          projectId: projectId,
          title: title,
          createdAt: 1000,
        ),
      );

  Future<int> addPet() => db
      .into(db.pets)
      .insert(PetsCompanion.insert(species: Species.joe, createdAt: 1000));

  Future<int> addBlockRecord({
    required int petId,
    int? taskId,
    int? projectId,
  }) => db
      .into(db.blockRecords)
      .insert(
        BlockRecordsCompanion.insert(
          petId: petId,
          taskId: Value(taskId),
          projectId: Value(projectId),
          startedAt: 1000,
          endedAt: 1501000,
          minutes: 25,
          localDate: '2026-10-10',
          utcOffsetMinutes: 480,
          expGranted: 250,
          petExpAfter: 250,
          settledAt: 1501000,
        ),
      );

  Future<int> addCycle(int taskId, {int? id}) => db
      .into(db.focusCycle)
      .insert(
        FocusCycleCompanion.insert(
          id: id == null ? const Value.absent() : Value(id),
          taskId: taskId,
          startAt: 1000,
          endAt: 1501000,
          focusMinutes: 25,
          breakMinutes: 5,
          autoStart: false,
        ),
      );

  Future<List<String>> names(String type) async {
    final rows = await db
        .customSelect(
          'SELECT name FROM sqlite_master WHERE type = ? '
          "AND name NOT LIKE 'sqlite_%' ORDER BY name",
          variables: [Variable.withString(type)],
        )
        .get();
    return [for (final row in rows) row.read<String>('name')];
  }

  test('the five tables and the three indices exist', () async {
    expect(await names('table'), [
      'block_records',
      'focus_cycle',
      'pets',
      'projects',
      'tasks',
    ]);
    expect(await names('index'), [
      'block_records_local_date',
      'block_records_task_id',
      'tasks_project_id_status',
    ]);
  });

  group('defaults', () {
    test('a new task is to-do, with nothing earned and no plan', () async {
      final id = await addTask(await addProject());
      final task = await (db.select(
        db.tasks,
      )..where((t) => t.id.equals(id))).getSingle();

      expect(task.status, TaskStatus.todo);
      expect(task.actualPomodoros, 0);
      expect(task.cumulativeFocusMinutes, 0);
      expect(task.estimatedPomodoros, isNull);
      expect(task.notes, isNull);
      expect(task.estimatePromptedAt, isNull);
      expect(task.completionBonusGrantedAt, isNull);
      expect(task.lastFocusedAt, isNull);
      expect(task.completedAt, isNull);
    });

    test('a new pet is a quiet, unnamed egg with no EXP', () async {
      final id = await addPet();
      final pet = await (db.select(
        db.pets,
      )..where((p) => p.id.equals(id))).getSingle();

      expect(pet.species, Species.joe);
      expect(pet.personality, Personality.quiet);
      expect(pet.name, isNull);
      expect(pet.hatchedAt, isNull);
      expect(pet.exp, 0);
    });

    test('a new cycle is uncredited, with no break and no beat seen', () async {
      await addCycle(await addTask(await addProject()));
      final cycle = await db.select(db.focusCycle).getSingle();

      expect(cycle.id, 1);
      expect(cycle.blockRecordId, isNull);
      expect(cycle.breakStartAt, isNull);
      expect(cycle.breakSkippedAt, isNull);
      expect(cycle.seenAt, isNull);
    });
  });

  test('enums are stored as their names', () async {
    await addTask(await addProject());
    await addPet();

    final task = await db.customSelect('SELECT status FROM tasks').getSingle();
    final pet = await db
        .customSelect('SELECT species, personality FROM pets')
        .getSingle();

    expect(task.read<String>('status'), 'todo');
    expect(pet.read<String>('species'), 'joe');
    expect(pet.read<String>('personality'), 'quiet');
  });

  test('an id is never used twice (ADR-0023)', () async {
    final first = await addProject();
    await db.delete(db.projects).go();
    final second = await addProject();

    expect(second, greaterThan(first));
  });

  group('links between tables', () {
    test('a task cannot point at a project that is not there', () async {
      expect(addTask(999), throwsA(anything));
    });

    test('deleting a project deletes its tasks', () async {
      final keep = await addProject('Keep');
      final drop = await addProject('Drop');
      await addTask(keep, 'Stays');
      await addTask(drop, 'Goes');

      await (db.delete(db.projects)..where((p) => p.id.equals(drop))).go();

      final titles = await db.select(db.tasks).map((t) => t.title).get();
      expect(titles, ['Stays']);
    });

    test(
      'deleting a task keeps its block records, unlinked (ADR-0022)',
      () async {
        final project = await addProject();
        final task = await addTask(project);
        await addBlockRecord(
          petId: await addPet(),
          taskId: task,
          projectId: project,
        );

        await (db.delete(db.tasks)..where((t) => t.id.equals(task))).go();

        final record = await db.select(db.blockRecords).getSingle();
        expect(record.taskId, isNull);
        expect(record.projectId, project);
        expect(record.minutes, 25);
        expect(record.expGranted, 250);
      },
    );

    test(
      'deleting a project keeps its block records, unlinked (ADR-0022)',
      () async {
        final project = await addProject();
        final task = await addTask(project);
        await addBlockRecord(
          petId: await addPet(),
          taskId: task,
          projectId: project,
        );

        await db.delete(db.projects).go();

        final record = await db.select(db.blockRecords).getSingle();
        expect(record.taskId, isNull);
        expect(record.projectId, isNull);
        expect(record.minutes, 25);
      },
    );

    test('a task with a live cycle cannot be deleted', () async {
      final task = await addTask(await addProject());
      await addCycle(task);

      expect(db.delete(db.tasks).go(), throwsA(anything));
    });

    test('a block record needs a pet that exists', () async {
      expect(addBlockRecord(petId: 999), throwsA(anything));
    });
  });

  group('the focus cycle holds at most one row', () {
    test('a second cycle is refused', () async {
      final task = await addTask(await addProject());
      await addCycle(task);

      expect(addCycle(task), throwsA(anything));
    });

    test('a cycle with any id but 1 is refused', () async {
      final task = await addTask(await addProject());

      expect(addCycle(task, id: 2), throwsA(anything));
    });

    test('after the cycle is deleted, the next one takes its place', () async {
      final task = await addTask(await addProject());
      await addCycle(task);
      await db.delete(db.focusCycle).go();

      await addCycle(task);

      expect((await db.select(db.focusCycle).getSingle()).id, 1);
    });
  });
}

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:test/test.dart';
import 'package:tomo_core/data/tomo_database.dart';
import 'package:tomo_core/diagnostics/diagnostic_entry.dart';
import 'package:tomo_core/diagnostics/log.dart';
import 'package:tomo_core/onboarding/onboarding.dart';
import 'package:tomo_core/pet/species.dart';
import 'package:tomo_core/result.dart';
import 'package:tomo_core/tasks/task_status.dart';
import 'package:tomo_core/testing.dart';

/// What finishing onboarding writes (spec §8.2): the pet, the first project,
/// and the first task if one was typed, in one transaction.
void main() {
  final nine = DateTime.utc(2026, 10, 10, 9);

  late RecordingSink sink;
  late TomoDatabase db;
  late Onboarding onboarding;

  setUp(() {
    sink = RecordingSink();
    db = openTestDatabase(clock: TestClock(nine).call);
    onboarding = Onboarding(db, log: Log(sinks: [sink]));
  });

  tearDown(() => db.close());

  Future<Result<void>> finish({
    String? line,
    Species species = Species.geode,
  }) => onboarding.complete(
    species: species,
    line: line,
    defaultProjectName: 'My work',
  );

  test('a new install has not been through onboarding', () async {
    expect(await onboarding.isComplete(), isFalse);
  });

  test('finishing makes the pet: the chosen species, still an egg', () async {
    final result = await finish(line: 'Thesis', species: Species.lily);

    expect(result, isA<Success<void>>());
    expect(await onboarding.isComplete(), isTrue);
    final pet = await db.select(db.pets).getSingle();
    expect(pet.species, Species.lily);
    expect(pet.name, isNull);
    expect(pet.hatchedAt, isNull);
    expect(pet.exp, 0);
    expect(pet.createdAt, nine.millisecondsSinceEpoch);
  });

  test("the typed line names the project and is the first task", () async {
    await finish(line: '  Write my thesis  ');

    final project = await db.select(db.projects).getSingle();
    final task = await db.select(db.tasks).getSingle();
    expect(project.name, 'Write my thesis');
    expect(task.title, 'Write my thesis');
    expect(task.projectId, project.id);
    expect(task.status, TaskStatus.todo);
  });

  test('skipped: one plain default project and no task', () async {
    await finish();

    expect((await db.select(db.projects).getSingle()).name, 'My work');
    expect(await db.select(db.tasks).get(), isEmpty);
    expect(await onboarding.isComplete(), isTrue);
  });

  test('a blank line counts as skipped', () async {
    await finish(line: '   ');

    expect((await db.select(db.projects).getSingle()).name, 'My work');
    expect(await db.select(db.tasks).get(), isEmpty);
  });

  test('a line too long for a project name is refused, and nothing is '
      'written', () async {
    final result = await finish(line: 'n' * 61);

    expect(
      (result as Failure).error,
      const Invalid(InvalidField.projectName, InvalidRule.tooLong, limit: 60),
    );
    expect(await onboarding.isComplete(), isFalse);
    expect(await db.select(db.projects).get(), isEmpty);
  });

  test('finishing twice makes no second pet or project', () async {
    await finish(line: 'Thesis');
    final again = await finish(line: 'Garden', species: Species.joe);

    expect(again, isA<Success<void>>());
    expect((await db.select(db.pets).getSingle()).species, Species.geode);
    expect((await db.select(db.projects).getSingle()).name, 'Thesis');
  });

  test(
    'cut off part-way, nothing is kept and onboarding starts again',
    () async {
      final failing = _FailTaskInsert();
      final broken = openTomoDatabase(
        NativeDatabase.memory().interceptWith(failing),
        clock: TestClock(nine).call,
        log: Log(sinks: const []),
      );
      addTearDown(broken.close);
      final cutOff = Onboarding(broken, log: Log(sinks: [sink]));

      final result = await cutOff.complete(
        species: Species.joe,
        line: 'Thesis',
        defaultProjectName: 'My work',
      );

      expect((result as Failure).error, const StorageFailed());
      expect(sink.entries.single.code, DiagnosticCode.onboardingWriteFailed);
      expect(await cutOff.isComplete(), isFalse);
      expect(await broken.select(broken.pets).get(), isEmpty);
      expect(await broken.select(broken.projects).get(), isEmpty);
    },
  );
}

/// The pet and the project go in; the task, written last, fails.
final class _FailTaskInsert extends QueryInterceptor {
  @override
  Future<int> runInsert(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    if (statement.contains('"tasks"')) throw StateError('killed');
    return super.runInsert(executor, statement, args);
  }
}

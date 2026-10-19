import 'package:drift/drift.dart' show Value;
import 'package:test/test.dart';
import 'package:tomo_core/data/tomo_database.dart';
import 'package:tomo_core/diagnostics/log.dart';
import 'package:tomo_core/focus/block_lengths.dart';
import 'package:tomo_core/focus/focus_cycle_service.dart';
import 'package:tomo_core/pet/beat.dart';
import 'package:tomo_core/pet/pet_look.dart';
import 'package:tomo_core/pet/pet_standing.dart';
import 'package:tomo_core/pet/species.dart';
import 'package:tomo_core/result.dart';
import 'package:tomo_core/testing.dart';

/// The pet as Home sees it (spec §8.3, §7.2): read from the database, with
/// the owed run waiting, so Home never shows what only Focus may reveal.
void main() {
  late TestClock clock;
  late TomoDatabase db;
  late FocusCycleService focus;
  late PetReader reader;
  late int taskId;

  T ok<T>(Result<T> result) => switch (result) {
    Success(:final value) => value,
    Failure(:final error) => fail('expected success, got $error'),
  };

  PetLook lookNow(PetStanding pet, {bool calm = false}) =>
      pet.lookAt(clock.now, calmPet: calm, reduceMotion: false);

  setUp(() async {
    clock = TestClock(DateTime.utc(2026, 10, 10, 9));
    db = openTestDatabase(clock: clock.call);
    focus = FocusCycleService(
      db,
      log: Log(sinks: const []),
      utcOffsetAt: (_) => Duration.zero,
    );
    reader = PetReader(db);
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
  });

  tearDown(() => db.close());

  Future<void> addPet({
    int exp = 0,
    bool hatched = false,
    String? name,
    Species species = Species.joe,
  }) => db
      .into(db.pets)
      .insert(
        PetsCompanion.insert(
          species: species,
          name: Value(name),
          exp: Value(exp),
          hatchedAt: Value(hatched ? 1 : null),
          createdAt: 0,
        ),
      );

  Future<void> start([BlockLengths lengths = BlockLengths.preset25]) async =>
      ok(
        await focus.startBlock(
          taskId: taskId,
          lengths: lengths,
          autoStart: false,
        ),
      );

  test('before onboarding there is no pet', () async {
    expect(await reader.read(), isNull);
  });

  test('a new pet is an egg that waits, wobbling', () async {
    await addPet();

    final pet = (await reader.read())!;
    expect(pet.species, Species.joe);
    expect(pet.name, isNull);
    expect(pet.hatched, isFalse);
    expect(pet.cycle, isNull);
    expect(pet.owedRun, isEmpty);
    expect(
      lookNow(pet),
      isA<EggLook>()
          .having((egg) => egg.picture, 'picture', 0)
          .having((egg) => egg.mayWobble, 'mayWobble', isTrue),
    );
  });

  test('the egg cracks across a running block, and holds still', () async {
    await addPet();
    await start();
    clock.advance(const Duration(minutes: 13));

    final egg = lookNow((await reader.read())!) as EggLook;
    // Joe has six pictures; 13 of 25 minutes is the fourth.
    expect(egg.picture, 3);
    expect(egg.mayWobble, isFalse);
  });

  test('the hatched pet, resting, at its level and stage', () async {
    await addPet(exp: 600 * 12 + 480, hatched: true, name: 'Pip');

    final pet = (await reader.read())!;
    expect(pet.name, 'Pip');
    expect(pet.level, 13);
    expect(
      lookNow(pet),
      isA<HatchedLook>()
          .having((p) => p.stage, 'stage', 2)
          .having((p) => p.face, 'face', Face.resting),
    );
    expect(lookNow(pet, calm: true), isA<HatchedLook>());
    expect((lookNow(pet, calm: true) as HatchedLook).face, Face.still);
  });

  test('a running block shows Pleased; its break, Drowsy', () async {
    await addPet(exp: 600, hatched: true);
    await start();
    expect((lookNow((await reader.read())!) as HatchedLook).face, Face.pleased);

    clock.advance(const Duration(minutes: 25));
    ok(await focus.takeBreak());
    expect((lookNow((await reader.read())!) as HatchedLook).face, Face.drowsy);
  });

  test(
    'a first block finished away keeps the egg until Focus hatches it',
    () async {
      await addPet();
      await start(BlockLengths.firstEver);
      clock.advance(const Duration(minutes: 15));
      ok(await focus.reconcile());

      final pet = (await reader.read())!;
      expect(pet.hatched, isTrue);
      expect(pet.owedRun.whereType<Hatch>(), hasLength(1));
      final egg = lookNow(pet) as EggLook;
      expect(egg.picture, 5);
      expect(egg.mayWobble, isFalse);

      ok(await focus.markBeatRunSeen());
      expect(lookNow((await reader.read())!), isA<HatchedLook>());
    },
  );

  test('an evolution not yet played keeps the old stage', () async {
    // Ten minutes short of level 10, where stage 2 begins.
    await addPet(exp: 600 * 9 - 100, hatched: true);
    await start();
    clock.advance(const Duration(minutes: 25));
    ok(await focus.reconcile());

    final pet = (await reader.read())!;
    expect(pet.level, 10);
    expect((lookNow(pet) as HatchedLook).stage, 1);

    ok(await focus.markBeatRunSeen());
    expect((lookNow((await reader.read())!) as HatchedLook).stage, 2);
  });

  group('when the look next changes by the clock', () {
    test('never, with no cycle', () async {
      await addPet();
      expect((await reader.read())!.nextChangeAfter(clock.now), isNull);
    });

    test('each whole minute of a running block', () async {
      await addPet();
      await start();
      final startAt = clock.now;
      clock.advance(const Duration(minutes: 3, seconds: 20));

      expect(
        (await reader.read())!.nextChangeAfter(clock.now),
        startAt.add(const Duration(minutes: 4)),
      );
    });

    test('at the end of a running break', () async {
      await addPet(hatched: true);
      await start();
      clock.advance(const Duration(minutes: 25));
      ok(await focus.takeBreak());
      final breakAt = clock.now;
      clock.advance(const Duration(minutes: 2));

      expect(
        (await reader.read())!.nextChangeAfter(clock.now),
        breakAt.add(const Duration(minutes: 5)),
      );
    });
  });

  test('watching gives the pet again after each change', () async {
    final seen = <PetStanding?>[];
    final watching = reader.watch().listen(seen.add);
    await pumpEventQueue();
    expect(seen, [isNull]);

    await addPet();
    await pumpEventQueue();
    expect(seen.last?.species, Species.joe);

    await start();
    await pumpEventQueue();
    expect(seen.last?.cycle, isNotNull);

    await watching.cancel();
  });
}

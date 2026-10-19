import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:test/test.dart';
import 'package:tomo_core/data/tomo_database.dart';
import 'package:tomo_core/diagnostics/diagnostic_entry.dart';
import 'package:tomo_core/diagnostics/log.dart';
import 'package:tomo_core/onboarding/onboarding.dart';
import 'package:tomo_core/pet/personality.dart';
import 'package:tomo_core/pet/pet_service.dart';
import 'package:tomo_core/pet/species.dart';
import 'package:tomo_core/result.dart';
import 'package:tomo_core/testing.dart';

/// Naming the pet (spec §8.7): the hatch's *Done*, and later Settings →
/// *Rename pet*.
void main() {
  final nine = DateTime.utc(2026, 10, 10, 9);

  late RecordingSink sink;
  late TomoDatabase db;
  late PetService pets;
  late int writes;

  Future<void> hatchedGeode(TomoDatabase db) async {
    await Onboarding(db, log: Log(sinks: const [])).complete(
      species: Species.geode,
      personality: Personality.quiet,
      defaultProjectName: 'My work',
    );
  }

  setUp(() async {
    sink = RecordingSink();
    writes = 0;
    db = openTestDatabase(clock: TestClock(nine).call);
    pets = PetService(
      db,
      log: Log(sinks: [sink]),
      afterWrite: () async => writes++,
    );
    await hatchedGeode(db);
  });

  tearDown(() => db.close());

  Future<String?> storedName() async =>
      (await db.select(db.pets).getSingle()).name;

  test('naming stores the name, trimmed', () async {
    final result = await pets.rename('  Pebble ');

    expect((result as Success<String>).value, 'Pebble');
    expect(await storedName(), 'Pebble');
  });

  test('the species name is a name like any other', () async {
    await pets.rename('Geode');

    expect(await storedName(), 'Geode');
  });

  test('a blank name is refused and the old one stays', () async {
    await pets.rename('Pebble');

    final result = await pets.rename('   ');

    expect(
      (result as Failure).error,
      const Invalid(InvalidField.petName, InvalidRule.empty),
    );
    expect(await storedName(), 'Pebble');
  });

  test('a name is at most $maxPetNameLength characters as a reader counts '
      'them', () async {
    final longest = 'é' * maxPetNameLength;
    expect(await pets.rename(longest), isA<Success<String>>());

    final result = await pets.rename('${longest}x');

    expect(
      (result as Failure).error,
      const Invalid(
        InvalidField.petName,
        InvalidRule.tooLong,
        limit: maxPetNameLength,
      ),
    );
    expect(await storedName(), longest);
  });

  test('a name counts emoji as one character each', () async {
    final result = await pets.rename('🐣' * maxPetNameLength);

    expect(result, isA<Success<String>>());
  });

  test('the notifications are brought up to date after a write', () async {
    await pets.rename('Pebble');
    await pumpEventQueue();
    expect(writes, 1);

    await pets.rename('');
    await pumpEventQueue();
    expect(writes, 1, reason: 'a refused write changes nothing');
  });

  test('a failed write is recorded and changes nothing', () async {
    final broken = openTomoDatabase(
      NativeDatabase.memory().interceptWith(_FailUpdates()),
      clock: TestClock(nine).call,
      log: Log(sinks: const []),
    );
    addTearDown(broken.close);
    await hatchedGeode(broken);

    final result = await PetService(
      broken,
      log: Log(sinks: [sink]),
    ).rename('Pebble');

    expect((result as Failure).error, const StorageFailed());
    expect(sink.entries.single.code, DiagnosticCode.petWriteFailed);
    expect((await broken.select(broken.pets).getSingle()).name, isNull);
  });
}

final class _FailUpdates extends QueryInterceptor {
  @override
  Future<int> runUpdate(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) => throw StateError('killed');
}

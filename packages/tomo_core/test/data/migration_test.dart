import 'dart:io';

import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';
import 'package:tomo_core/clock.dart';
import 'package:tomo_core/data/tomo_database.dart';
import 'package:tomo_core/diagnostics/diagnostic_entry.dart';
import 'package:tomo_core/diagnostics/log.dart';
import 'package:tomo_core/testing.dart';

import 'tomo/generated/schema.dart';

/// Promise 24: every committed schema upgrades cleanly, and a failed migration
/// never wipes (spec §6.2).
void main() {
  group('committed schemas', () {
    late SchemaVerifier verifier;

    setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

    test(
      'a new database is exactly the committed version-1 snapshot',
      () async {
        // If this fails, a table changed without a new schema version. Bump
        // schemaVersion, run `dart run drift_dev make-migrations`, write the
        // step.
        // An empty database, so the tables are created by today's code and
        // then compared with the snapshot.
        final db = openTestDatabase();
        addTearDown(db.close);

        await verifier.migrateAndValidate(db, 1);
      },
    );
  });

  group('starting', () {
    test('a new database starts ready', () async {
      final db = openTestDatabase();
      addTearDown(db.close);

      expect(await db.start(), StorageStart.ready);
      expect(await db.select(db.projects).get(), isEmpty);
    });

    group('a file written by a newer Tomo', () {
      late Directory dir;
      late File file;

      setUp(() {
        dir = Directory.systemTemp.createTempSync('tomo_migration_test');
        file = File('${dir.path}/tomo.sqlite');
        // What a later version might leave behind: a table this app has
        // never heard of, holding the user's data, at schema version 2.
        sqlite3.open(file.path)
          ..execute('CREATE TABLE from_the_future (words TEXT NOT NULL)')
          ..execute("INSERT INTO from_the_future VALUES ('my pet')")
          ..execute('PRAGMA user_version = 2')
          ..close();
      });

      tearDown(() => dir.deleteSync(recursive: true));

      test('is refused, recorded, and left exactly as it was', () async {
        final before = file.readAsBytesSync();
        final sink = RecordingSink();
        final db = openTomoDatabase(
          NativeDatabase(file),
          clock: systemClock,
          log: Log(sinks: [sink]),
        );

        expect(await db.start(), StorageStart.failed);

        final entry = sink.entries.single;
        expect(entry.code, DiagnosticCode.storageStartFailed);
        expect(entry.level, DiagnosticLevel.error);
        expect(entry.errorType, 'DatabaseNewerThanApp');

        expect(file.readAsBytesSync(), before);
        final raw = sqlite3.open(file.path);
        addTearDown(raw.close);
        expect(raw.select('PRAGMA user_version').single.values, [2]);
        expect(raw.select('SELECT words FROM from_the_future').single.values, [
          'my pet',
        ]);
      });
    });
  });
}

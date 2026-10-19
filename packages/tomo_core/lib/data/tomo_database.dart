import 'package:drift/drift.dart';

import '../clock.dart';
import '../diagnostics/diagnostic_entry.dart';
import '../diagnostics/log.dart';
import '../pet/species.dart';
import '../tasks/task_status.dart';
import 'tables.dart';
import 'tomo_database.steps.dart';

// The app builds the file's executor and hands it to [openTomoDatabase].
export 'package:drift/drift.dart' show QueryExecutor;

part 'tomo_database.g.dart';

/// Builds Tomo's one database on [executor]: a file on the phone, or
/// `NativeDatabase.memory()` in tests. Both get the same set-up and the same
/// migrations, because both come through here (spec §6.2).
///
/// Nothing is read or written until the first query, or [TomoDatabase.start].
TomoDatabase openTomoDatabase(
  QueryExecutor executor, {
  required Clock clock,
  required Log log,
}) => TomoDatabase._(executor, clock: clock, log: log);

/// Whether the database could be opened.
enum StorageStart {
  /// Open, at this app's schema version.
  ready,

  /// The file could not be brought to this app's schema version. It has been
  /// left exactly as it was, and a diagnostic entry was written. Show the
  /// error block; do not use the database.
  failed,
}

/// Thrown when the file was written by a newer Tomo than this one.
final class DatabaseNewerThanApp implements Exception {
  const DatabaseNewerThanApp();
}

@DriftDatabase(tables: [Projects, Tasks, Pets, BlockRecords, FocusCycle])
class TomoDatabase extends _$TomoDatabase {
  TomoDatabase._(super.e, {required this.clock, required this._log});

  /// The one clock every rule built on this database reads.
  final Clock clock;
  final Log _log;

  /// Version 1 is the first, so there are no migration steps yet. When the
  /// schema changes: bump this, run `dart run drift_dev make-migrations` in
  /// this package, and fill in the step it adds to `stepByStep` (spec §6.2).
  @override
  int get schemaVersion => 1;

  /// Opens the file and runs any migrations now, so a failure is met at
  /// start-up and not in the middle of a tap.
  ///
  /// **A failed migration never wipes** (spec §6.2): every step runs inside one
  /// transaction, so a failure leaves the file as it was.
  Future<StorageStart> start() async {
    try {
      await customSelect('SELECT 1').get();
      return StorageStart.ready;
    } catch (error, stackTrace) {
      _log.error(DiagnosticCode.storageStartFailed, error, stackTrace);
      await close();
      return StorageStart.failed;
    }
  }

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
      // Drift would otherwise stamp a newer file with this older version.
      if (from > to) throw const DatabaseNewerThanApp();
      // One transaction: a step that fails leaves the file as it was.
      await transaction(() => stepByStep()(migrator, from, to));
    },
    beforeOpen: (details) async {
      // SQLite leaves foreign keys off unless asked, on every connection.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}

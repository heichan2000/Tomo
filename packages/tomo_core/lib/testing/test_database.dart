import 'package:drift/native.dart';

import '../clock.dart';
import '../data/tomo_database.dart';
import '../diagnostics/log.dart';

/// Tomo's database, in memory, built by the same [openTomoDatabase] the app
/// uses: the same set-up, the same migrations.
///
/// Without a [clock] it reads the system clock; without a [log] it records
/// nowhere. Close it when the test ends.
TomoDatabase openTestDatabase({Clock? clock, Log? log}) => openTomoDatabase(
  NativeDatabase.memory(),
  clock: clock ?? systemClock,
  log: log ?? Log(sinks: const []),
);

/// A database in memory that a newer Tomo wrote: its [TomoDatabase.start]
/// reports [StorageStart.failed], as on a phone holding a newer app's file.
TomoDatabase openNewerTestDatabase({Clock? clock, Log? log}) =>
    openTomoDatabase(
      NativeDatabase.memory(
        setup: (raw) => raw.execute('PRAGMA user_version = 99'),
      ),
      clock: clock ?? systemClock,
      log: log ?? Log(sinks: const []),
    );

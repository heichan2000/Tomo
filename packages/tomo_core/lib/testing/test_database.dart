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

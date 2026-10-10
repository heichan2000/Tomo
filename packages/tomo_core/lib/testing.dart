/// Test helpers shared by `tomo_core`'s tests and the app's (spec §15.4).
///
/// Nothing in the app's `lib/` imports this, so a release build drops it.
library;

export 'testing/memory_stores.dart';
export 'testing/recording_sink.dart';
export 'testing/test_clock.dart';
export 'testing/test_database.dart';

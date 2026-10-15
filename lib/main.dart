import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tomo_core/clock.dart';
import 'package:tomo_core/data/tomo_database.dart';
import 'package:tomo_core/diagnostics/console_sink.dart';
import 'package:tomo_core/diagnostics/diagnostic_entry.dart';
import 'package:tomo_core/diagnostics/diagnostic_log.dart';
import 'package:tomo_core/diagnostics/log.dart';

import 'app/error_block.dart';
import 'app/error_handlers.dart';
import 'app/start_up.dart';
import 'app/tomo_app.dart';
import 'platform/device_facts.dart';
import 'platform/diagnostic_log_file.dart';
import 'platform/stores.dart';
import 'ui/font_licence.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Errors always go to the diagnostic log. Debug builds also print every
  // entry to the console; release builds print nothing (ADR-0004).
  final diagnostics = DiagnosticLog(
    FileDiagnosticLogStorage(getApplicationSupportDirectory),
    facts: readDeviceFacts,
  );
  final log = Log(sinks: [diagnostics, if (kDebugMode) const ConsoleSink()]);
  installErrorHandlers(log);
  installErrorBlock();
  log.info(DiagnosticCode.appStarted);
  registerFontLicence();

  // The splash screen stays up while this runs.
  final start = await startTomo(
    database: openTomoDatabase(
      databaseFile(getApplicationSupportDirectory),
      clock: systemClock,
      log: log,
    ),
    keyValues: SharedPreferencesStore(),
    deviceFile: DeviceFile(getApplicationSupportDirectory),
    log: log,
    diagnostics: diagnostics,
  );

  runApp(switch (start) {
    Started(:final overrides, :final first) => ProviderScope(
      overrides: overrides,
      child: TomoApp(first: first),
    ),
    StartFailed(:final appearance) => StartFailedApp(appearance: appearance),
  });
}

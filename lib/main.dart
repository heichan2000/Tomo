import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tomo_core/diagnostics/console_sink.dart';
import 'package:tomo_core/diagnostics/diagnostic_entry.dart';
import 'package:tomo_core/diagnostics/diagnostic_log.dart';
import 'package:tomo_core/diagnostics/log.dart';

import 'app/error_handlers.dart';
import 'app/tomo_app.dart';
import 'platform/device_facts.dart';
import 'platform/diagnostic_log_file.dart';
import 'ui/font_licence.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Errors always go to the diagnostic log. Debug builds also print every
  // entry to the console; release builds print nothing (ADR-0004).
  final diagnostics = DiagnosticLog(
    FileDiagnosticLogStorage(getApplicationSupportDirectory),
    facts: readDeviceFacts,
  );
  final log = Log(sinks: [diagnostics, if (kDebugMode) const ConsoleSink()]);
  installErrorHandlers(log);
  log.info(DiagnosticCode.appStarted);
  registerFontLicence();

  runApp(const ProviderScope(child: TomoApp()));
}

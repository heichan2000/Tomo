import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tomo_core/diagnostics/console_sink.dart';
import 'package:tomo_core/diagnostics/diagnostic_entry.dart';
import 'package:tomo_core/diagnostics/log.dart';

import 'app/tomo_app.dart';

void main() {
  // Debug builds print diagnostic entries to the console; release builds
  // print nothing (ADR-0004).
  final log = Log(sinks: [if (kDebugMode) const ConsoleSink()]);
  log.info(DiagnosticCode.appStarted);

  runApp(const ProviderScope(child: TomoApp()));
}

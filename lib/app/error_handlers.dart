import 'package:flutter/foundation.dart';
import 'package:tomo_core/diagnostics/diagnostic_entry.dart';
import 'package:tomo_core/diagnostics/log.dart';

/// Sends every error nothing else caught to [log] (spec §13, ADR-0004).
///
/// An uncaught Dart error in a release build does not close the app: it
/// leaves a broken patch of screen and no trace. These two hooks are the only
/// place such an error can be recorded.
void installErrorHandlers(Log log) {
  FlutterError.onError = (details) {
    log.error(
      DiagnosticCode.uncaughtFlutterError,
      details.exception,
      details.stack ?? StackTrace.empty,
    );
    // In debug, Flutter's own red-screen report still reaches the console.
    if (kDebugMode) FlutterError.presentError(details);
  };
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    log.error(DiagnosticCode.uncaughtPlatformError, error, stackTrace);
    return true;
  };
}

/// Why a diagnostic entry was written. Tomo writes these names itself, one per
/// place it expects something to be worth recording.
enum DiagnosticCode {
  /// The app started. Console only.
  appStarted,

  /// The database could not be opened or brought to this version (spec §6.2).
  storageStartFailed,

  /// A focus-cycle write failed and was rolled back (spec §4.5).
  focusWriteFailed,

  /// A task or project write failed and was rolled back (spec §5.2).
  taskWriteFailed,

  /// Finishing onboarding failed and was rolled back (spec §8.2).
  onboardingWriteFailed,

  /// An error Flutter caught while building, laying out or painting.
  uncaughtFlutterError,

  /// An error nothing caught, outside Flutter's own callbacks.
  uncaughtPlatformError,

  /// An error no other code names: something Tomo did not see coming.
  unanticipated,
}

/// How much an entry matters. Only [error] entries are kept in the diagnostic
/// log; the rest are console logging.
enum EntryLevel { info, error }

/// One record the `Log` facade can emit, and the only thing it can emit
/// (ADR-0004, spec §13).
///
/// It is **allowlisted by construction**: there is no field that can hold
/// message text, an exception's `toString()` or anything the user typed, so
/// none of those can reach the console or the diagnostic log. An error
/// contributes its type name and its stack trace, nothing else.
final class DiagnosticEntry {
  final DiagnosticCode code;
  final EntryLevel level;

  /// The moment it happened, in UTC.
  final DateTime at;

  /// The error's type name, such as `StateError`. Null for an info entry.
  final String? errorType;

  /// Where the error was thrown. Null for an info entry.
  final StackTrace? stackTrace;

  DiagnosticEntry.info(this.code, {required DateTime at})
    : level = EntryLevel.info,
      at = at.toUtc(),
      errorType = null,
      stackTrace = null;

  /// Records that [error] was thrown at [stackTrace]. Only the error's type
  /// name is kept; its message is dropped here, on purpose.
  DiagnosticEntry.error(
    this.code,
    Object error,
    StackTrace this.stackTrace, {
    required DateTime at,
  }) : level = EntryLevel.error,
       at = at.toUtc(),
       errorType = error.runtimeType.toString();
}

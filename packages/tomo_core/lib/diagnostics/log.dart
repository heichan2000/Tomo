import 'diagnostic_entry.dart';

/// Somewhere a diagnostic entry goes: the debug console, or the diagnostic log.
abstract interface class DiagnosticSink {
  void record(DiagnosticEntry entry);
}

/// The only way Tomo emits anything about itself (ADR-0004, spec §13).
///
/// It takes a [DiagnosticCode] and, for an error, the error and its stack
/// trace. It builds a [DiagnosticEntry] from them and hands it to every sink.
/// `print` and `debugPrint` are banned everywhere else by `tomo_lints`.
final class Log {
  final List<DiagnosticSink> _sinks;
  final DateTime Function() _now;

  Log({required Iterable<DiagnosticSink> sinks, DateTime Function()? now})
    : _sinks = List.unmodifiable(sinks),
      _now = now ?? DateTime.now;

  void info(DiagnosticCode code) =>
      _emit(DiagnosticEntry.info(code, at: _now()));

  void error(DiagnosticCode code, Object error, StackTrace stackTrace) =>
      _emit(DiagnosticEntry.error(code, error, stackTrace, at: _now()));

  void _emit(DiagnosticEntry entry) {
    for (final sink in _sinks) {
      try {
        sink.record(entry);
      } catch (_) {
        // Recording an error must never cause one (ADR-0004).
      }
    }
  }
}

import '../diagnostics/diagnostic_entry.dart';
import '../diagnostics/log.dart';

/// A sink that keeps every entry, so a test can ask what was recorded.
final class RecordingSink implements DiagnosticSink {
  final entries = <DiagnosticEntry>[];

  @override
  void record(DiagnosticEntry entry) => entries.add(entry);
}

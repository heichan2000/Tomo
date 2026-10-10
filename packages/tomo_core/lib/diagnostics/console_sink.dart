import 'diagnostic_entry.dart';
import 'log.dart';

/// Console logging: prints each entry to the device console. Debug builds
/// only; nothing here is kept (ADR-0004).
///
/// This is the one library where `print` is allowed. `tomo_lints` names it.
final class ConsoleSink implements DiagnosticSink {
  const ConsoleSink();

  @override
  void record(DiagnosticEntry entry) {
    // ignore: avoid_print
    print(consoleLines(entry).join('\n'));
  }

  /// What [record] prints for [entry], one line per item.
  static List<String> consoleLines(DiagnosticEntry entry) => [
    [
      entry.at.toIso8601String(),
      entry.level.name,
      entry.code.name,
      ?entry.errorType,
    ].join(' '),
    ?entry.stackTrace?.toString().trimRight(),
  ];
}

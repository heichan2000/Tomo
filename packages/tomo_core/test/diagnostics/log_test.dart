import 'package:test/test.dart';
import 'package:tomo_core/diagnostics/console_sink.dart';
import 'package:tomo_core/diagnostics/diagnostic_entry.dart';
import 'package:tomo_core/diagnostics/log.dart';

final class _Recorder implements DiagnosticSink {
  final entries = <DiagnosticEntry>[];

  @override
  void record(DiagnosticEntry entry) => entries.add(entry);
}

final class _BrokenSink implements DiagnosticSink {
  @override
  void record(DiagnosticEntry entry) => throw StateError('disk full');
}

void main() {
  final noon = DateTime.utc(2026, 10, 10, 12);

  group('Log', () {
    test('an info entry carries its code and the time, and no error', () {
      final sink = _Recorder();
      Log(sinks: [sink], now: () => noon).info(DiagnosticCode.appStarted);

      final entry = sink.entries.single;
      expect(entry.code, DiagnosticCode.appStarted);
      expect(entry.level, EntryLevel.info);
      expect(entry.at, noon);
      expect(entry.errorType, isNull);
      expect(entry.stackTrace, isNull);
    });

    test('an error entry keeps the type name and the stack trace', () {
      final sink = _Recorder();
      final stack = StackTrace.current;
      Log(
        sinks: [sink],
        now: () => noon,
      ).error(DiagnosticCode.unanticipated, StateError('boom'), stack);

      final entry = sink.entries.single;
      expect(entry.level, EntryLevel.error);
      expect(entry.errorType, 'StateError');
      expect(entry.stackTrace, same(stack));
    });

    test('every sink gets the entry', () {
      final first = _Recorder();
      final second = _Recorder();
      Log(sinks: [first, second]).info(DiagnosticCode.appStarted);

      expect(first.entries, hasLength(1));
      expect(second.entries, hasLength(1));
    });

    test('a sink that throws stops nothing', () {
      final after = _Recorder();
      final log = Log(sinks: [_BrokenSink(), after]);

      expect(() => log.info(DiagnosticCode.appStarted), returnsNormally);
      expect(after.entries, hasLength(1));
    });

    test('the time is stored in UTC', () {
      final sink = _Recorder();
      final local = DateTime(2026, 10, 10, 12);
      Log(sinks: [sink], now: () => local).info(DiagnosticCode.appStarted);

      expect(sink.entries.single.at.isUtc, isTrue);
      expect(sink.entries.single.at, local.toUtc());
    });
  });

  group('ConsoleSink', () {
    test('an error prints its type and stack, never its message', () {
      final lines = ConsoleSink.consoleLines(
        DiagnosticEntry.error(
          DiagnosticCode.unanticipated,
          StateError('the secret task title'),
          StackTrace.fromString('#0 settle (focus.dart:6)\n'),
          at: noon,
        ),
      );

      expect(lines, [
        '2026-10-10T12:00:00.000Z error unanticipated StateError',
        '#0 settle (focus.dart:6)',
      ]);
    });

    test('an info entry prints one line', () {
      final lines = ConsoleSink.consoleLines(
        DiagnosticEntry.info(DiagnosticCode.appStarted, at: noon),
      );

      expect(lines, ['2026-10-10T12:00:00.000Z info appStarted']);
    });
  });
}

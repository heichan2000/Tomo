import 'dart:ui' show ErrorCallback, PlatformDispatcher;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tomo/app/error_handlers.dart';
import 'package:tomo_core/diagnostics/diagnostic_entry.dart';
import 'package:tomo_core/diagnostics/log.dart';
import 'package:tomo_core/testing.dart';

/// Both of Flutter's last-resort error hooks record to the log (spec §13).
void main() {
  late RecordingSink sink;
  late FlutterExceptionHandler? flutterBefore;
  late ErrorCallback? platformBefore;

  setUp(() {
    sink = RecordingSink();
    flutterBefore = FlutterError.onError;
    platformBefore = PlatformDispatcher.instance.onError;
    installErrorHandlers(Log(sinks: [sink]));
  });

  tearDown(() {
    FlutterError.onError = flutterBefore;
    PlatformDispatcher.instance.onError = platformBefore;
  });

  test('an error Flutter caught is recorded, by type and stack only', () {
    final stack = StackTrace.current;
    final handler = FlutterError.onError!;
    // Presenting the error is Flutter's debug-console report; silence it here.
    final presentBefore = FlutterError.presentError;
    FlutterError.presentError = (_) {};
    addTearDown(() => FlutterError.presentError = presentBefore);

    handler(
      FlutterErrorDetails(exception: StateError('private words'), stack: stack),
    );

    final entry = sink.entries.single;
    expect(entry.code, DiagnosticCode.uncaughtFlutterError);
    expect(entry.level, EntryLevel.error);
    expect(entry.errorType, 'StateError');
    expect(entry.stackTrace, same(stack));
  });

  test('an error nothing caught is recorded, and counts as handled', () {
    final stack = StackTrace.current;

    final handled = PlatformDispatcher.instance.onError!(
      const FormatException('private words'),
      stack,
    );

    expect(handled, isTrue);
    final entry = sink.entries.single;
    expect(entry.code, DiagnosticCode.uncaughtPlatformError);
    expect(entry.errorType, 'FormatException');
    expect(entry.stackTrace, same(stack));
  });

  test('an error with no stack is still recorded', () {
    final presentBefore = FlutterError.presentError;
    FlutterError.presentError = (_) {};
    addTearDown(() => FlutterError.presentError = presentBefore);

    FlutterError.onError!(FlutterErrorDetails(exception: StateError('')));

    expect(sink.entries.single.errorType, 'StateError');
  });
}

import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:tomo_core/diagnostics/diagnostic_entry.dart';
import 'package:tomo_core/diagnostics/diagnostic_log.dart';
import 'package:tomo_core/diagnostics/log.dart';
import 'package:tomo_core/testing.dart';

/// The diagnostic log (spec §13, ADR-0004): a capped, plain record of errors
/// outside the database, that can never be the cause of one. Promise 25.
void main() {
  const facts = DeviceFacts(
    appVersion: '1.0.0',
    buildNumber: '1',
    osVersion: 'Android 16',
    deviceClass: DeviceClass.phone,
    locale: 'en-US',
  );
  final noon = DateTime.utc(2026, 10, 10, 12);

  late MemoryDiagnosticLogStorage storage;
  late DiagnosticLog diagnostics;
  late Log log;
  late DateTime now;

  DiagnosticLog logOn(MemoryDiagnosticLogStorage on) =>
      DiagnosticLog(on, facts: () async => facts);

  setUp(() {
    storage = MemoryDiagnosticLogStorage();
    diagnostics = logOn(storage);
    now = noon;
    log = Log(sinks: [diagnostics], now: () => now);
  });

  StackTrace stack(int frames, [String function = 'settle']) =>
      StackTrace.fromString(
        [for (var i = 0; i < frames; i++) '#$i      $function (focus.dart:$i)']
            .join('\n'),
      );

  Future<void> recordErrors(int count, {int frames = 3}) async {
    for (var i = 0; i < count; i++) {
      now = noon.add(Duration(seconds: i));
      log.error(DiagnosticCode.unanticipated, StateError('n$i'), stack(frames));
    }
    await diagnostics.settled;
  }

  test('a new log is empty', () async {
    expect(await diagnostics.count(), 0);
  });

  test('an error is kept', () async {
    log.error(DiagnosticCode.focusWriteFailed, StateError('boom'), stack(2));
    await diagnostics.settled;

    expect(await diagnostics.count(), 1);
  });

  test(
    'only errors are kept: console logging is not the diagnostic log',
    () async {
      log.info(DiagnosticCode.appStarted);
      await diagnostics.settled;

      expect(await diagnostics.count(), 0);
      expect(storage.contents, isNull);
    },
  );

  group('what the shared text holds', () {
    test('the time, the code, the type, the phone and the stack', () async {
      log.error(
        DiagnosticCode.focusWriteFailed,
        const FormatException('whatever'),
        stack(2),
      );
      await diagnostics.settled;

      final text = await diagnostics.exportText();

      expect(text, contains('2026-10-10T12:00:00.000Z'));
      expect(text, contains('focusWriteFailed'));
      expect(text, contains('FormatException'));
      expect(text, contains('1.0.0'));
      expect(text, contains('Android 16'));
      expect(text, contains('phone'));
      expect(text, contains('en-US'));
      expect(text, contains('#0      settle (focus.dart:0)'));
      expect(text, contains('#1      settle (focus.dart:1)'));
    });

    test("never an error's message, however it was thrown", () async {
      log.error(
        DiagnosticCode.taskWriteFailed,
        StateError('my secret task title'),
        stack(1),
      );
      log.error(
        DiagnosticCode.taskWriteFailed,
        const FormatException('another private note', 'private source'),
        stack(1),
      );
      await diagnostics.settled;

      final text = await diagnostics.exportText();

      expect(text, isNot(contains('secret')));
      expect(text, isNot(contains('private')));
      expect(storage.contents, isNot(contains('secret')));
      expect(storage.contents, isNot(contains('private')));
    });

    test('says how many entries it holds, oldest first', () async {
      await recordErrors(3);

      final text = await diagnostics.exportText();

      expect(text, contains('3 entries'));
      expect(
        text.indexOf('2026-10-10T12:00:00.000Z'),
        lessThan(text.indexOf('2026-10-10T12:00:02.000Z')),
      );
    });
  });

  group('it is capped', () {
    test('at 200 entries: the oldest go first', () async {
      await recordErrors(205);

      expect(await diagnostics.count(), 200);
      final text = await diagnostics.exportText();
      // Entries 0 to 4 are gone; entry 5 is now the oldest.
      expect(text, isNot(contains('2026-10-10T12:00:04.000Z')));
      expect(text, contains('2026-10-10T12:00:05.000Z'));
      expect(text, contains('2026-10-10T12:03:24.000Z'));
    });

    test('and under a byte ceiling, whatever the entries weigh', () async {
      final small = DiagnosticLog(
        storage,
        facts: () async => facts,
        maxBytes: 4000,
      );
      final smallLog = Log(sinks: [small], now: () => now);
      for (var i = 0; i < 50; i++) {
        now = noon.add(Duration(seconds: i));
        smallLog.error(DiagnosticCode.unanticipated, StateError(''), stack(10));
      }
      await small.settled;

      expect(utf8.encode(storage.contents!).length, lessThanOrEqualTo(4000));
      expect(await small.count(), inInclusiveRange(1, 49));
      // The newest is always there.
      expect(await small.exportText(), contains('2026-10-10T12:00:49.000Z'));
    });

    test('a stack trace keeps only its first 30 frames', () async {
      log.error(DiagnosticCode.unanticipated, StateError(''), stack(100));
      await diagnostics.settled;

      final text = await diagnostics.exportText();

      expect(text, contains('#29 '));
      expect(text, isNot(contains('#30 ')));
    });
  });

  test(
    'it outlives the process: a new log over the same file carries on',
    () async {
      await recordErrors(2);

      final afterRestart = logOn(storage);
      Log(
        sinks: [afterRestart],
        now: () => noon.add(const Duration(hours: 1)),
      ).error(DiagnosticCode.unanticipated, StateError(''), stack(1));
      await afterRestart.settled;

      expect(await afterRestart.count(), 3);
    },
  );

  group('it can never be the cause of an error', () {
    test('a file that cannot be written is swallowed', () async {
      storage.failWrites = true;

      expect(
        () => log.error(DiagnosticCode.unanticipated, StateError(''), stack(1)),
        returnsNormally,
      );
      await diagnostics.settled;
      expect(await diagnostics.count(), 0);
    });

    test('and recording works again once the file does', () async {
      storage.failWrites = true;
      log.error(DiagnosticCode.unanticipated, StateError(''), stack(1));
      await diagnostics.settled;
      storage.failWrites = false;

      log.error(DiagnosticCode.unanticipated, StateError(''), stack(1));
      await diagnostics.settled;

      expect(await diagnostics.count(), 1);
    });

    test('a file that cannot be read counts as empty', () async {
      await recordErrors(2);
      storage.failReads = true;

      expect(await diagnostics.count(), 0);
      expect(await diagnostics.exportText(), contains('0 entries'));
    });

    test('lines that are not entries are skipped, the rest kept', () async {
      await recordErrors(2);
      storage.contents = 'half a li\n${storage.contents}{"at":12\n';

      expect(await diagnostics.count(), 2);
    });

    test('facts about the phone that cannot be read do not stop it', () async {
      final blind = DiagnosticLog(
        storage,
        facts: () async => throw const FileSystemException('no package info'),
      );
      Log(
        sinks: [blind],
        now: () => noon,
      ).error(DiagnosticCode.unanticipated, StateError(''), stack(1));
      await blind.settled;

      expect(await blind.count(), 1);
      expect(await blind.exportText(), contains('unanticipated'));
    });
  });

  test('recording returns at once: the write happens behind it', () async {
    storage.writeDelay = const Duration(milliseconds: 20);

    log.error(DiagnosticCode.unanticipated, StateError(''), stack(1));

    // Nothing written yet, and the caller was not made to wait.
    expect(storage.contents, isNull);
    await diagnostics.settled;
    expect(await diagnostics.count(), 1);
  });

  test('entries recorded close together are all kept, in order', () async {
    storage.writeDelay = const Duration(milliseconds: 2);
    await recordErrors(10);

    expect(await diagnostics.count(), 10);
  });
}

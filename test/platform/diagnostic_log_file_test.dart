import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tomo/platform/device_facts.dart';
import 'package:tomo/platform/diagnostic_log_file.dart';
import 'package:tomo_core/diagnostics/diagnostic_entry.dart';
import 'package:tomo_core/diagnostics/diagnostic_log.dart';
import 'package:tomo_core/diagnostics/log.dart';

/// The diagnostic log's real file, in a temporary folder.
void main() {
  late Directory dir;
  late FileDiagnosticLogStorage storage;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('tomo_diagnostic_log_test');
    storage = FileDiagnosticLogStorage(() async => dir);
  });

  tearDown(() => dir.deleteSync(recursive: true));

  test('there is no file until something is recorded', () async {
    expect(await storage.read(), isNull);
    expect(dir.listSync(), isEmpty);
  });

  test('what is written is what is read, from one plain file', () async {
    await storage.write('one\n');
    await storage.write('one\ntwo\n');

    expect(await storage.read(), 'one\ntwo\n');
    expect(dir.listSync().map((f) => f.uri.pathSegments.last), [
      'diagnostics.log',
    ]);
  });

  test('a real error lands in the file and survives a restart', () async {
    DiagnosticLog open() => DiagnosticLog(
      FileDiagnosticLogStorage(() async => dir),
      facts: () async => const DeviceFacts(
        appVersion: '1.0.0',
        buildNumber: '1',
        osVersion: 'android 16',
        deviceClass: DeviceClass.phone,
        locale: 'en-US',
      ),
    );
    final first = open();
    Log(sinks: [first]).error(
      DiagnosticCode.unanticipated,
      StateError('private'),
      StackTrace.current,
    );
    await first.settled;

    final afterRestart = open();

    expect(await afterRestart.count(), 1);
    final text = await afterRestart.exportText();
    expect(text, contains('StateError'));
    expect(text, isNot(contains('private')));
  });

  test('a folder that cannot be found stops nothing', () async {
    final lost = DiagnosticLog(
      FileDiagnosticLogStorage(
        () async => throw const FileSystemException('no such folder'),
      ),
      facts: () async => throw const FileSystemException('no facts'),
    );

    expect(
      () => Log(
        sinks: [lost],
      ).error(DiagnosticCode.unanticipated, StateError(''), StackTrace.current),
      returnsNormally,
    );
    await lost.settled;
    expect(await lost.count(), 0);
  });

  test('a screen 600 points wide or more is a tablet', () {
    expect(deviceClassFor(411), DeviceClass.phone);
    expect(deviceClassFor(599.9), DeviceClass.phone);
    expect(deviceClassFor(600), DeviceClass.tablet);
    expect(deviceClassFor(840), DeviceClass.tablet);
  });
}

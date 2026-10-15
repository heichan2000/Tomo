import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tomo/platform/stores.dart';
import 'package:tomo_core/data/device_only_file.dart';
import 'package:tomo_core/data/settings.dart';

/// The app's side of the storage interfaces (spec §6.1, C16): the settings
/// through `shared_preferences`, and the device-only file on disk.
void main() {
  group('the settings store', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('keeps the three kinds of value the settings use', () async {
      final store = SharedPreferencesStore();

      await store.write('appearance', 'dark');
      await store.write('autoStart', true);
      await store.write('lastFocusMinutes', 50);

      final reopened = SharedPreferencesStore();
      expect(await reopened.read('appearance'), 'dark');
      expect(await reopened.read('autoStart'), true);
      expect(await reopened.read('lastFocusMinutes'), 50);
    });

    test('a missing key reads as nothing, and remove takes one away', () async {
      final store = SharedPreferencesStore();
      expect(await store.read('lastProjectId'), isNull);

      await store.write('lastProjectId', 4);
      await store.remove('lastProjectId');

      expect(await store.read('lastProjectId'), isNull);
    });

    test('the six settings round-trip through it', () async {
      final settings = Settings(SharedPreferencesStore());

      await settings.setAppearance(Appearance.light);
      await settings.setCalmPet(true);
      await settings.setLastLengths(focusMinutes: 25, breakMinutes: 5);
      await settings.setLastProjectId(7);

      final again = Settings(SharedPreferencesStore());
      expect(await again.appearance(), Appearance.light);
      expect(await again.calmPet(), isTrue);
      expect(await again.autoStart(), isFalse);
      expect(await again.lastFocusMinutes(), 25);
      expect(await again.lastBreakMinutes(), 5);
      expect(await again.lastProjectId(), 7);
    });
  });

  group('the device-only file', () {
    late Directory dir;

    setUp(() => dir = Directory.systemTemp.createTempSync('tomo_device_file'));
    tearDown(() => dir.deleteSync(recursive: true));

    test('is one file, device.json, written only when there is news', () async {
      final file = DeviceOnlyFile(DeviceFile(() async => dir));
      expect(await file.notificationPermissionAsked(), isFalse);
      expect(dir.listSync(), isEmpty);

      await file.setNotificationPermissionAsked();

      expect(dir.listSync().map((f) => f.uri.pathSegments.last), [
        'device.json',
      ]);
      final reopened = DeviceOnlyFile(DeviceFile(() async => dir));
      expect(await reopened.notificationPermissionAsked(), isTrue);
    });
  });
}

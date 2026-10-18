import 'package:test/test.dart';
import 'package:tomo_core/data/device_only_file.dart';
import 'package:tomo_core/testing.dart';

/// The device-only file (spec §6.1, §17 C8): one small JSON file that stays on
/// this phone, so a restored phone asks for the notification permission again.
void main() {
  late MemoryDeviceFileStorage storage;
  late DeviceOnlyFile file;

  setUp(() {
    storage = MemoryDeviceFileStorage();
    file = DeviceOnlyFile(storage);
  });

  test('on a new phone, the permission has not been asked', () async {
    expect(await file.notificationPermissionAsked(), isFalse);
  });

  test('once asked, it stays asked', () async {
    await file.setNotificationPermissionAsked();

    expect(await file.notificationPermissionAsked(), isTrue);
    expect(await DeviceOnlyFile(storage).notificationPermissionAsked(), isTrue);
  });

  test('it is written as a small JSON object', () async {
    await file.setNotificationPermissionAsked();

    expect(storage.contents, '{"notificationPermissionAsked":true}');
  });

  group('a file that cannot be understood reads as not asked', () {
    for (final (name, contents) in [
      ('empty', ''),
      ('not JSON', 'asked=yes'),
      ('JSON, but not an object', '[true]'),
      ('the wrong type', '{"notificationPermissionAsked":"yes"}'),
      ('cut off mid-write', '{"notificationPermissionAsk'),
    ]) {
      test(name, () async {
        storage.contents = contents;

        expect(await file.notificationPermissionAsked(), isFalse);
      });
    }
  });

  test('a file that cannot be read at all reads as not asked', () async {
    storage.failReads = true;

    expect(await file.notificationPermissionAsked(), isFalse);
  });

  group('the denial line (spec §11.4)', () {
    test('on a new phone, it has not been shown', () async {
      expect(await file.notificationDenialShown(), isFalse);
    });

    test('once shown, it stays shown, and asking stays as it was', () async {
      await file.setNotificationDenialShown();

      expect(await DeviceOnlyFile(storage).notificationDenialShown(), isTrue);
      expect(await file.notificationPermissionAsked(), isFalse);
    });

    test('the two facts are kept side by side', () async {
      await file.setNotificationPermissionAsked();
      await file.setNotificationDenialShown();

      expect(
        storage.contents,
        '{"notificationPermissionAsked":true,'
        '"notificationDenialShown":true}',
      );
    });

    test('a file that cannot be understood reads as not shown', () async {
      storage.contents = '{"notificationDenialShown":1}';

      expect(await file.notificationDenialShown(), isFalse);
    });
  });

  test('other fields in the file are kept when it is rewritten', () async {
    storage.contents = '{"somethingLater":42}';

    await file.setNotificationPermissionAsked();

    expect(
      storage.contents,
      '{"somethingLater":42,"notificationPermissionAsked":true}',
    );
  });
}

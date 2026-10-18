import 'dart:convert';

/// Where the device-only file's text is kept. The app implements this with a
/// file in the application-support directory, left out of the phone's backup;
/// tests use `MemoryDeviceFileStorage`.
abstract interface class DeviceFileStorage {
  /// The file's text, or null when there is no file yet.
  Future<String?> read();
  Future<void> write(String contents);
}

/// The few facts that belong to this phone and must not travel in a backup
/// (spec §6.1, ADR-0028): whether the notification permission has been
/// asked, so a restored phone asks again, and whether Ready has shown the
/// line that says it was turned down.
///
/// It is a small JSON object. A file that is missing, unreadable or not
/// understood reads as "not asked": asking twice is harmless, failing is not.
final class DeviceOnlyFile {
  DeviceOnlyFile(this._storage);

  final DeviceFileStorage _storage;

  static const _asked = 'notificationPermissionAsked';

  static const _denialShown = 'notificationDenialShown';

  Future<bool> notificationPermissionAsked() async =>
      (await _readFields())[_asked] == true;

  Future<void> setNotificationPermissionAsked() => _setTrue(_asked);

  /// Whether Ready has shown the denial line, which it shows once (spec
  /// §11.4).
  Future<bool> notificationDenialShown() async =>
      (await _readFields())[_denialShown] == true;

  Future<void> setNotificationDenialShown() => _setTrue(_denialShown);

  Future<void> _setTrue(String key) async {
    final fields = await _readFields();
    fields[key] = true;
    await _storage.write(jsonEncode(fields));
  }

  Future<Map<String, Object?>> _readFields() async {
    try {
      final decoded = jsonDecode(await _storage.read() ?? '');
      return decoded is Map<String, Object?> ? {...decoded} : {};
    } catch (_) {
      // Missing, unreadable or cut off mid-write: start again from nothing.
      return {};
    }
  }
}

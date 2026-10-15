import 'dart:io';

import 'package:drift_flutter/drift_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tomo_core/data/device_only_file.dart';
import 'package:tomo_core/data/settings.dart';
import 'package:tomo_core/data/tomo_database.dart';

/// Where Tomo's files live: the application-support directory (spec §6.1).
/// On Android that is the app's own `files/` folder, which the backup rules
/// name (§6.4).
typedef Folder = Future<Directory> Function();

/// The database file, `tomo.sqlite`, in [folder]. The backup rules name this
/// file and its two side files, so the name must not change (spec §17, C16).
QueryExecutor databaseFile(Folder folder) => driftDatabase(
  name: 'tomo',
  native: DriftNativeOptions(databaseDirectory: folder),
);

/// The six settings, through `shared_preferences`.
///
/// This is the plugin's first API on purpose. On Android it keeps everything
/// in `FlutterSharedPreferences.xml`, the one settings file the backup rules
/// name; the newer API's default is DataStore, which the rules would miss
/// (spec §17, C16). It reads every value into memory once, at the first use.
final class SharedPreferencesStore implements KeyValueStore {
  SharedPreferencesStore([Future<SharedPreferences>? preferences])
    : _preferences = preferences ?? SharedPreferences.getInstance();

  final Future<SharedPreferences> _preferences;

  @override
  Future<Object?> read(String key) async => (await _preferences).get(key);

  @override
  Future<void> write(String key, Object value) async {
    final preferences = await _preferences;
    switch (value) {
      case final String text:
        await preferences.setString(key, text);
      case final bool flag:
        await preferences.setBool(key, flag);
      case final int number:
        await preferences.setInt(key, number);
      default:
        throw ArgumentError.value(value, key, 'not a String, bool or int');
    }
  }

  @override
  Future<void> remove(String key) async => (await _preferences).remove(key);
}

/// The device-only file, `device.json`, in [folder] (spec §6.1, C8).
///
/// On Android it stays on the phone because the backup rules name only the
/// database and the settings. On iPhone it still needs marking (spec §17,
/// C17).
final class DeviceFile implements DeviceFileStorage {
  DeviceFile(this._folder);

  static const fileName = 'device.json';

  final Folder _folder;

  Future<File> _file() async => File('${(await _folder()).path}/$fileName');

  @override
  Future<String?> read() async {
    final file = await _file();
    return file.existsSync() ? file.readAsString() : null;
  }

  @override
  Future<void> write(String contents) async {
    final file = await _file();
    // Written beside the file and then moved over it, so a kill mid-write
    // leaves the old one whole.
    final next = File('${file.path}.next');
    await next.writeAsString(contents, flush: true);
    await next.rename(file.path);
  }
}

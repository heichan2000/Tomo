import 'dart:io';

import '../data/device_only_file.dart';
import '../data/settings.dart';

/// A [KeyValueStore] held in memory. A test may read or seed [values].
final class MemoryKeyValueStore implements KeyValueStore {
  final values = <String, Object>{};

  @override
  Future<Object?> read(String key) async => values[key];

  @override
  Future<void> write(String key, Object value) async => values[key] = value;

  @override
  Future<void> remove(String key) async => values.remove(key);
}

/// A [DeviceFileStorage] held in memory. A test may read or seed [contents],
/// or make every read fail.
final class MemoryDeviceFileStorage implements DeviceFileStorage {
  /// The file's text. Null means there is no file.
  String? contents;

  /// When true, [read] throws, like a file the phone will not open.
  bool failReads = false;

  @override
  Future<String?> read() async {
    if (failReads) throw const FileSystemException('unreadable');
    return contents;
  }

  @override
  Future<void> write(String contents) async => this.contents = contents;
}

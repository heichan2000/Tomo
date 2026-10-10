import 'dart:io';

import '../data/device_only_file.dart';
import '../data/settings.dart';
import '../diagnostics/diagnostic_log.dart';

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

/// A [DiagnosticLogStorage] held in memory. A test may read or seed
/// [contents], make reads or writes fail, or make writes slow.
final class MemoryDiagnosticLogStorage implements DiagnosticLogStorage {
  /// The file's text. Null means there is no file.
  String? contents;
  bool failReads = false;
  bool failWrites = false;

  /// How long each write takes.
  Duration writeDelay = Duration.zero;

  @override
  Future<String?> read() async {
    if (failReads) throw const FileSystemException('unreadable');
    return contents;
  }

  @override
  Future<void> write(String contents) async {
    if (writeDelay > Duration.zero) await Future<void>.delayed(writeDelay);
    if (failWrites) throw const FileSystemException('disk full');
    this.contents = contents;
  }
}

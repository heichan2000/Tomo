import 'dart:convert';

import 'diagnostic_entry.dart';
import 'log.dart';

/// Where the diagnostic log's text is kept. The app implements this with a
/// plain file in the application-support directory, outside the database and
/// left out of the phone's backup; tests use `MemoryDiagnosticLogStorage`.
abstract interface class DiagnosticLogStorage {
  /// The file's text, or null when there is no file yet.
  Future<String?> read();
  Future<void> write(String contents);
}

/// What kind of device this is. No identifier.
enum DeviceClass { phone, tablet }

/// The reproduction context stamped on every entry (ADR-0004). None of it
/// identifies the user or the phone.
final class DeviceFacts {
  const DeviceFacts({
    required this.appVersion,
    required this.buildNumber,
    required this.osVersion,
    required this.deviceClass,
    required this.locale,
  });

  final String appVersion;
  final String buildNumber;
  final String osVersion;
  final DeviceClass deviceClass;
  final String locale;
}

/// The diagnostic log (spec §13, ADR-0004): the bounded, on-device record of
/// errors the user may share.
///
/// It keeps only error entries, at most [maxEntries] of them and at most
/// [maxBytes] of text; the oldest go first. It lives outside the database, so
/// a database failure can still be recorded. Recording is fire-and-forget and
/// **swallows its own errors**: an error recorder that can crash the app is
/// worse than none. There is no way to clear it, because it holds nothing to
/// clear.
final class DiagnosticLog implements DiagnosticSink {
  DiagnosticLog(
    this._storage, {
    required this._facts,
    this.maxEntries = 200,
    this.maxBytes = 512 * 1024,
  });

  /// A stack trace keeps this many frames: the ones nearest the throw.
  static const maxStackFrames = 30;

  final DiagnosticLogStorage _storage;
  final Future<DeviceFacts> Function() _facts;
  final int maxEntries;
  final int maxBytes;

  Future<void> _queue = Future.value();

  /// Completes when every entry recorded so far has been written or given up
  /// on. Never fails.
  Future<void> get settled => _queue;

  @override
  void record(DiagnosticEntry entry) {
    if (entry.level != EntryLevel.error) return;
    // One write at a time, in order; a failure ends that write and no other.
    _queue = _queue.then((_) => _append(entry)).catchError((Object _) {});
  }

  /// How many entries the log holds. The *Share diagnostics* row shows this
  /// and is turned off at zero.
  Future<int> count() async => (await _readLines()).length;

  /// The whole log as plain text, oldest entry first, for the share sheet.
  Future<String> exportText() async {
    await settled;
    final entries = (await _readLines()).map(_decode).toList();
    final buffer = StringBuffer()
      ..writeln('Tomo diagnostics')
      ..writeln('${entries.length} entries');
    for (final entry in entries) {
      buffer
        ..writeln()
        ..writeln([entry['at'], entry['code'], entry['type']].join('  '))
        ..writeln(
          [
            'Tomo ${entry['app']} (${entry['build']})',
            entry['os'],
            entry['device'],
            entry['locale'],
          ].join(' · '),
        );
      for (final frame in entry['stack'] as List<Object?>) {
        buffer.writeln(frame);
      }
    }
    return buffer.toString();
  }

  Future<void> _append(DiagnosticEntry entry) async {
    final facts = await _readFacts();
    final frames = const LineSplitter()
        .convert(entry.stackTrace.toString().trimRight())
        .take(maxStackFrames)
        .toList();
    // Everything written is in this map: allowlisted by construction.
    final line = jsonEncode({
      'at': entry.at.toIso8601String(),
      'code': entry.code.name,
      'type': entry.errorType,
      'stack': frames,
      'app': facts?.appVersion,
      'build': facts?.buildNumber,
      'os': facts?.osVersion,
      'device': facts?.deviceClass.name,
      'locale': facts?.locale,
    });

    final lines = [...await _readLines(), line];
    while (lines.length > maxEntries || _bytes(lines) > maxBytes) {
      if (lines.length == 1) return; // One entry too big to keep at all.
      lines.removeAt(0);
    }
    await _storage.write('${lines.join('\n')}\n');
  }

  int _bytes(List<String> lines) =>
      lines.fold(0, (total, line) => total + utf8.encode(line).length + 1);

  Future<DeviceFacts?> _readFacts() async {
    try {
      return await _facts();
    } catch (_) {
      return null;
    }
  }

  /// The stored entries, one per line, skipping anything that is not one.
  Future<List<String>> _readLines() async {
    try {
      final contents = await _storage.read() ?? '';
      return [
        for (final line in const LineSplitter().convert(contents))
          if (_isEntry(line)) line,
      ];
    } catch (_) {
      return [];
    }
  }

  bool _isEntry(String line) {
    try {
      final decoded = jsonDecode(line);
      return decoded is Map<String, Object?> && decoded['stack'] is List;
    } catch (_) {
      return false;
    }
  }

  Map<String, Object?> _decode(String line) =>
      jsonDecode(line) as Map<String, Object?>;
}

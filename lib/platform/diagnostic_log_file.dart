import 'dart:io';

import 'package:tomo_core/diagnostics/diagnostic_log.dart';

/// The diagnostic log's file: plain text in the application-support
/// directory, outside the database (spec §6.1, §13).
///
/// On Android it is left out of the phone's backup because the backup rules
/// name only the database and the settings. On iPhone it still needs marking
/// (spec §17, C17).
final class FileDiagnosticLogStorage implements DiagnosticLogStorage {
  FileDiagnosticLogStorage(this._directory);

  static const fileName = 'diagnostics.log';

  /// Where the file lives. Asked for on every use, so a slow or failing
  /// lookup at start-up costs nothing until an error is recorded.
  final Future<Directory> Function() _directory;

  Future<File> _file() async => File('${(await _directory()).path}/$fileName');

  @override
  Future<String?> read() async {
    final file = await _file();
    return file.existsSync() ? file.readAsString() : null;
  }

  @override
  Future<void> write(String contents) async {
    final file = await _file();
    // Written beside the file and then moved over it, so a kill mid-write
    // leaves the old log whole.
    final next = File('${file.path}.next');
    await next.writeAsString(contents, flush: true);
    await next.rename(file.path);
  }
}

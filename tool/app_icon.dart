// Writes every app icon and splash file from the Tomo egg grid (spec §9.7).
// Run `dart run tool/app_icon.dart` from the repo root after the egg changes,
// and commit what it writes: test/tool/app_icon_test.dart fails if a committed
// file differs. The files and their rules are in tool/app_icon/files.dart.

import 'dart:io';

import 'app_icon/files.dart';

void main() {
  final root = File.fromUri(Platform.script).parent.parent.path;
  for (final MapEntry(key: path, value: bytes) in appIconFiles().entries) {
    File('$root/$path')
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes);
    stdout.writeln(path);
  }
}

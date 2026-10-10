import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Tests over files in the repo that keep the project's shape (spec §15).
/// `flutter test` runs them from the repo root.
void main() {
  test('only the root has an analysis_options.yaml', () {
    // A nested file makes its package a separate analysis context without the
    // tomo_lints plugin, so `print` would pass there unseen (promise 26).
    final nested = Directory('packages')
        .listSync(recursive: true)
        .whereType<File>()
        .map((file) => file.path.replaceAll(r'\', '/'))
        .where((path) => path.endsWith('/analysis_options.yaml'))
        .where((path) => !path.contains('/.dart_tool/'));

    expect(nested, isEmpty);
  });

  test('tomo_core depends on no Flutter and no Riverpod (ADR-0027)', () {
    final pubspec = File('packages/tomo_core/pubspec.yaml').readAsStringSync();

    expect(pubspec, isNot(contains('sdk: flutter')));
    expect(pubspec, isNot(contains('riverpod')));
  });

  test('.fvmrc pins the Flutter the spec names', () {
    expect(File('.fvmrc').readAsStringSync(), contains('"flutter": "3.47.6"'));
  });
}

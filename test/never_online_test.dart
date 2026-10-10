import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Promise 30, the packages half: nothing is resolved into Tomo that is not on
/// the written allowlist (ADR-0029, spec §15.2 and §16).
///
/// A test over files in the repo. `flutter test` runs it from the repo root.
void main() {
  final locked = _lockedPackages(File('pubspec.lock').readAsStringSync());
  final allowed = _allowlist(File('docs/package-allowlist').readAsLinesSync());

  test('pubspec.lock was read', () {
    expect(locked, containsAll(['flutter', 'drift', 'flutter_riverpod']));
  });

  test('every resolved package is on the allowlist', () {
    expect(
      locked.difference(allowed),
      isEmpty,
      reason:
          'A package was added. If Tomo really needs it, add its name to '
          'docs/package-allowlist in the same change.',
    );
  });

  test('the allowlist names nothing that is not resolved', () {
    expect(
      allowed.difference(locked),
      isEmpty,
      reason: 'Remove these lines from docs/package-allowlist.',
    );
  });

  test('no pubspec asks for a deliberately absent package', () {
    for (final path in _pubspecs) {
      final asked = _directDependencies(File(path).readAsStringSync());
      expect(
        asked.where(_isDeliberatelyAbsent),
        isEmpty,
        reason: '$path depends on a package spec §15.2 rules out.',
      );
    }
  });

  test("Tomo's own code imports no deliberately absent package", () {
    final offenders = <String>[];
    for (final root in _sourceRoots) {
      final dir = Directory(root);
      if (!dir.existsSync()) continue;
      for (final file in dir.listSync(recursive: true).whereType<File>()) {
        if (!file.path.endsWith('.dart')) continue;
        for (final match in _packageImport.allMatches(
          file.readAsStringSync(),
        )) {
          if (_isDeliberatelyAbsent(match.group(1)!)) {
            offenders.add('${file.path}: ${match.group(1)}');
          }
        }
      }
    }
    expect(offenders, isEmpty);
  });
}

const _pubspecs = [
  'pubspec.yaml',
  'packages/tomo_core/pubspec.yaml',
  'packages/tomo_lints/pubspec.yaml',
];

const _sourceRoots = ['lib', 'packages/tomo_core/lib'];

/// Spec §15.2, "Deliberately absent". Some of these are still resolved,
/// because a package Tomo does use depends on them (`http`, through
/// `timezone` and `package_info_plus`). Tomo must never ask for them or
/// import them itself.
const _deliberatelyAbsent = {
  'http',
  'dio',
  'flutter_secure_storage',
  'rive',
  'flutter_svg',
  'lottie',
  'google_fonts',
  'mockito',
  'riverpod_generator',
  'riverpod_lint',
  'permission_handler',
  'flutter_timezone',
  'device_info_plus',
  'flutter_launcher_icons',
  'flutter_native_splash',
  'sqlite3_flutter_libs',
};

/// "Any crash/analytics SDK or Firebase", by the names they go by.
final _telemetry = RegExp(
  r'^(firebase|sentry|datadog|bugsnag|instabug|posthog|amplitude|mixpanel)|'
  r'(crashlytics|analytics)',
);

bool _isDeliberatelyAbsent(String package) =>
    _deliberatelyAbsent.contains(package) || _telemetry.hasMatch(package);

final _packageImport = RegExp(
  r'''^\s*(?:import|export)\s+['"]package:([a-z0-9_]+)/''',
  multiLine: true,
);

/// The package names in a `pubspec.lock`: the two-space-indented keys under
/// `packages:`.
Set<String> _lockedPackages(String lock) {
  final names = <String>{};
  var inPackages = false;
  for (final line in lock.split('\n')) {
    if (!line.startsWith(' ')) {
      inPackages = line.trimRight() == 'packages:';
      continue;
    }
    final match = RegExp(r'^  ([a-z0-9_]+):\s*$').firstMatch(line);
    if (inPackages && match != null) names.add(match.group(1)!);
  }
  return names;
}

/// One package name per line; `#` starts a comment.
Set<String> _allowlist(List<String> lines) => {
  for (final line in lines)
    if (line.split('#').first.trim() case final name when name.isNotEmpty) name,
};

/// The names under `dependencies:` and `dev_dependencies:` in a pubspec.
Set<String> _directDependencies(String pubspec) {
  final names = <String>{};
  var inDependencies = false;
  for (final line in pubspec.split('\n')) {
    if (!line.startsWith(' ') && line.trim().isNotEmpty) {
      inDependencies = RegExp(
        r'^(dev_)?dependencies:\s*$',
      ).hasMatch(line.trimRight());
      continue;
    }
    final match = RegExp(r'^  ([a-z0-9_]+):').firstMatch(line);
    if (inDependencies && match != null) names.add(match.group(1)!);
  }
  return names;
}

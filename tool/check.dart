// The one "done" command (spec §15.7). Run it as `tool/check` from the repo
// root. It passes only if:
//
//   1. the Flutter on PATH is the one `.fvmrc` pins;
//   2. `pub get` and the generators (`build_runner`, `gen_l10n`) change no file;
//   3. the analyzer is clean, `tomo_lints` included;
//   4. every test passes in the app, `tomo_core` and `tomo_lints`.
//
// It is plain Dart with no packages, so it runs the same on Windows, macOS and
// Linux. It talks through stdout and stderr; nothing here is app code.

import 'dart:convert';
import 'dart:io';

const _core = 'packages/tomo_core';
const _lints = 'packages/tomo_lints';

Future<void> main() async {
  final root = File.fromUri(Platform.script).parent.parent.path;
  Directory.current = root;

  await _step('Flutter is the pinned version', _checkPinnedFlutter);

  // Taken before `pub get`, which runs gen_l10n itself and may rewrite the lock.
  final before = await _treeState();
  await _step('Packages are resolved', () => _run('flutter', ['pub', 'get']));
  await _step(
    'build_runner',
    () => _run('dart', [
      'run',
      'build_runner',
      'build',
      '--delete-conflicting-outputs',
    ], workingDirectory: _core),
  );
  await _step('gen_l10n', () => _run('flutter', ['gen-l10n']));
  await _step('Generated files are up to date', () async {
    final after = await _treeState();
    final changed = {
      for (final path in {...before.keys, ...after.keys})
        if (before[path] != after[path]) path,
    }.toList()..sort();
    if (changed.isEmpty) return;
    stderr.writeln(
      '`pub get` or a generator changed these files. Look at them, keep '
      'them, and run tool/check again:',
    );
    changed.forEach(stderr.writeln);
    throw const _Failed();
  });

  // `dart analyze`, not `flutter analyze`: on Flutter 3.47.6 the latter returns
  // before analyzer plugins report, so it never shows a `tomo_lints` finding.
  // `--fatal-infos` matches what `flutter analyze` treats as a failure.
  await _step('analyze', () => _run('dart', ['analyze', '--fatal-infos']));
  await _step(
    'tomo_core tests',
    () => _run('dart', ['test'], workingDirectory: _core),
  );
  await _step(
    'tomo_lints tests',
    () => _run('dart', ['test'], workingDirectory: _lints),
  );
  await _step('app tests', () => _run('flutter', ['test']));

  stdout.writeln('\ntool/check passed.');
}

Future<void> _step(String name, Future<void> Function() body) async {
  stdout.writeln('\n== $name');
  try {
    await body();
  } on _Failed {
    stderr.writeln('\ntool/check FAILED at: $name');
    exit(1);
  }
}

final class _Failed implements Exception {
  const _Failed();
}

/// Fails unless `flutter --version` reports the version in `.fvmrc`.
Future<void> _checkPinnedFlutter() async {
  final fvmrc = jsonDecode(File('.fvmrc').readAsStringSync());
  final pinned = (fvmrc as Map<String, Object?>)['flutter'];
  final version = jsonDecode(
    await _capture('flutter', ['--version', '--machine']),
  );
  final actual = (version as Map<String, Object?>)['frameworkVersion'];
  if (actual == pinned) {
    stdout.writeln('Flutter $actual');
    return;
  }
  stderr.writeln(
    'The Flutter on PATH is $actual, but .fvmrc pins $pinned. '
    'Run `fvm install` and put the pinned Flutter first on PATH.',
  );
  throw const _Failed();
}

/// Every file that differs from the last commit (changed, new or deleted;
/// ignored files left out), with a fingerprint of what it holds now. If a
/// generator touches a file, its entry appears or changes.
Future<Map<String, String>> _treeState() async {
  final differing = await _capture('git', [
    'ls-files',
    '--modified',
    '--deleted',
    '--others',
    '--exclude-standard',
  ]);
  final staged = await _capture('git', ['diff', '--cached', '--name-only']);
  return {
    for (final path in const LineSplitter().convert('$differing\n$staged'))
      if (path.isNotEmpty) path: _fingerprint(File(path)),
  };
}

String _fingerprint(File file) =>
    file.existsSync() ? '${file.lengthSync()} ${_checksum(file)}' : 'deleted';

/// A cheap content checksum, enough to notice a generator rewriting a file.
int _checksum(File file) {
  var sum = 0;
  for (final byte in file.readAsBytesSync()) {
    sum = (sum * 31 + byte) & 0x3fffffff;
  }
  return sum;
}

Future<void> _run(
  String command,
  List<String> arguments, {
  String? workingDirectory,
}) async {
  final process = await Process.start(
    command,
    arguments,
    workingDirectory: workingDirectory,
    mode: ProcessStartMode.inheritStdio,
    // `flutter` and `dart` are .bat files on Windows.
    runInShell: Platform.isWindows,
  );
  if (await process.exitCode != 0) throw const _Failed();
}

Future<String> _capture(String command, List<String> arguments) async {
  final result = await Process.run(
    command,
    arguments,
    runInShell: Platform.isWindows,
    stdoutEncoding: utf8,
    stderrEncoding: utf8,
  );
  if (result.exitCode != 0) {
    stderr.writeln(result.stderr);
    throw const _Failed();
  }
  return result.stdout as String;
}

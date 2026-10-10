// The harness finds tests by the name test_*, so these can't be lowerCamelCase.
// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:tomo_lints/src/no_print_outside_log.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NoPrintOutsideLogTest);
    defineReflectiveTests(ConsoleSinkExemptionTest);
  });
}

/// Promise 26: no `print` / `debugPrint`. The analyzer keeps the promise; this
/// proves the rule that keeps it still fires (spec §16).
@reflectiveTest
class NoPrintOutsideLogTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = NoPrintOutsideLog();
    newPackage('flutter')
      ..addFile('lib/foundation.dart', r'''
export 'src/foundation/print.dart';
''')
      ..addFile('lib/src/foundation/print.dart', r'''
typedef DebugPrintCallback = void Function(String? message, {int? wrapWidth});
DebugPrintCallback debugPrint = debugPrintThrottled;
void debugPrintThrottled(String? message, {int? wrapWidth}) {}
void debugPrintSynchronously(String? message, {int? wrapWidth}) {}
''');
    super.setUp();
  }

  Future<void> test_print_isFlagged() async {
    await assertDiagnostics(
      r'''
void f() {
  print('hello');
}
''',
      [lint(13, 5)],
    );
  }

  Future<void> test_printTearOff_isFlagged() async {
    await assertDiagnostics(
      r'''
void f(List<String> lines) {
  lines.forEach(print);
}
''',
      [lint(45, 5)],
    );
  }

  Future<void> test_debugPrint_isFlagged() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/foundation.dart';

void f() {
  debugPrint('hello');
}
''',
      [lint(56, 10)],
    );
  }

  Future<void> test_debugPrintSynchronously_isFlagged() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/foundation.dart';

void f() {
  debugPrintSynchronously('hello');
}
''',
      [lint(56, 23)],
    );
  }

  Future<void> test_ownFunctionNamedPrint_isAllowed() async {
    await assertNoDiagnostics(r'''
class Receipt {
  void print() {}
}

void f(Receipt receipt) {
  receipt.print();
}
''');
  }
}

/// The harness names the package under test `test`, so the exemption is
/// proven on a stand-in library. That the real one is spelled right is proven
/// by `tool/check`: the analyzer would flag Tomo's own console sink.
@reflectiveTest
class ConsoleSinkExemptionTest extends AnalysisRuleTest {
  static const _sinkPath = 'lib/diagnostics/console_sink.dart';

  @override
  void setUp() {
    rule = NoPrintOutsideLog(
      consoleSinkLibrary: 'package:test/diagnostics/console_sink.dart',
    );
    super.setUp();
  }

  Future<void> test_consoleSink_mayPrint() async {
    final sink = newFile('$testPackageRootPath/$_sinkPath', r'''
void write(String line) {
  print(line);
}
''');
    await assertNoDiagnosticsInFile(sink.path);
  }

  Future<void> test_everyOtherLibrary_isStillFlagged() async {
    await assertDiagnostics(
      r'''
void write(String line) {
  print(line);
}
''',
      [lint(28, 5)],
    );
  }
}

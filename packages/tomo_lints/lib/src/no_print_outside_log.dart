import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// No `print` or `debugPrint` anywhere except inside the `Log` facade
/// (ADR-0004, spec §13).
///
/// The built-in `avoid_print` lets `debugPrint` through, and both can carry
/// any text to the console. The `Log` facade can only emit a diagnostic
/// entry, which cannot hold message text at all.
class NoPrintOutsideLog extends AnalysisRule {
  static const LintCode code = LintCode(
    'no_print_outside_log',
    "Don't call '{0}'. The Log facade is the only way Tomo writes to the "
        'console.',
    correctionMessage: 'Emit a diagnostic entry through Log instead.',
    // An error, like avoid_print (spec §15.3): `dart analyze` fails on it.
    severity: DiagnosticSeverity.ERROR,
  );

  /// The one library allowed to print: the facade's debug console sink.
  static const tomoConsoleSinkLibrary =
      'package:tomo_core/diagnostics/console_sink.dart';

  /// The library this instance lets print. Only the rule's own test passes
  /// anything but [tomoConsoleSinkLibrary].
  final String consoleSinkLibrary;

  /// `print` from `dart:core`.
  static const _corePrint = 'print';

  /// Flutter's console printers, all in `package:flutter/foundation.dart`.
  static const _flutterPrints = {
    'debugPrint',
    'debugPrintThrottled',
    'debugPrintSynchronously',
    'debugPrintStack',
  };

  NoPrintOutsideLog({this.consoleSinkLibrary = tomoConsoleSinkLibrary})
    : super(
        name: 'no_print_outside_log',
        description:
            'No print or debugPrint outside the Log facade (ADR-0004).',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    if (context.libraryElement?.uri.toString() == consoleSinkLibrary) return;
    registry.addSimpleIdentifier(this, _Visitor(this));
  }

  /// Whether [name], declared in the library at [library], is a console
  /// printer.
  static bool isConsolePrinter(String name, Uri library) {
    if (name == _corePrint) return library.toString() == 'dart:core';
    return _flutterPrints.contains(name) &&
        library.isScheme('package') &&
        library.pathSegments.first == 'flutter';
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final NoPrintOutsideLog rule;

  _Visitor(this.rule);

  // Every use is an identifier: a call, a tear-off (`forEach(print)`), or a
  // read of Flutter's `debugPrint` variable.
  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    final element = node.element;
    final name = element?.name;
    final library = element?.library?.uri;
    if (name == null || library == null) return;
    if (NoPrintOutsideLog.isConsolePrinter(name, library)) {
      rule.reportAtNode(node, arguments: [name]);
    }
  }
}

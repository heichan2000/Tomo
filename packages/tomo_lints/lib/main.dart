/// Tomo's analyzer plugin. The analysis server loads [plugin] from this file.
library;

import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';

import 'src/no_print_outside_log.dart';

final plugin = TomoLintsPlugin();

class TomoLintsPlugin extends Plugin {
  @override
  String get name => 'tomo_lints';

  @override
  void register(PluginRegistry registry) {
    // A warning rule is on by default, so no analysis_options.yaml can forget
    // to switch it on.
    registry.registerWarningRule(NoPrintOutsideLog());
  }
}

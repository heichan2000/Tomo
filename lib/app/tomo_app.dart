import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// The root of the app. For now it shows one empty screen.
class TomoApp extends StatelessWidget {
  const TomoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(),
    );
  }
}

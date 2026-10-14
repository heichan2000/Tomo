import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../ui/pixel_check_screen.dart';

/// The root of the app. Until the app shell exists, debug and profile builds
/// open on the pixel check screen and release builds on an empty one.
class TomoApp extends StatelessWidget {
  const TomoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: kReleaseMode ? const Scaffold() : const PixelCheckScreen(),
    );
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../ui/kit_gallery_screen.dart';
import 'tomo_look.dart';

/// The root of the app. Until the app shell exists, debug and profile builds
/// open on the kit gallery and release builds on an empty one.
class TomoApp extends StatelessWidget {
  const TomoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      scrollBehavior: const TomoScrollBehavior(),
      builder: (context, child) => TomoLook(child: child!),
      home: kReleaseMode ? const SizedBox.shrink() : const KitGalleryScreen(),
    );
  }
}

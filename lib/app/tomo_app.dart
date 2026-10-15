import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import 'phone_column.dart';
import 'providers.dart';
import 'routes.dart';
import 'start_up.dart';
import 'tomo_look.dart';

/// The root of the app, once [startTomo] has opened everything. It wears the
/// theme Settings asks for, around the pet's accent once it has hatched, and
/// opens on [first].
class TomoApp extends ConsumerWidget {
  const TomoApp({super.key, required this.first});

  final FirstSurface first;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appearance = ref.watch(appearanceProvider);
    final species = ref.watch(hatchedSpeciesProvider);
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      scrollBehavior: const TomoScrollBehavior(),
      builder: (context, child) => TomoLook(
        appearance: appearance,
        species: species,
        child: PhoneColumn(child: child!),
      ),
      onGenerateInitialRoutes: (_) => firstRoutes(first),
      // Every other screen is pushed as a route object, never by name.
      onGenerateRoute: (_) => null,
    );
  }
}

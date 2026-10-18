import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import 'notification_watch.dart';
import 'phone_column.dart';
import 'providers.dart';
import 'routes.dart';
import 'start_up.dart';
import 'timer_buzz.dart';
import 'tomo_look.dart';

/// The root of the app, once [startTomo] has opened everything. It wears the
/// theme Settings asks for, around the pet's accent once it has hatched, and
/// opens on [first]. It keeps the phone's notifications in step
/// ([NotificationWatch]) and buzzes when the timer runs out ([TimerBuzz]).
class TomoApp extends ConsumerStatefulWidget {
  const TomoApp({super.key, required this.first});

  final FirstSurface first;

  @override
  ConsumerState<TomoApp> createState() => _TomoAppState();
}

class _TomoAppState extends ConsumerState<TomoApp> {
  final _navigator = GlobalKey<NavigatorState>();
  final _focusRoutes = FocusRouteObserver();

  @override
  Widget build(BuildContext context) {
    final appearance = ref.watch(appearanceProvider);
    final species = ref.watch(hatchedSpeciesProvider);
    return NotificationWatch(
      navigator: _navigator,
      focusRoutes: _focusRoutes,
      child: TimerBuzz(
        focusRoutes: _focusRoutes,
        child: MaterialApp(
          navigatorKey: _navigator,
          navigatorObservers: [_focusRoutes],
          onGenerateTitle: (context) => AppLocalizations.of(context).appName,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          scrollBehavior: const TomoScrollBehavior(),
          builder: (context, child) => TomoLook(
            appearance: appearance,
            species: species,
            child: PhoneColumn(child: child!),
          ),
          onGenerateInitialRoutes: (_) => firstRoutes(widget.first),
          // Every other screen is pushed as a route object, never by name.
          onGenerateRoute: (_) => null,
        ),
      ),
    );
  }
}

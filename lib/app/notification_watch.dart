import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tomo_core/focus/focus_cycle_service.dart';
import 'package:tomo_core/notifications/notification_schedule.dart';
import 'package:tomo_core/result.dart';

import 'providers.dart';
import 'routes.dart';

/// Keeps the phone's notifications in step with the app (spec §11.2): a sync
/// at the start and on every lifecycle change, the permission re-read on
/// every resume, and a tapped notification bringing Focus forward if its
/// cycle is still live (§11.1).
class NotificationWatch extends ConsumerStatefulWidget {
  const NotificationWatch({
    super.key,
    required this.navigator,
    required this.focusRoutes,
    required this.child,
  });

  final GlobalKey<NavigatorState> navigator;
  final FocusRouteObserver focusRoutes;
  final Widget child;

  @override
  ConsumerState<NotificationWatch> createState() => _NotificationWatchState();
}

class _NotificationWatchState extends ConsumerState<NotificationWatch> {
  late final AppLifecycleListener _lifecycle;
  late final StreamSubscription<String?> _taps;

  @override
  void initState() {
    super.initState();
    // Opening the app is coming forward: nothing pending, delivered ones
    // cleared.
    _sync();
    _lifecycle = AppLifecycleListener(
      onStateChange: (_) => _sync(),
      onResume: () =>
          unawaited(ref.read(notificationAccessProvider.notifier).refresh()),
    );
    _taps = ref.read(notificationTapsProvider).listen(_tapped);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    unawaited(_taps.cancel());
    super.dispose();
  }

  void _sync() => unawaited(ref.read(notificationSyncProvider).sync());

  Future<void> _tapped(String? payload) async {
    final standing = await ref.read(focusCycleServiceProvider).reconcile();
    if (standing is! Success<CycleStanding>) return;
    final outcome = tapOutcome(payload: payload, cycle: standing.value.cycle);
    final context = widget.navigator.currentContext;
    if (outcome == NotificationTap.openFocus &&
        !widget.focusRoutes.isOpen &&
        context != null &&
        context.mounted) {
      openFocus(context);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Whether Focus is in the app's top-level stack, so a tap doesn't open it
/// twice.
class FocusRouteObserver extends NavigatorObserver {
  var _open = 0;

  bool get isOpen => _open > 0;

  bool _isFocus(Route<dynamic>? route) =>
      route?.settings.name == focusRouteName;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (_isFocus(route)) _open++;
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (_isFocus(route)) _open--;
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (_isFocus(route)) _open--;
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (_isFocus(oldRoute)) _open--;
    if (_isFocus(newRoute)) _open++;
  }
}

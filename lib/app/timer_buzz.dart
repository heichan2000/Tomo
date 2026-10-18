import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tomo_core/focus/live_cycle.dart';
import 'package:tomo_core/notifications/haptics.dart';
import 'package:tomo_core/notifications/notification_schedule.dart';
import 'package:tomo_core/pet/pet_standing.dart';

import '../platform/notifications.dart';
import 'notification_watch.dart';
import 'providers.dart';

/// The timer buzz (spec §11.5): while Tomo is open, a block or a break
/// running out is felt, at the moments a notification would fire if Tomo
/// were away. Whatever screen is showing, the Work tab included.
///
/// A block that runs out with Focus open is left to Focus: its beat run fires
/// the reward tap, and one moment never fires both.
class TimerBuzz extends ConsumerStatefulWidget {
  const TimerBuzz({super.key, required this.focusRoutes, required this.child});

  final FocusRouteObserver focusRoutes;
  final Widget child;

  @override
  ConsumerState<TimerBuzz> createState() => _TimerBuzzState();
}

class _TimerBuzzState extends ConsumerState<TimerBuzz> {
  Timer? _wait;

  @override
  void initState() {
    super.initState();
    ref.listenManual<PetStanding?>(
      petStandingProvider,
      (_, pet) => _waitFor(pet?.cycle, ref.read(databaseProvider).clock()),
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _wait?.cancel();
    super.dispose();
  }

  /// Waits for the next moment [cycle] runs out after [after], then for the
  /// one after that: under auto-start, the block's end and then its break's.
  void _waitFor(LiveCycle? cycle, DateTime after) {
    _wait?.cancel();
    final next = cycle == null
        ? null
        : timerEnds(cycle: cycle, after: after).firstOrNull;
    if (next == null) return;
    final now = ref.read(databaseProvider).clock();
    _wait = Timer(next.at.difference(now), () {
      final haptic = hapticFor(
        isForeground: appIsForeground(),
        beatWillPlay:
            next.slot == NotificationSlot.blockEnd && widget.focusRoutes.isOpen,
      );
      // The reward tap is the beat run's own to fire.
      if (haptic == Haptic.timerBuzz) {
        unawaited(ref.read(hapticPlayerProvider).play(haptic));
      }
      _waitFor(cycle, next.at);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

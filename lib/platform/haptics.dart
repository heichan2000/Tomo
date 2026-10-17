import 'package:flutter/services.dart';
import 'package:tomo_core/notifications/haptics.dart';

/// The phone's haptics through Flutter's own [HapticFeedback], no package
/// (spec §11.5, ADR-0013). A system setting may swallow them silently, so
/// nothing relies on one alone.
class SystemHaptics implements HapticPlayer {
  const SystemHaptics();

  @override
  Future<void> play(Haptic haptic) => switch (haptic) {
    Haptic.rewardTap => HapticFeedback.lightImpact(),
    Haptic.timerBuzz => HapticFeedback.vibrate(),
    Haptic.none => Future<void>.value(),
  };
}

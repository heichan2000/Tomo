import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tomo_core/notifications/haptics.dart';

/// The phone's haptics, no package (spec §11.5, ADR-0013). The reward tap is
/// Flutter's own [HapticFeedback]. So is the timer buzz on iPhone; on Android
/// that is the long-press bump, so there the buzz is a real one, run by
/// `MainActivity` through the `tomo/notifications` channel. A system setting
/// may swallow either silently, so nothing relies on one alone.
class SystemHaptics implements HapticPlayer {
  const SystemHaptics();

  static const _channel = MethodChannel('tomo/notifications');

  /// The Android timer buzz: one short buzz (C157).
  static const timerBuzzLength = Duration(milliseconds: 250);

  @override
  Future<void> play(Haptic haptic) => switch (haptic) {
    Haptic.rewardTap => HapticFeedback.lightImpact(),
    Haptic.timerBuzz =>
      defaultTargetPlatform == TargetPlatform.android
          ? _buzz()
          : HapticFeedback.vibrate(),
    Haptic.none => Future<void>.value(),
  };

  Future<void> _buzz() async {
    try {
      await _channel.invokeMethod<void>('buzz', {
        'ms': timerBuzzLength.inMilliseconds,
      });
    } on PlatformException {
      // A phone that can't or won't vibrate: the screen still shows the end.
    }
  }
}

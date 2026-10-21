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

  /// The evolution's buzz: one long one (C167).
  static const evolutionBuzzLength = Duration(milliseconds: 800);

  @override
  Future<void> play(Haptic haptic) => switch (haptic) {
    Haptic.rewardTap => HapticFeedback.lightImpact(),
    Haptic.timerBuzz =>
      defaultTargetPlatform == TargetPlatform.android
          ? _buzz(timerBuzzLength).then((_) {})
          : HapticFeedback.vibrate(),
    Haptic.evolutionBuzz => _evolutionBuzz(),
    Haptic.none => Future<void>.value(),
  };

  /// Kept quiet by silent or Do Not Disturb, the evolution's buzz is the
  /// reward tap instead, so it is never the one beat with nothing to feel.
  Future<void> _evolutionBuzz() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return HapticFeedback.vibrate();
    }
    if (!await _buzz(evolutionBuzzLength)) await HapticFeedback.lightImpact();
  }

  /// Whether the phone played it: false when silent or Do Not Disturb keeps
  /// it quiet.
  Future<bool> _buzz(Duration length) async {
    try {
      return await _channel.invokeMethod<bool>('buzz', {
            'ms': length.inMilliseconds,
          }) ??
          true;
    } on PlatformException {
      // A phone that can't or won't vibrate: the screen still shows the end.
      return true;
    }
  }
}

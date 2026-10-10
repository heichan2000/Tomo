/// The two haptics Tomo has (spec §11.5, ADR-0013). Tomo plays no audio.
enum Haptic {
  /// Fired by each beat as it plays; the same tap for all five kinds.
  rewardTap,

  /// A block or break ended while Tomo is open and no beat will play.
  timerBuzz,
  none,
}

/// The haptic for a block or a break ending.
///
/// One event never fires both: if a beat will play, the answer is the reward
/// tap, and that tap is the one the beat itself fires. Stop early, anything
/// during a running block and ordinary taps are silent on purpose.
Haptic hapticFor({required bool isForeground, required bool beatWillPlay}) =>
    beatWillPlay
    ? Haptic.rewardTap
    : isForeground
    ? Haptic.timerBuzz
    : Haptic.none;

/// What the app implements in `lib/platform/` to reach the phone's haptics.
/// Nothing may rely on a haptic as its only signal: a system setting can
/// swallow one silently.
abstract interface class HapticPlayer {
  Future<void> play(Haptic haptic);
}

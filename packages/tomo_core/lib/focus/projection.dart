import 'live_cycle.dart';

/// Where the focus cycle stands (spec §4.1).
enum FocusState {
  /// No cycle. With a task picked, this is Focus's Ready screen.
  idle,
  focusRunning,

  /// The block has ended; awaiting the next action.
  focusComplete,
  breakRunning,
  breakComplete,
}

/// Something the caller must do because of where the cycle stands.
enum FocusEffect {
  /// The block completed and is not yet recorded: settle it, exactly once.
  settle,

  /// The clock moved back past the block's start: discard the cycle at zero
  /// and show the clock notice.
  clockNotice,
}

/// The machine is a projection (spec §4.2): where [cycle] stands at [now], and
/// what that calls for.
///
/// There are no tick, timer-fired or resumed events. This one pure function
/// drives the live screen and a cold start days later alike, which is why a
/// completed block is never lost and never credited twice.
({FocusState state, Set<FocusEffect> effects}) project(
  LiveCycle? cycle,
  DateTime now,
) {
  if (cycle == null) return (state: FocusState.idle, effects: const {});
  if (now.isBefore(cycle.startAt)) {
    return (state: FocusState.idle, effects: const {FocusEffect.clockNotice});
  }
  if (now.isBefore(cycle.endAt)) {
    return (state: FocusState.focusRunning, effects: const {});
  }

  // The block has completed. Whatever comes after, it is owed until recorded.
  final effects = cycle.isCredited
      ? const <FocusEffect>{}
      : const {FocusEffect.settle};
  final breakEndAt = cycle.breakEndAt;

  if (cycle.breakSkippedAt != null) {
    return (state: FocusState.breakComplete, effects: effects);
  }
  if (breakEndAt == null) {
    return (state: FocusState.focusComplete, effects: effects);
  }
  return (
    state: now.isBefore(breakEndAt)
        ? FocusState.breakRunning
        : FocusState.breakComplete,
    effects: effects,
  );
}

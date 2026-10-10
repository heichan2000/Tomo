import 'projection.dart';

/// What the user can do to the focus cycle (spec §4.3).
///
/// Marking a task done is **not** here: it is a task write, and it leaves the
/// cycle where it is.
enum FocusCommand {
  startBlock,

  /// The only way a running block ends before its end instant. Earns zero.
  stopEarly,
  takeBreak,
  skipBreak,

  /// *Done for now*, or Android back from a complete state.
  leave,
}

/// Where each command leads from each state. A pair that is missing is
/// illegal.
const _transitions = <FocusState, Map<FocusCommand, FocusState>>{
  FocusState.idle: {FocusCommand.startBlock: FocusState.focusRunning},
  FocusState.focusRunning: {FocusCommand.stopEarly: FocusState.idle},
  FocusState.focusComplete: {
    FocusCommand.startBlock: FocusState.focusRunning,
    FocusCommand.takeBreak: FocusState.breakRunning,
    FocusCommand.leave: FocusState.idle,
  },
  FocusState.breakRunning: {
    // Starting a block here skips the rest of the break.
    FocusCommand.startBlock: FocusState.focusRunning,
    FocusCommand.skipBreak: FocusState.breakComplete,
    FocusCommand.leave: FocusState.idle,
  },
  FocusState.breakComplete: {
    FocusCommand.startBlock: FocusState.focusRunning,
    FocusCommand.leave: FocusState.idle,
  },
};

/// Whether [command] may be issued in [state].
bool isLegal(FocusState state, FocusCommand command) =>
    _transitions[state]!.containsKey(command);

/// The state [command] leads to from [state].
///
/// An illegal pair is a programming error: it fails an `assert` in debug and
/// tests, and in release returns null, which the caller treats as "do
/// nothing".
FocusState? stateAfter(FocusState state, FocusCommand command) {
  final target = _transitions[state]![command];
  assert(target != null, '${command.name} is illegal in ${state.name}');
  return target;
}

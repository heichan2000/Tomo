import 'projection.dart';

/// What Focus offers once a block or a break has ended (spec §8.5).
enum FocusChoice {
  /// *Take a 5-min break*, at the cycle's own break length.
  takeBreak,

  /// *Another 25-min block* on the same task, after a block.
  anotherBlock,

  /// *Start another block* on the same task, after a break.
  startAnotherBlock,

  /// *Mark task done*: a task write, which leaves the cycle where it is.
  markTaskDone,

  /// *Start another task*: the task picker.
  startAnotherTask,

  /// *Done for now*, which is *Leave*.
  doneForNow,
}

/// How a choice's button looks: the accent, the sunken shade, or text.
enum ChoiceWeight { primary, secondary, quiet }

/// The choices [state] offers, in order, each with its weight (spec §8.5).
///
/// A done task gets no next block, whichever way it became done
/// (promise 39). While the estimate card shows, its own *Mark done* stands
/// in for *Mark task done*. A block or a break still running offers none.
List<(FocusChoice, ChoiceWeight)> choicesAfter(
  FocusState state, {
  required bool taskDone,
  required bool estimateCard,
}) => switch (state) {
  FocusState.focusComplete when taskDone => const [
    (FocusChoice.takeBreak, ChoiceWeight.primary),
    (FocusChoice.startAnotherTask, ChoiceWeight.secondary),
    (FocusChoice.doneForNow, ChoiceWeight.quiet),
  ],
  FocusState.focusComplete => [
    (FocusChoice.takeBreak, ChoiceWeight.primary),
    (FocusChoice.anotherBlock, ChoiceWeight.secondary),
    if (!estimateCard) (FocusChoice.markTaskDone, ChoiceWeight.quiet),
  ],
  FocusState.breakComplete when taskDone => const [
    (FocusChoice.startAnotherTask, ChoiceWeight.primary),
    (FocusChoice.doneForNow, ChoiceWeight.quiet),
  ],
  FocusState.breakComplete => const [
    (FocusChoice.startAnotherBlock, ChoiceWeight.primary),
    (FocusChoice.markTaskDone, ChoiceWeight.secondary),
    (FocusChoice.doneForNow, ChoiceWeight.quiet),
  ],
  FocusState.idle ||
  FocusState.focusRunning ||
  FocusState.breakRunning => const [],
};

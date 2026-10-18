import 'package:test/test.dart';
import 'package:tomo_core/focus/choices.dart';
import 'package:tomo_core/focus/projection.dart';

/// The choices after a block or a break (spec §8.5). Promise 39, the
/// choices' half: a cycle whose task is done offers no next block.
void main() {
  List<(FocusChoice, ChoiceWeight)> after(
    FocusState state, {
    bool taskDone = false,
    bool estimateCard = false,
  }) => choicesAfter(state, taskDone: taskDone, estimateCard: estimateCard);

  test('after a block: a break, another block, or mark the task done', () {
    expect(after(FocusState.focusComplete), [
      (FocusChoice.takeBreak, ChoiceWeight.primary),
      (FocusChoice.anotherBlock, ChoiceWeight.secondary),
      (FocusChoice.markTaskDone, ChoiceWeight.quiet),
    ]);
  });

  test('while the estimate card shows, Mark task done hides', () {
    expect(after(FocusState.focusComplete, estimateCard: true), [
      (FocusChoice.takeBreak, ChoiceWeight.primary),
      (FocusChoice.anotherBlock, ChoiceWeight.secondary),
    ]);
  });

  test('after a block whose task is done: a break, another task, or leave', () {
    expect(after(FocusState.focusComplete, taskDone: true), [
      (FocusChoice.takeBreak, ChoiceWeight.primary),
      (FocusChoice.startAnotherTask, ChoiceWeight.secondary),
      (FocusChoice.doneForNow, ChoiceWeight.quiet),
    ]);
  });

  test('break over: another block, mark the task done, or leave', () {
    expect(after(FocusState.breakComplete), [
      (FocusChoice.startAnotherBlock, ChoiceWeight.primary),
      (FocusChoice.markTaskDone, ChoiceWeight.secondary),
      (FocusChoice.doneForNow, ChoiceWeight.quiet),
    ]);
  });

  test('break over with the task done: another task, or leave', () {
    expect(after(FocusState.breakComplete, taskDone: true), [
      (FocusChoice.startAnotherTask, ChoiceWeight.primary),
      (FocusChoice.doneForNow, ChoiceWeight.quiet),
    ]);
  });

  test('a done task never offers another block on it', () {
    for (final state in [FocusState.focusComplete, FocusState.breakComplete]) {
      final offered = after(state, taskDone: true).map((c) => c.$1);
      expect(offered, isNot(contains(FocusChoice.anotherBlock)));
      expect(offered, isNot(contains(FocusChoice.startAnotherBlock)));
      expect(offered, isNot(contains(FocusChoice.markTaskDone)));
    }
  });

  test('nothing is offered while a block or a break runs, or in idle', () {
    for (final state in [
      FocusState.idle,
      FocusState.focusRunning,
      FocusState.breakRunning,
    ]) {
      expect(after(state), isEmpty);
    }
  });
}

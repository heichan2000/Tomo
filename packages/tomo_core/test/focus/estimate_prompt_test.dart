import 'package:test/test.dart';
import 'package:tomo_core/focus/estimate_prompt.dart';

/// When the estimate prompt is due (spec §4.9). Promise 8, the condition.
void main() {
  final earlier = DateTime.utc(2026, 10, 9);

  test('due when the finished blocks reach the plan', () {
    expect(
      estimatePromptDue(
        estimate: 3,
        actualPomodoros: 3,
        estimatePromptedAt: null,
      ),
      isTrue,
    );
  });

  test('due when the finished blocks have passed the plan', () {
    expect(
      estimatePromptDue(
        estimate: 3,
        actualPomodoros: 5,
        estimatePromptedAt: null,
      ),
      isTrue,
    );
  });

  test('not due while blocks remain in the plan', () {
    expect(
      estimatePromptDue(
        estimate: 3,
        actualPomodoros: 2,
        estimatePromptedAt: null,
      ),
      isFalse,
    );
  });

  test('never due for a task with no plan', () {
    expect(
      estimatePromptDue(
        estimate: null,
        actualPomodoros: 40,
        estimatePromptedAt: null,
      ),
      isFalse,
    );
  });

  test('never due twice: once prompted, always prompted', () {
    expect(
      estimatePromptDue(
        estimate: 3,
        actualPomodoros: 3,
        estimatePromptedAt: earlier,
      ),
      isFalse,
    );
  });

  test('raising the plan after the prompt does not re-arm it', () {
    expect(
      estimatePromptDue(
        estimate: 6,
        actualPomodoros: 6,
        estimatePromptedAt: earlier,
      ),
      isFalse,
    );
  });
}

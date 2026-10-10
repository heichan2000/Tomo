/// Whether the estimate prompt is due for a task (spec §4.9).
///
/// It fires once per task, ever: when the finished blocks reach the plan, and
/// only if it has never fired. Changing the plan afterwards does not re-arm
/// it, because [estimatePromptedAt] is never cleared.
bool estimatePromptDue({
  required int? estimate,
  required int actualPomodoros,
  required DateTime? estimatePromptedAt,
}) =>
    estimate != null &&
    actualPomodoros >= estimate &&
    estimatePromptedAt == null;

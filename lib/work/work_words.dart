import 'package:tomo_core/tasks/task.dart';
import 'package:tomo_core/tasks/task_status.dart';

import '../l10n/app_localizations.dart';

/// The line under a project's name (spec §8.8): `4 open · 3 done`, `All 2
/// done` or `No tasks`. Never a progress bar: done over total would drop
/// each time a task is added.
String projectCounts(
  AppLocalizations l, {
  required int open,
  required int done,
}) {
  if (open > 0) return l.projectCounts(open, done);
  if (done > 0) return l.projectAllDone(done);
  return l.projectNoTasks;
}

/// A task row's blocks, in words (spec §8.8): `2 of 4 blocks`, over the plan
/// `5 blocks · planned 4`, with no plan `1 block`; null with neither a plan
/// nor a block. No colour, warning or "over" word.
String? taskMeta(AppLocalizations l, Task task) {
  final done = task.actualPomodoros;
  final planned = task.estimate;
  if (planned == null) return done == 0 ? null : l.taskBlocks(done);
  return done > planned
      ? l.taskBlocksOverPlan(done, planned)
      : l.taskBlocksOfPlan(done, planned);
}

/// A status in words, as the status control says it.
String statusName(AppLocalizations l, TaskStatus status) => switch (status) {
  TaskStatus.todo => l.statusTodo,
  TaskStatus.doing => l.statusDoing,
  TaskStatus.done => l.statusDone,
};

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tomo_core/tasks/task.dart';
import 'package:tomo_core/tasks/task_service.dart';

import '../app/providers.dart';

/// What the Work screens watch (spec §8.8): every project with its tasks
/// counted, and one project's tasks.
abstract interface class WorkLists {
  /// Every project, the most recently active first, with its open and done
  /// tasks counted.
  Stream<List<ProjectSummary>> projects();

  /// A project's tasks: doing, then to-do, then done; the most recently
  /// touched first in each.
  Stream<List<Task>> tasksIn(int projectId);
}

/// Where the Work screens hear of a change: the database. Widget tests of
/// the whole app replace it, because the database's watched queries can't
/// run on a widget test's pretend clock (spec §17 C72).
final workListsProvider = Provider<WorkLists>(
  (ref) => _Watched(ref.watch(taskServiceProvider)),
);

final projectSummariesProvider = StreamProvider.autoDispose(
  (ref) => ref.watch(workListsProvider).projects(),
);

final projectTasksProvider = StreamProvider.autoDispose.family<List<Task>, int>(
  (ref, projectId) => ref.watch(workListsProvider).tasksIn(projectId),
);

final class _Watched implements WorkLists {
  const _Watched(this._tasks);

  final TaskService _tasks;

  @override
  Stream<List<ProjectSummary>> projects() => _tasks.watchProjectSummaries();

  @override
  Stream<List<Task>> tasksIn(int projectId) =>
      _tasks.watchTasksInProject(projectId);
}

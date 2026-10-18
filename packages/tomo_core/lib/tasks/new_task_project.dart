import 'task.dart';
import 'task_service.dart' show TaskService;

/// The project the task picker's *New task* goes into (spec §8.1): the
/// last-used one (spec §6.3), or, when none is remembered or it has been
/// deleted, the most recently active. [projects] are the most recently
/// active first, as [TaskService.projects] gives them.
///
/// Null when there are no projects at all.
Project? newTaskProject(List<Project> projects, {required int? lastUsedId}) {
  for (final project in projects) {
    if (project.id == lastUsedId) return project;
  }
  return projects.firstOrNull;
}

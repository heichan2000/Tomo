import 'task_status.dart';

/// A task, as the screens see it.
///
/// The earned numbers ([actualPomodoros], [cumulativeFocusMinutes],
/// [lastFocusedAt], [estimatePromptedAt], [completionBonusGrantedAt]) can be
/// read here and set nowhere: [TaskPatch] has no field for them. Only the
/// settle and the completion bonus move them (spec §5.4).
final class Task {
  const Task({
    required this.id,
    required this.projectId,
    required this.title,
    required this.notes,
    required this.status,
    required this.estimate,
    required this.actualPomodoros,
    required this.cumulativeFocusMinutes,
    required this.estimatePromptedAt,
    required this.completionBonusGrantedAt,
    required this.createdAt,
    required this.lastFocusedAt,
    required this.completedAt,
  });

  final int id;
  final int projectId;
  final String title;
  final String? notes;
  final TaskStatus status;

  /// Planned blocks, 1 to 20. Null is "no plan".
  final int? estimate;

  /// Finished blocks.
  final int actualPomodoros;
  final int cumulativeFocusMinutes;
  final DateTime? estimatePromptedAt;
  final DateTime? completionBonusGrantedAt;
  final DateTime createdAt;
  final DateTime? lastFocusedAt;
  final DateTime? completedAt;

  /// The status one tap on a done task's ring gives it back: doing if it has
  /// any finished blocks, otherwise to-do. No "previous status" is stored
  /// (spec §5.4).
  TaskStatus get reopensTo =>
      actualPomodoros > 0 ? TaskStatus.doing : TaskStatus.todo;

  @override
  bool operator ==(Object other) =>
      other is Task &&
      other.id == id &&
      other.projectId == projectId &&
      other.title == title &&
      other.notes == notes &&
      other.status == status &&
      other.estimate == estimate &&
      other.actualPomodoros == actualPomodoros &&
      other.cumulativeFocusMinutes == cumulativeFocusMinutes &&
      other.estimatePromptedAt == estimatePromptedAt &&
      other.completionBonusGrantedAt == completionBonusGrantedAt &&
      other.createdAt == createdAt &&
      other.lastFocusedAt == lastFocusedAt &&
      other.completedAt == completedAt;

  @override
  int get hashCode => Object.hash(
    id,
    projectId,
    title,
    notes,
    status,
    estimate,
    actualPomodoros,
    cumulativeFocusMinutes,
    estimatePromptedAt,
    completionBonusGrantedAt,
    createdAt,
    lastFocusedAt,
    completedAt,
  );
}

/// A project, as the screens see it.
final class Project {
  const Project({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  final int id;
  final String name;
  final DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      other is Project &&
      other.id == id &&
      other.name == name &&
      other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(id, name, createdAt);
}

/// A project with its tasks counted, as a row on the Work tab says it:
/// `4 open · 3 done` (spec §8.8). To-do and doing are open.
final class ProjectSummary {
  const ProjectSummary(this.project, {required this.open, required this.done});

  final Project project;
  final int open;
  final int done;

  @override
  bool operator ==(Object other) =>
      other is ProjectSummary &&
      other.project == project &&
      other.open == open &&
      other.done == done;

  @override
  int get hashCode => Object.hash(project, open, done);
}

/// A new value for a field that can also be cleared. `Edit(null)` clears it;
/// leaving the patch's field null leaves the task's alone.
final class Edit<T> {
  const Edit(this.value);

  final T value;
}

/// The changes to make to a task. A field left null is left alone.
///
/// These five are all a caller can change. The earned numbers are not here.
final class TaskPatch {
  const TaskPatch({
    this.title,
    this.notes,
    this.estimate,
    this.projectId,
    this.status,
  });

  final String? title;

  /// Blank notes clear them.
  final Edit<String?>? notes;

  /// Planned blocks, 1 to 20, or `Edit(null)` for no plan.
  final Edit<int?>? estimate;

  /// Moves the task to this project.
  final int? projectId;
  final TaskStatus? status;
}

/// The task the live focus cycle is on, with the project it is in now: what
/// Focus's header and the running banner name.
final class CycleTask {
  const CycleTask(this.task, this.project);

  final Task task;
  final Project project;
}

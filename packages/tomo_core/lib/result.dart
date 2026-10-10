/// What a write hands back (spec §5.2): success, or one of five named errors.
///
/// Writes never throw. Both types are sealed, so a `switch` that forgets a
/// case fails to compile.
sealed class Result<T> {
  const Result();
}

final class Success<T> extends Result<T> {
  const Success(this.value);

  final T value;
}

final class Failure<T> extends Result<T> {
  const Failure(this.error);

  final WriteError error;
}

/// The sealed set of five.
sealed class WriteError {
  const WriteError();
}

/// What kind of thing was not found.
enum EntityKind { task, project }

/// The task or project doesn't exist.
final class NotFound extends WriteError {
  const NotFound(this.kind, this.id);

  final EntityKind kind;
  final int id;

  @override
  bool operator ==(Object other) =>
      other is NotFound && other.kind == kind && other.id == id;

  @override
  int get hashCode => Object.hash(kind, id);
}

/// The fields a validation rule can refuse.
enum InvalidField {
  taskTitle,
  notes,
  estimate,
  projectName,
  focusMinutes,
  breakMinutes,
}

enum InvalidRule { empty, tooLong, outOfRange }

/// A validation rule failed.
final class Invalid extends WriteError {
  const Invalid(this.field, this.rule, {this.limit});

  final InvalidField field;
  final InvalidRule rule;

  /// The limit that was passed: a maximum length, or the nearer end of a
  /// range. Null for [InvalidRule.empty].
  final int? limit;

  @override
  bool operator ==(Object other) =>
      other is Invalid &&
      other.field == field &&
      other.rule == rule &&
      other.limit == limit;

  @override
  int get hashCode => Object.hash(field, rule, limit);
}

/// The task lock refused: a focus block is running on this task (ADR-0024).
final class BlockRunning extends WriteError {
  const BlockRunning(this.taskId);

  final int taskId;

  @override
  bool operator ==(Object other) =>
      other is BlockRunning && other.taskId == taskId;

  @override
  int get hashCode => taskId.hashCode;
}

/// A block was asked for on a done task.
final class TaskDone extends WriteError {
  const TaskDone(this.taskId);

  final int taskId;

  @override
  bool operator ==(Object other) => other is TaskDone && other.taskId == taskId;

  @override
  int get hashCode => taskId.hashCode;
}

/// The database failed. It carries nothing; a diagnostic entry was written.
final class StorageFailed extends WriteError {
  const StorageFailed();

  @override
  bool operator ==(Object other) => other is StorageFailed;

  @override
  int get hashCode => 0;
}

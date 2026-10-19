import 'dart:async';

import 'package:characters/characters.dart';
import 'package:drift/drift.dart';

import '../data/instants.dart';
import '../data/tomo_database.dart';
import '../diagnostics/diagnostic_entry.dart';
import '../diagnostics/log.dart';
import '../focus/cycle_ledger.dart';
import '../focus/projection.dart';
import '../result.dart';
import '../rewards/rewards.dart';
import 'task.dart';
import 'task_status.dart';

const maxTaskTitleLength = 200;
const maxNotesLength = 5000;
const maxProjectNameLength = 60;
const minEstimate = 1;
const maxEstimate = 20;

/// The one service that owns every task and project write (spec §5).
///
/// Each write is one transaction, returns a [Result] and never throws. The
/// writes are fixed; screens may add reads freely, because a read can't break
/// a rule.
abstract interface class TaskService {
  ///
  /// [afterWrite] runs, unawaited, after each write that commits: the app
  /// syncs the notifications there, because a write can end or settle the
  /// cycle (spec §11.2).
  factory TaskService(
    TomoDatabase db, {
    required Log log,
    UtcOffsetAt? utcOffsetAt,
    Future<void> Function()? afterWrite,
  }) = _DriftTaskService;

  /// A new task is always to-do.
  Future<Result<Task>> createTask({
    required int projectId,
    required String title,
    String? notes,
    int? estimate,
  });

  /// Changes a task's title, notes, planned blocks, project or status.
  ///
  /// **The completion bonus lives here**: any change into done pays it, once
  /// per task, ever. While a block is running on the task, marking it done is
  /// refused with [BlockRunning].
  Future<Result<Task>> updateTask(int id, TaskPatch patch);

  /// Deletes a task for good. Its block records stay, unlinked (ADR-0022).
  /// Refused with [BlockRunning] while a block is running on it.
  Future<Result<void>> deleteTask(int id);

  Future<Result<Project>> createProject(String name);
  Future<Result<Project>> renameProject(int id, String name);

  /// Deletes a project and its tasks. Refused with [BlockRunning] while a
  /// block is running on one of them.
  Future<Result<void>> deleteProject(int id);

  /// Every project, the most recently active first.
  Stream<List<Project>> watchProjects();

  /// [watchProjects]'s list, each project with its open and done tasks
  /// counted: the Work tab.
  Stream<List<ProjectSummary>> watchProjectSummaries();

  /// [watchProjectSummaries]'s list, read once.
  Future<List<ProjectSummary>> projectSummaries();

  /// A project's tasks: doing, then to-do, then done; within each, the most
  /// recently touched first.
  Stream<List<Task>> watchTasksInProject(int id);

  /// [watchTasksInProject]'s list, read once.
  Future<List<Task>> tasksInProject(int id);

  /// The tasks a block can start on: doing, then to-do, the most recently
  /// focused first. No done tasks.
  Stream<List<Task>> watchPickerTasks();

  /// One task. Null means it has been deleted.
  Stream<Task?> watchTask(int id);

  /// [watchPickerTasks]'s list, read once: the task picker is a sheet over
  /// everything, and nothing else writes while it is open.
  Future<List<Task>> pickerTasks();

  /// [watchProjects]'s list, read once, for the task picker.
  Future<List<Project>> projects();

  /// The task the live cycle is on, and its project; null without a cycle.
  Future<CycleTask?> cycleTask();

  /// [cycleTask] now and each time the cycle, the task or its project
  /// changes: a rename or a move while Focus is minimised shows on the
  /// banner.
  Stream<CycleTask?> watchCycleTask();
}

final class _DriftTaskService implements TaskService {
  _DriftTaskService(
    this._db, {
    required this._log,
    UtcOffsetAt? utcOffsetAt,
    this._afterWrite,
  }) : _ledger = CycleLedger(_db, utcOffsetAt: utcOffsetAt);

  final TomoDatabase _db;
  final Log _log;
  final CycleLedger _ledger;
  final Future<void> Function()? _afterWrite;

  @override
  Future<Result<Task>> createTask({
    required int projectId,
    required String title,
    String? notes,
    int? estimate,
  }) {
    final String cleanTitle;
    final String? cleanNotes;
    try {
      cleanTitle = _validTitle(title);
      cleanNotes = _validNotes(notes);
      _checkEstimate(estimate);
    } on _Refused catch (refused) {
      return Future.value(Failure(refused.error));
    }

    return _write((now) async {
      await _requireProject(projectId);
      final id = await _db
          .into(_db.tasks)
          .insert(
            TasksCompanion.insert(
              projectId: projectId,
              title: cleanTitle,
              notes: Value(cleanNotes),
              estimatedPomodoros: Value(estimate),
              createdAt: epochMs(now),
            ),
          );
      return _task(await _requireTask(id));
    });
  }

  @override
  Future<Result<Task>> updateTask(int id, TaskPatch patch) {
    final String? cleanTitle;
    final Edit<String?>? cleanNotes;
    try {
      cleanTitle = patch.title == null ? null : _validTitle(patch.title!);
      cleanNotes = patch.notes == null
          ? null
          : Edit(_validNotes(patch.notes!.value));
      if (patch.estimate != null) _checkEstimate(patch.estimate!.value);
    } on _Refused catch (refused) {
      return Future.value(Failure(refused.error));
    }

    return _write((now) async {
      // Settle a finished block first, so a change into done counts it.
      final standing = await _ledger.reconcile(now);
      final before = await _requireTask(id);
      if (patch.projectId != null) await _requireProject(patch.projectId!);

      final status = patch.status;
      final enteringDone =
          status == TaskStatus.done && before.status != TaskStatus.done;
      final leavingDone =
          status != null &&
          status != TaskStatus.done &&
          before.status == TaskStatus.done;
      if (enteringDone && _isRunningOn(standing, id)) {
        throw _Refused(BlockRunning(id));
      }

      final payBonus = enteringDone && before.completionBonusGrantedAt == null;
      if (payBonus) {
        final pet = await _db.select(_db.pets).getSingle();
        await (_db.update(_db.pets)..where((p) => p.id.equals(pet.id))).write(
          PetsCompanion(
            exp: Value(
              addExp(
                pet.exp,
                completionBonus(
                  cumulativeFocusMinutes: before.cumulativeFocusMinutes,
                ),
              ),
            ),
          ),
        );
      }

      await (_db.update(_db.tasks)..where((t) => t.id.equals(id))).write(
        TasksCompanion(
          title: Value.absentIfNull(cleanTitle),
          notes: cleanNotes == null
              ? const Value.absent()
              : Value(cleanNotes.value),
          estimatedPomodoros: patch.estimate == null
              ? const Value.absent()
              : Value(patch.estimate!.value),
          projectId: Value.absentIfNull(patch.projectId),
          status: Value.absentIfNull(status),
          completedAt: enteringDone
              ? Value(epochMs(now))
              : leavingDone
              ? const Value(null)
              : const Value.absent(),
          completionBonusGrantedAt: payBonus
              ? Value(epochMs(now))
              : const Value.absent(),
        ),
      );
      return _task(await _requireTask(id));
    });
  }

  @override
  Future<Result<void>> deleteTask(int id) => _write((now) async {
    final standing = await _ledger.reconcile(now);
    await _requireTask(id);
    if (_isRunningOn(standing, id)) throw _Refused(BlockRunning(id));

    // A finished cycle on this task ends as Leave does; its block is already
    // settled, and its record outlives the task (ADR-0022).
    if (standing.cycle?.taskId == id) await _ledger.end();
    await (_db.delete(_db.tasks)..where((t) => t.id.equals(id))).go();
  });

  @override
  Future<Result<Project>> createProject(String name) {
    final String cleanName;
    try {
      cleanName = _validProjectName(name);
    } on _Refused catch (refused) {
      return Future.value(Failure(refused.error));
    }

    return _write((now) async {
      final id = await _db
          .into(_db.projects)
          .insert(
            ProjectsCompanion.insert(name: cleanName, createdAt: epochMs(now)),
          );
      return _project(await _requireProject(id));
    });
  }

  @override
  Future<Result<Project>> renameProject(int id, String name) {
    final String cleanName;
    try {
      cleanName = _validProjectName(name);
    } on _Refused catch (refused) {
      return Future.value(Failure(refused.error));
    }

    return _write((now) async {
      await _requireProject(id);
      await (_db.update(_db.projects)..where((p) => p.id.equals(id))).write(
        ProjectsCompanion(name: Value(cleanName)),
      );
      return _project(await _requireProject(id));
    });
  }

  @override
  Future<Result<void>> deleteProject(int id) => _write((now) async {
    final standing = await _ledger.reconcile(now);
    await _requireProject(id);

    final cycle = standing.cycle;
    if (cycle != null) {
      final cycleTask = await _ledger.taskRow(cycle.taskId);
      if (cycleTask.projectId == id) {
        if (standing.state == FocusState.focusRunning) {
          throw _Refused(BlockRunning(cycleTask.id));
        }
        await _ledger.end();
      }
    }
    await (_db.delete(_db.projects)..where((p) => p.id.equals(id))).go();
  });

  @override
  Stream<List<Project>> watchProjects() =>
      _projectsByActivity().watch().map(_projects);

  @override
  Future<List<Project>> projects() =>
      _projectsByActivity().get().then(_projects);

  @override
  Stream<List<ProjectSummary>> watchProjectSummaries() =>
      _projectsByActivity().watch().map(_summaries);

  @override
  Future<List<ProjectSummary>> projectSummaries() =>
      _projectsByActivity().get().then(_summaries);

  /// Most recent activity: the latest of the project's own creation and its
  /// tasks' creation, last focus and completion. Each row also counts the
  /// project's open and done tasks.
  Selectable<QueryRow> _projectsByActivity() => _db.customSelect(
    'SELECT p.*, MAX(p.created_at, COALESCE(MAX(MAX(t.created_at, '
    'COALESCE(t.last_focused_at, 0), COALESCE(t.completed_at, 0))), 0)) '
    'AS activity, '
    "COUNT(t.id) - COUNT(CASE WHEN t.status = 'done' THEN 1 END) "
    'AS open_tasks, '
    "COUNT(CASE WHEN t.status = 'done' THEN 1 END) AS done_tasks "
    'FROM projects p LEFT JOIN tasks t ON t.project_id = p.id '
    'GROUP BY p.id ORDER BY activity DESC, p.id DESC',
    readsFrom: {_db.projects, _db.tasks},
  );

  List<Project> _projects(List<QueryRow> rows) => [
    for (final row in rows) _project(_db.projects.map(row.data)),
  ];

  List<ProjectSummary> _summaries(List<QueryRow> rows) => [
    for (final row in rows)
      ProjectSummary(
        _project(_db.projects.map(row.data)),
        open: row.read<int>('open_tasks'),
        done: row.read<int>('done_tasks'),
      ),
  ];

  @override
  Stream<List<Task>> watchTasksInProject(int id) =>
      _inProject(id).watch().map((rows) => rows.map(_task).toList());

  @override
  Future<List<Task>> tasksInProject(int id) =>
      _inProject(id).get().then((rows) => rows.map(_task).toList());

  SimpleSelectStatement<$TasksTable, TaskRow> _inProject(int id) =>
      _db.select(_db.tasks)
        ..where((t) => t.projectId.equals(id))
        ..orderBy([
          (t) => OrderingTerm(expression: _statusRank(t)),
          (t) => OrderingTerm.desc(_lastTouched(t)),
          (t) => OrderingTerm.desc(t.id),
        ]);

  @override
  Stream<List<Task>> watchPickerTasks() =>
      _pickerQuery().watch().map((rows) => rows.map(_task).toList());

  @override
  Future<List<Task>> pickerTasks() =>
      _pickerQuery().get().then((rows) => rows.map(_task).toList());

  SimpleSelectStatement<$TasksTable, TaskRow> _pickerQuery() =>
      _db.select(_db.tasks)
        ..where((t) => t.status.equalsValue(TaskStatus.done).not())
        ..orderBy([
          (t) => OrderingTerm(expression: _statusRank(t)),
          (t) =>
              OrderingTerm.desc(coalesce([t.lastFocusedAt, const Constant(0)])),
          (t) => OrderingTerm.desc(t.createdAt),
          (t) => OrderingTerm.desc(t.id),
        ]);

  @override
  Future<CycleTask?> cycleTask() => _cycleTask().getSingleOrNull();

  @override
  Stream<CycleTask?> watchCycleTask() => _cycleTask().watchSingleOrNull();

  Selectable<CycleTask> _cycleTask() =>
      (_db.select(_db.focusCycle).join([
        innerJoin(_db.tasks, _db.tasks.id.equalsExp(_db.focusCycle.taskId)),
        innerJoin(_db.projects, _db.projects.id.equalsExp(_db.tasks.projectId)),
      ])).map(
        (row) => CycleTask(
          _task(row.readTable(_db.tasks)),
          _project(row.readTable(_db.projects)),
        ),
      );

  @override
  Stream<Task?> watchTask(int id) =>
      (_db.select(_db.tasks)..where((t) => t.id.equals(id)))
          .watchSingleOrNull()
          .map((row) => row == null ? null : _task(row));

  /// Doing first, then to-do, then done.
  Expression<int> _statusRank($TasksTable t) => CaseWhenExpression(
    cases: [
      CaseWhen(t.status.equalsValue(TaskStatus.doing), then: const Constant(0)),
      CaseWhen(t.status.equalsValue(TaskStatus.todo), then: const Constant(1)),
    ],
    orElse: const Constant(2),
  );

  /// The latest thing that happened to a task.
  Expression<int> _lastTouched($TasksTable t) => CustomExpression<int>(
    'MAX(tasks.created_at, COALESCE(tasks.last_focused_at, 0), '
    'COALESCE(tasks.completed_at, 0))',
  );

  bool _isRunningOn(CycleStanding standing, int taskId) =>
      standing.state == FocusState.focusRunning &&
      standing.cycle?.taskId == taskId;

  Future<TaskRow> _requireTask(int id) async {
    final row = await (_db.select(
      _db.tasks,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) throw _Refused(NotFound(EntityKind.task, id));
    return row;
  }

  Future<ProjectRow> _requireProject(int id) async {
    final row = await (_db.select(
      _db.projects,
    )..where((p) => p.id.equals(id))).getSingleOrNull();
    if (row == null) throw _Refused(NotFound(EntityKind.project, id));
    return row;
  }

  /// Runs [body] in one transaction at one reading of the clock. A refusal
  /// rolls the transaction back and comes out as its error.
  Future<Result<T>> _write<T>(Future<T> Function(DateTime now) body) async {
    try {
      final value = await _db.transaction(() => body(_db.clock().toUtc()));
      unawaited(_afterWrite?.call());
      return Success(value);
    } on _Refused catch (refused) {
      return Failure(refused.error);
    } catch (error, stackTrace) {
      _log.error(DiagnosticCode.taskWriteFailed, error, stackTrace);
      return const Failure(StorageFailed());
    }
  }
}

/// A rule said no. Thrown inside a write so its transaction rolls back.
final class _Refused implements Exception {
  const _Refused(this.error);

  final WriteError error;
}

/// [name] as a project name would be stored, or why it can't be.
Result<String> checkProjectName(String name) {
  try {
    return Success(_validProjectName(name));
  } on _Refused catch (refused) {
    return Failure(refused.error);
  }
}

String _validTitle(String title) => _required(
  title,
  field: InvalidField.taskTitle,
  maxLength: maxTaskTitleLength,
);

String _validProjectName(String name) => _required(
  name,
  field: InvalidField.projectName,
  maxLength: maxProjectNameLength,
);

/// Trimmed, not empty, and no longer than [maxLength] characters as a reader
/// counts them (grapheme clusters).
String _required(
  String text, {
  required InvalidField field,
  required int maxLength,
}) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) throw _Refused(Invalid(field, InvalidRule.empty));
  if (trimmed.characters.length > maxLength) {
    throw _Refused(Invalid(field, InvalidRule.tooLong, limit: maxLength));
  }
  return trimmed;
}

/// Trimmed; blank is no notes.
String? _validNotes(String? notes) {
  final trimmed = notes?.trim() ?? '';
  if (trimmed.isEmpty) return null;
  if (trimmed.characters.length > maxNotesLength) {
    throw const _Refused(
      Invalid(InvalidField.notes, InvalidRule.tooLong, limit: maxNotesLength),
    );
  }
  return trimmed;
}

void _checkEstimate(int? estimate) {
  if (estimate == null) return;
  if (estimate < minEstimate || estimate > maxEstimate) {
    throw _Refused(
      Invalid(
        InvalidField.estimate,
        InvalidRule.outOfRange,
        limit: estimate < minEstimate ? minEstimate : maxEstimate,
      ),
    );
  }
}

Task _task(TaskRow row) => Task(
  id: row.id,
  projectId: row.projectId,
  title: row.title,
  notes: row.notes,
  status: row.status,
  estimate: row.estimatedPomodoros,
  actualPomodoros: row.actualPomodoros,
  cumulativeFocusMinutes: row.cumulativeFocusMinutes,
  estimatePromptedAt: _instant(row.estimatePromptedAt),
  completionBonusGrantedAt: _instant(row.completionBonusGrantedAt),
  createdAt: utcFromMs(row.createdAt),
  lastFocusedAt: _instant(row.lastFocusedAt),
  completedAt: _instant(row.completedAt),
);

Project _project(ProjectRow row) =>
    Project(id: row.id, name: row.name, createdAt: utcFromMs(row.createdAt));

DateTime? _instant(int? ms) => ms == null ? null : utcFromMs(ms);

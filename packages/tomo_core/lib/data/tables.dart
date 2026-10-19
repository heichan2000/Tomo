/// Tomo's five tables, exactly as spec §6.2 lays them out.
///
/// Conventions: integer ids that are never reused (ADR-0023); every instant an
/// integer of UTC epoch milliseconds named `*_at`, never a Drift `DateTime`;
/// enums stored as their names.
library;

import 'package:drift/drift.dart';

import '../pet/species.dart';
import '../tasks/task_status.dart';

@DataClassName('ProjectRow')
class Projects extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get createdAt => integer()();
}

@DataClassName('TaskRow')
@TableIndex(name: 'tasks_project_id_status', columns: {#projectId, #status})
class Tasks extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Never null: onboarding seeds a project. Deleting it deletes its tasks.
  IntColumn get projectId =>
      integer().references(Projects, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text()();
  TextColumn get notes => text().nullable()();
  TextColumn get status =>
      textEnum<TaskStatus>().withDefault(const Constant('todo'))();

  /// Planned blocks. Null is "no plan".
  IntColumn get estimatedPomodoros => integer().nullable()();

  /// One more per settle.
  IntColumn get actualPomodoros => integer().withDefault(const Constant(0))();

  /// The completion bonus scales on this.
  IntColumn get cumulativeFocusMinutes =>
      integer().withDefault(const Constant(0))();

  /// Set once, never cleared.
  IntColumn get estimatePromptedAt => integer().nullable()();

  /// Set once, never cleared.
  IntColumn get completionBonusGrantedAt => integer().nullable()();
  IntColumn get createdAt => integer()();

  /// Set at settle.
  IntColumn get lastFocusedAt => integer().nullable()();

  /// Set on entering done, cleared on reopening.
  IntColumn get completedAt => integer().nullable()();
}

/// Exactly one row in the MVP. Its existence is "onboarding complete".
@DataClassName('PetRow')
class Pets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get species => textEnum<Species>()();

  /// Null until the hatch names it.
  TextColumn get name => text().nullable()();

  /// Null is the egg.
  IntColumn get hatchedAt => integer().nullable()();

  /// The truth. Level and stage are worked out from it, never stored.
  IntColumn get exp => integer().withDefault(const Constant(0))();
  IntColumn get createdAt => integer()();
}

/// Written once by the settle and never updated, except that deleting a task
/// or project unlinks it (ADR-0022).
@DataClassName('BlockRecordRow')
@TableIndex(name: 'block_records_local_date', columns: {#localDate})
@TableIndex(name: 'block_records_task_id', columns: {#taskId})
class BlockRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get petId => integer().references(Pets, #id)();
  IntColumn get taskId => integer().nullable().references(
    Tasks,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// The project the task had at settle.
  IntColumn get projectId => integer().nullable().references(
    Projects,
    #id,
    onDelete: KeyAction.setNull,
  )();
  IntColumn get startedAt => integer()();
  IntColumn get endedAt => integer()();
  IntColumn get minutes => integer()();

  /// The local day it ended, `YYYY-MM-DD`.
  TextColumn get localDate => text()();

  /// The UTC offset at settle.
  IntColumn get utcOffsetMinutes => integer()();
  IntColumn get expGranted => integer()();

  /// `petExpAfter - expGranted == 0` means this block was the hatch.
  IntColumn get petExpAfter => integer()();
  IntColumn get settledAt => integer()();
}

/// The live focus cycle. At most one row, with id 1; deleted on the way back
/// to idle.
@DataClassName('FocusCycleRow')
class FocusCycle extends Table {
  @override
  String get tableName => 'focus_cycle';

  /// Always 1. Not auto-incremented: that would hand the second cycle id 2,
  /// which the check refuses.
  IntColumn get id => integer().withDefault(const Constant(1))();

  /// The service always ends the cycle before deleting its task (spec §5.4);
  /// RESTRICT is the backstop.
  IntColumn get taskId =>
      integer().references(Tasks, #id, onDelete: KeyAction.restrict)();
  IntColumn get startAt => integer()();
  IntColumn get endAt => integer()();
  IntColumn get focusMinutes => integer()();
  IntColumn get breakMinutes => integer()();

  /// Snapshotted at block start.
  BoolColumn get autoStart => boolean()();

  /// Written by *Take break*, or as `endAt` under auto-start.
  IntColumn get breakStartAt => integer().nullable()();

  /// Written by *Skip break*.
  IntColumn get breakSkippedAt => integer().nullable()();

  /// Not null means the block is credited.
  IntColumn get blockRecordId =>
      integer().nullable().references(BlockRecords, #id)();

  /// The beat run was had (spec §7.4).
  IntColumn get seenAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => ['CHECK (id = 1)'];
}

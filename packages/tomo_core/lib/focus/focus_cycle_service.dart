import 'package:drift/drift.dart';

import '../data/tomo_database.dart';
import '../diagnostics/diagnostic_entry.dart';
import '../diagnostics/log.dart';
import '../result.dart';
import '../rewards/rewards.dart';
import '../tasks/task_status.dart';
import 'block_lengths.dart';
import 'commands.dart';
import 'estimate_prompt.dart';
import 'live_cycle.dart';
import 'projection.dart';

/// The phone's UTC offset at [instant], for the local day a block ended in.
typedef UtcOffsetAt = Duration Function(DateTime instant);

/// Where the focus cycle stands after a command or a look.
final class CycleStanding {
  const CycleStanding({
    required this.state,
    this.cycle,
    this.clockNotice = false,
  });

  final FocusState state;

  /// The live cycle. Null when [state] is idle.
  final LiveCycle? cycle;

  /// The clock had moved back past the block's start, so the block was
  /// discarded at zero. Show the clock notice (spec §4.4).
  final bool clockNotice;
}

/// The focus cycle against the database: the five commands and the settle
/// (spec §4.3 to §4.9).
///
/// Every method first brings the stored cycle up to now ([reconcile]), so a
/// finished block is always settled before anything else happens to it. Each
/// runs in one transaction and never throws: a database failure comes back as
/// [StorageFailed], with a diagnostic entry written.
final class FocusCycleService {
  FocusCycleService(this._db, {required this._log, UtcOffsetAt? utcOffsetAt})
    : _utcOffsetAt = utcOffsetAt ?? _phoneUtcOffsetAt;

  final TomoDatabase _db;
  final Log _log;
  final UtcOffsetAt _utcOffsetAt;

  static Duration _phoneUtcOffsetAt(DateTime instant) =>
      instant.toLocal().timeZoneOffset;

  /// Brings the stored cycle up to now and says where it stands.
  ///
  /// A block whose end has passed is settled here, exactly once. A cycle whose
  /// start is in the future (the clock moved backward) is discarded at zero.
  /// Call it on every start, every resume, and whenever the screen re-reads
  /// the cycle.
  Future<Result<CycleStanding>> reconcile() =>
      _write((now) async => Success(await _reconcile(now)));

  /// Starts a focus block on [taskId], replacing any finished cycle.
  ///
  /// Fails with [Invalid] for a length outside the limits, [NotFound] for a
  /// missing task and [TaskDone] for a done one. A to-do task becomes doing in
  /// the same transaction.
  Future<Result<CycleStanding>> startBlock({
    required int taskId,
    required BlockLengths lengths,
    required bool autoStart,
  }) {
    final refusal = _checkLengths(lengths);
    if (refusal != null) return Future.value(Failure(refusal));

    return _write((now) async {
      final standing = await _reconcile(now);
      if (stateAfter(standing.state, FocusCommand.startBlock) == null) {
        return Success(standing);
      }

      final task = await (_db.select(
        _db.tasks,
      )..where((t) => t.id.equals(taskId))).getSingleOrNull();
      if (task == null) {
        return Failure(NotFound(EntityKind.task, taskId));
      }
      if (task.status == TaskStatus.done) return Failure(TaskDone(taskId));

      if (task.status == TaskStatus.todo) {
        await (_db.update(_db.tasks)..where((t) => t.id.equals(taskId))).write(
          const TasksCompanion(status: Value(TaskStatus.doing)),
        );
      }

      final cycle = LiveCycle(
        taskId: taskId,
        startAt: now,
        endAt: now.add(Duration(minutes: lengths.focusMinutes)),
        focusMinutes: lengths.focusMinutes,
        breakMinutes: lengths.breakMinutes,
        autoStart: autoStart,
      );
      // Replacing a finished cycle drops its unseen beat run; the EXP stays.
      await _db.delete(_db.focusCycle).go();
      await _db
          .into(_db.focusCycle)
          .insert(
            FocusCycleCompanion.insert(
              taskId: cycle.taskId,
              startAt: _ms(cycle.startAt),
              endAt: _ms(cycle.endAt),
              focusMinutes: cycle.focusMinutes,
              breakMinutes: cycle.breakMinutes,
              autoStart: cycle.autoStart,
            ),
          );
      return Success(
        CycleStanding(
          state: FocusState.focusRunning,
          cycle: cycle,
          clockNotice: standing.clockNotice,
        ),
      );
    });
  }

  /// Ends a running block before its end. It earns nothing and leaves no
  /// trace (spec §4.6).
  ///
  /// If the end passed while the confirmation was open, the block
  /// **completed**: it is credited, and this returns that standing instead.
  Future<Result<CycleStanding>> stopEarly() => _write((now) async {
    final standing = await _reconcile(now);
    if (standing.state != FocusState.focusRunning) {
      // Idle is a caller's mistake; a complete state is the block finishing
      // under the open confirmation, which is nobody's.
      if (standing.state == FocusState.idle) {
        stateAfter(standing.state, FocusCommand.stopEarly);
      }
      return Success(standing);
    }
    await _db.delete(_db.focusCycle).go();
    return const Success(CycleStanding(state: FocusState.idle));
  });

  /// Starts the break after a finished block.
  Future<Result<CycleStanding>> takeBreak() => _command(
    FocusCommand.takeBreak,
    (now) => FocusCycleCompanion(breakStartAt: Value(_ms(now))),
  );

  /// Ends a running break now. Never penalised.
  Future<Result<CycleStanding>> skipBreak() => _command(
    FocusCommand.skipBreak,
    (now) => FocusCycleCompanion(breakSkippedAt: Value(_ms(now))),
  );

  /// *Done for now*: ends the cycle. An unseen beat run goes with it; the EXP
  /// stays.
  Future<Result<CycleStanding>> leave() => _write((now) async {
    final standing = await _reconcile(now);
    if (stateAfter(standing.state, FocusCommand.leave) == null) {
      return Success(standing);
    }
    await _db.delete(_db.focusCycle).go();
    return const Success(CycleStanding(state: FocusState.idle));
  });

  /// Records that the beat run was had: it finished, was skipped, or was
  /// walked away from (spec §7.4). After this it never plays again.
  Future<Result<CycleStanding>> markBeatRunSeen() => _write((now) async {
    final standing = await _reconcile(now);
    final cycle = standing.cycle;
    if (cycle == null || !cycle.isCredited || cycle.seenAt != null) {
      return Success(standing);
    }
    await _db
        .update(_db.focusCycle)
        .write(FocusCycleCompanion(seenAt: Value(_ms(now))));
    return Success(await _reconcile(now));
  });

  /// Whether to show the estimate prompt now for the cycle's task (spec §4.9).
  ///
  /// It answers true **once per task, ever**: answering true is what marks the
  /// task as prompted.
  Future<Result<bool>> takeEstimatePrompt() => _write((now) async {
    final cycle = (await _reconcile(now)).cycle;
    if (cycle == null || !cycle.isCredited) return const Success(false);

    final task = await _task(cycle.taskId);
    final promptedAt = task.estimatePromptedAt;
    final due = estimatePromptDue(
      estimate: task.estimatedPomodoros,
      actualPomodoros: task.actualPomodoros,
      estimatePromptedAt: promptedAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(promptedAt, isUtc: true),
    );
    if (!due) return const Success(false);

    await (_db.update(_db.tasks)..where((t) => t.id.equals(task.id))).write(
      TasksCompanion(estimatePromptedAt: Value(_ms(now))),
    );
    return const Success(true);
  });

  /// A command that only stamps one instant on the cycle.
  Future<Result<CycleStanding>> _command(
    FocusCommand command,
    FocusCycleCompanion Function(DateTime now) change,
  ) => _write((now) async {
    final standing = await _reconcile(now);
    if (stateAfter(standing.state, command) == null) return Success(standing);
    await _db.update(_db.focusCycle).write(change(now));
    return Success(await _reconcile(now));
  });

  Future<CycleStanding> _reconcile(DateTime now) async {
    final row = await _db.select(_db.focusCycle).getSingleOrNull();
    var cycle = row == null ? null : _live(row);
    var projection = project(cycle, now);

    if (projection.effects.contains(FocusEffect.clockNotice)) {
      await _db.delete(_db.focusCycle).go();
      return const CycleStanding(state: FocusState.idle, clockNotice: true);
    }
    if (projection.effects.contains(FocusEffect.settle)) {
      cycle = await _settle(cycle!, now);
      projection = project(cycle, now);
    }
    return CycleStanding(state: projection.state, cycle: cycle);
  }

  /// Records a finished block: its reward to the pet and its counts to the
  /// task, all at once and at most once, ever (spec §4.5).
  ///
  /// The caller's transaction makes it whole: cut off anywhere, nothing is
  /// kept and the block is still owed; once the cycle carries the record's id,
  /// nothing is owed again.
  Future<LiveCycle> _settle(LiveCycle cycle, DateTime now) async {
    final pet = await _db.select(_db.pets).getSingle();
    final task = await _task(cycle.taskId);
    final minutes = cycle.focusMinutes;
    final exp = expForBlock(minutes: minutes);
    final expAfter = addExp(pet.exp, exp);
    final offset = _utcOffsetAt(cycle.endAt);

    final recordId = await _db
        .into(_db.blockRecords)
        .insert(
          BlockRecordsCompanion.insert(
            petId: pet.id,
            taskId: Value(task.id),
            projectId: Value(task.projectId),
            startedAt: _ms(cycle.startAt),
            endedAt: _ms(cycle.endAt),
            minutes: minutes,
            localDate: _localDate(cycle.endAt, offset),
            utcOffsetMinutes: offset.inMinutes,
            expGranted: exp,
            petExpAfter: expAfter,
            settledAt: _ms(now),
          ),
        );
    await (_db.update(_db.pets)..where((p) => p.id.equals(pet.id))).write(
      PetsCompanion(
        exp: Value(expAfter),
        hatchedAt: pet.hatchedAt == null
            ? Value(_ms(now))
            : const Value.absent(),
      ),
    );
    await (_db.update(_db.tasks)..where((t) => t.id.equals(task.id))).write(
      TasksCompanion(
        actualPomodoros: Value(task.actualPomodoros + 1),
        cumulativeFocusMinutes: Value(task.cumulativeFocusMinutes + minutes),
        lastFocusedAt: Value(_ms(now)),
      ),
    );

    final settled = cycle.afterSettle(blockRecordId: recordId);
    final breakStartAt = settled.breakStartAt;
    await _db
        .update(_db.focusCycle)
        .write(
          FocusCycleCompanion(
            blockRecordId: Value(recordId),
            breakStartAt: Value(
              breakStartAt == null ? null : _ms(breakStartAt),
            ),
          ),
        );
    return settled;
  }

  Future<TaskRow> _task(int id) =>
      (_db.select(_db.tasks)..where((t) => t.id.equals(id))).getSingle();

  /// Runs [body] in one transaction at one reading of the clock.
  Future<Result<T>> _write<T>(
    Future<Result<T>> Function(DateTime now) body,
  ) async {
    try {
      return await _db.transaction(() => body(_db.clock().toUtc()));
    } on AssertionError {
      // An illegal command: a programming error, loud in debug and tests.
      rethrow;
    } catch (error, stackTrace) {
      _log.error(DiagnosticCode.focusWriteFailed, error, stackTrace);
      return const Failure(StorageFailed());
    }
  }
}

Invalid? _checkLengths(BlockLengths lengths) {
  final focus = lengths.focusMinutes;
  final rest = lengths.breakMinutes;
  if (!isValidFocusMinutes(focus)) {
    return Invalid(
      InvalidField.focusMinutes,
      InvalidRule.outOfRange,
      limit: focus < minFocusMinutes ? minFocusMinutes : maxFocusMinutes,
    );
  }
  if (!isValidBreakMinutes(rest)) {
    return Invalid(
      InvalidField.breakMinutes,
      InvalidRule.outOfRange,
      limit: rest < minBreakMinutes ? minBreakMinutes : maxBreakMinutes,
    );
  }
  return null;
}

int _ms(DateTime instant) => instant.millisecondsSinceEpoch;

DateTime _utc(int ms) => DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);

/// The calendar day, `YYYY-MM-DD`, that [instant] falls on at [offset].
String _localDate(DateTime instant, Duration offset) {
  final local = instant.toUtc().add(offset);
  String two(int n) => n.toString().padLeft(2, '0');
  return '${local.year.toString().padLeft(4, '0')}-'
      '${two(local.month)}-${two(local.day)}';
}

LiveCycle _live(FocusCycleRow row) => LiveCycle(
  taskId: row.taskId,
  startAt: _utc(row.startAt),
  endAt: _utc(row.endAt),
  focusMinutes: row.focusMinutes,
  breakMinutes: row.breakMinutes,
  autoStart: row.autoStart,
  breakStartAt: row.breakStartAt == null ? null : _utc(row.breakStartAt!),
  breakSkippedAt: row.breakSkippedAt == null ? null : _utc(row.breakSkippedAt!),
  blockRecordId: row.blockRecordId,
  seenAt: row.seenAt == null ? null : _utc(row.seenAt!),
);

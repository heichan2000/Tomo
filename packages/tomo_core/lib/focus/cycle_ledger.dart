import 'package:drift/drift.dart';

import '../data/instants.dart';
import '../data/tomo_database.dart';
import '../rewards/rewards.dart';
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

/// The stored focus cycle and the rules that keep it true, for use **inside a
/// caller's transaction**. The focus-cycle service and the task service both
/// go through it, so a finished block is settled the same way whoever notices.
final class CycleLedger {
  CycleLedger(this._db, {UtcOffsetAt? utcOffsetAt})
    : _utcOffsetAt = utcOffsetAt ?? _phoneUtcOffsetAt;

  final TomoDatabase _db;
  final UtcOffsetAt _utcOffsetAt;

  static Duration _phoneUtcOffsetAt(DateTime instant) =>
      instant.toLocal().timeZoneOffset;

  /// Ends the cycle: back to idle. An unseen beat run goes with it.
  Future<void> end() => _db.delete(_db.focusCycle).go();

  /// Brings the stored cycle up to [now]: settles a finished block that is
  /// still owed, and discards a cycle whose start is in the future.
  Future<CycleStanding> reconcile(DateTime now) async {
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
    final task = await taskRow(cycle.taskId);
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
            startedAt: epochMs(cycle.startAt),
            endedAt: epochMs(cycle.endAt),
            minutes: minutes,
            localDate: _localDate(cycle.endAt, offset),
            utcOffsetMinutes: offset.inMinutes,
            expGranted: exp,
            petExpAfter: expAfter,
            settledAt: epochMs(now),
          ),
        );
    await (_db.update(_db.pets)..where((p) => p.id.equals(pet.id))).write(
      PetsCompanion(
        exp: Value(expAfter),
        hatchedAt: pet.hatchedAt == null
            ? Value(epochMs(now))
            : const Value.absent(),
      ),
    );
    await (_db.update(_db.tasks)..where((t) => t.id.equals(task.id))).write(
      TasksCompanion(
        actualPomodoros: Value(task.actualPomodoros + 1),
        cumulativeFocusMinutes: Value(task.cumulativeFocusMinutes + minutes),
        lastFocusedAt: Value(epochMs(now)),
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
              breakStartAt == null ? null : epochMs(breakStartAt),
            ),
          ),
        );
    return settled;
  }

  Future<TaskRow> taskRow(int id) =>
      (_db.select(_db.tasks)..where((t) => t.id.equals(id))).getSingle();
}

/// The calendar day, `YYYY-MM-DD`, that [instant] falls on at [offset].
String _localDate(DateTime instant, Duration offset) {
  final local = instant.toUtc().add(offset);
  String two(int n) => n.toString().padLeft(2, '0');
  return '${local.year.toString().padLeft(4, '0')}-'
      '${two(local.month)}-${two(local.day)}';
}

LiveCycle _live(FocusCycleRow row) => LiveCycle(
  taskId: row.taskId,
  startAt: utcFromMs(row.startAt),
  endAt: utcFromMs(row.endAt),
  focusMinutes: row.focusMinutes,
  breakMinutes: row.breakMinutes,
  autoStart: row.autoStart,
  breakStartAt: row.breakStartAt == null ? null : utcFromMs(row.breakStartAt!),
  breakSkippedAt: row.breakSkippedAt == null
      ? null
      : utcFromMs(row.breakSkippedAt!),
  blockRecordId: row.blockRecordId,
  seenAt: row.seenAt == null ? null : utcFromMs(row.seenAt!),
);

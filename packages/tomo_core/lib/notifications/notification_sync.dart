import '../data/tomo_database.dart';
import '../diagnostics/diagnostic_entry.dart';
import '../diagnostics/log.dart';
import '../focus/cycle_ledger.dart';
import '../focus/projection.dart';
import '../pet/species.dart';
import 'notification_schedule.dart';

/// [syncNotifications] against what is stored: the cycle, its task and the
/// pet (spec §11.2, ADR-0008).
///
/// The app calls [sync] after every cycle write and on every lifecycle
/// change. It only reads, so it never settles a block: whoever opens the app
/// next does that.
final class NotificationSync {
  NotificationSync(
    this._db,
    this._scheduler, {
    required this._log,
    required this._isForeground,
  });

  final TomoDatabase _db;
  final NotificationScheduler _scheduler;
  final Log _log;

  /// Whether Tomo is on screen right now. Read when each sync runs, not when
  /// it is asked for.
  final bool Function() _isForeground;

  Future<void> _last = Future.value();

  /// Makes the phone's pending notifications match the stored cycle.
  ///
  /// Syncs run one at a time, in the order they were asked for, so the last
  /// one always reflects the last write. It never throws: a phone that
  /// refuses is recorded, and the block still counts on the next open.
  Future<void> sync() => _last = _last.then((_) => _run());

  Future<void> _run() async {
    try {
      final now = _db.clock().toUtc();
      final (cycle, subject) = await _db.transaction(() async {
        final row = await _db.select(_db.focusCycle).getSingleOrNull();
        final pet = await _db.select(_db.pets).getSingleOrNull();
        if (row == null || pet == null) return (null, null);
        final task = await (_db.select(
          _db.tasks,
        )..where((t) => t.id.equals(row.taskId))).getSingle();
        return (
          liveCycleOf(row),
          NotificationSubject(
            species: pet.species,
            hatched: pet.hatchedAt != null,
            petName: pet.name,
            taskTitle: task.title,
          ),
        );
      });
      // A cycle that starts after now is discarded at the next open
      // (spec §4.4), so nothing should announce it.
      final live =
          cycle != null &&
              !project(cycle, now).effects.contains(FocusEffect.clockNotice)
          ? cycle
          : null;
      await syncNotifications(
        _scheduler,
        cycle: live,
        now: now,
        isForeground: _isForeground(),
        subject: subject ?? _nobody,
      );
    } catch (error, stackTrace) {
      _log.error(DiagnosticCode.notificationSyncFailed, error, stackTrace);
    }
  }
}

/// Stands in when there is no cycle, so nothing is about anyone.
const _nobody = NotificationSubject(
  species: Species.geode,
  hatched: false,
  petName: null,
  taskTitle: '',
);

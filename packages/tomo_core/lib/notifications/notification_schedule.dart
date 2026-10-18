import '../data/instants.dart';
import '../focus/live_cycle.dart';
import '../pet/species.dart';

/// The three timer notifications (spec §11.1). Nothing else, ever: no
/// reminders, no nudges, no ongoing countdown.
enum NotificationKind {
  blockComplete,

  /// Under auto-start: the block ended and its break began by itself.
  blockCompleteBreakBegun,
  breakComplete,
}

/// Where a notification sits. Each slot has a fixed id, so a newer one
/// replaces an older one in the same slot without anyone cancelling it.
enum NotificationSlot {
  blockEnd(1),
  breakEnd(2);

  const NotificationSlot(this.id);

  final int id;
}

/// The Android channel and iOS category a notification belongs to
/// (spec §11.3, ADR-0008). The ids are hard to change once shipped.
enum NotificationChannel {
  focusBlock(androidId: 'focus_block_v1', iosCategory: 'focusBlock'),
  breakOver(androidId: 'break_v1', iosCategory: 'break');

  const NotificationChannel({
    required this.androidId,
    required this.iosCategory,
  });

  final String androidId;
  final String iosCategory;
}

/// Who and what a notification is about, as it stands when the schedule is
/// worked out.
final class NotificationSubject {
  const NotificationSubject({
    required this.species,
    required this.hatched,
    required this.petName,
    required this.taskTitle,
  });

  final Species species;
  final bool hatched;

  /// Null before the hatch names the pet.
  final String? petName;
  final String taskTitle;
}

/// What a notification's title and body are made from. The words come from
/// the copy files.
///
/// It holds facts that stay true when read hours late: the task and the
/// minutes. Never EXP, level, an instruction or a time of day.
final class NotificationContent {
  const NotificationContent({
    required this.species,
    required this.beforeHatch,
    required this.petName,
    required this.taskTitle,
    required this.focusMinutes,
    required this.breakMinutes,
  });

  final Species species;

  /// The title is "Your egg", and the first block's body hints at the hatch.
  final bool beforeHatch;

  /// The title after the hatch. Null means the pet is hatched but not yet
  /// named: use its species' name.
  final String? petName;
  final String taskTitle;
  final int focusMinutes;
  final int breakMinutes;
}

/// One notification that should be pending.
final class TimerNotification {
  const TimerNotification({
    required this.kind,
    required this.fireAt,
    required this.content,
    required this.payload,
  });

  final NotificationKind kind;

  /// An absolute instant, in UTC. Travel and daylight saving cannot move it.
  final DateTime fireAt;
  final NotificationContent content;

  /// Only the start of its cycle. See [tapOutcome].
  final String payload;

  NotificationSlot get slot => switch (kind) {
    NotificationKind.blockComplete ||
    NotificationKind.blockCompleteBreakBegun => NotificationSlot.blockEnd,
    NotificationKind.breakComplete => NotificationSlot.breakEnd,
  };

  NotificationChannel get channel => switch (slot) {
    NotificationSlot.blockEnd => NotificationChannel.focusBlock,
    NotificationSlot.breakEnd => NotificationChannel.breakOver,
  };
}

/// The notifications that should be pending right now (spec §11.2, ADR-0008).
///
/// The pending set is a function, not a history: none while Tomo is open,
/// otherwise this cycle's timer notifications that are still in the future.
/// So a stale notification cannot fire, and nothing has to remember to cancel.
List<TimerNotification> desiredNotifications({
  required LiveCycle? cycle,
  required DateTime now,
  required bool isForeground,
  required NotificationSubject subject,
}) {
  if (cycle == null || isForeground) return const [];

  final content = NotificationContent(
    species: subject.species,
    beforeHatch: !subject.hatched,
    petName: subject.hatched ? subject.petName : null,
    taskTitle: subject.taskTitle,
    focusMinutes: cycle.focusMinutes,
    breakMinutes: cycle.breakMinutes,
  );
  final payload = '${epochMs(cycle.startAt)}';
  return [
    for (final end in timerEnds(cycle: cycle, after: now))
      TimerNotification(
        kind: switch (end.slot) {
          NotificationSlot.blockEnd =>
            cycle.autoStart
                ? NotificationKind.blockCompleteBreakBegun
                : NotificationKind.blockComplete,
          NotificationSlot.breakEnd => NotificationKind.breakComplete,
        },
        fireAt: end.at,
        content: content,
        payload: payload,
      ),
  ];
}

/// A moment the timer runs out: the block's end, or the break's.
typedef TimerEnd = ({NotificationSlot slot, DateTime at});

/// When [cycle]'s block and break run out after [after], in order. The
/// notifications fire at these moments while Tomo is away, and the timer
/// buzz while it is open (spec §11.5).
List<TimerEnd> timerEnds({required LiveCycle cycle, required DateTime after}) {
  // Under auto-start the break begins at the block's end even if nobody is
  // there to settle it, so its end is known ahead of time.
  final breakStartAt =
      cycle.breakStartAt ?? (cycle.autoStart ? cycle.endAt : null);
  final breakEndAt = cycle.breakSkippedAt != null
      ? null
      : breakStartAt?.add(Duration(minutes: cycle.breakMinutes));

  return [
    (slot: NotificationSlot.blockEnd, at: cycle.endAt),
    if (breakEndAt != null) (slot: NotificationSlot.breakEnd, at: breakEndAt),
  ].where((end) => end.at.isAfter(after)).toList();
}

/// What the app implements in `lib/platform/` to reach the phone's
/// notifications.
abstract interface class NotificationScheduler {
  /// Makes [notification] pending, replacing whatever is in its slot.
  Future<void> schedule(TimerNotification notification);

  /// Removes whatever is pending in [slot]. Nothing there is fine.
  Future<void> cancel(NotificationSlot slot);

  /// Removes every Tomo notification already shown.
  Future<void> clearDelivered();
}

/// Makes the phone's pending notifications equal the desired set. Idempotent.
///
/// Call it on every cycle write and every time the app comes forward or goes
/// back. Coming forward also clears what was already delivered.
Future<void> syncNotifications(
  NotificationScheduler scheduler, {
  required LiveCycle? cycle,
  required DateTime now,
  required bool isForeground,
  required NotificationSubject subject,
}) async {
  final desired = desiredNotifications(
    cycle: cycle,
    now: now,
    isForeground: isForeground,
    subject: subject,
  );
  for (final slot in NotificationSlot.values) {
    final wanted = desired.where((n) => n.slot == slot).firstOrNull;
    if (wanted == null) {
      await scheduler.cancel(slot);
    } else {
      await scheduler.schedule(wanted);
    }
  }
  if (isForeground) await scheduler.clearDelivered();
}

/// What a tap on a notification does. A notification has no buttons.
enum NotificationTap {
  /// Its cycle is still the live one: bring Focus forward.
  openFocus,

  /// Its cycle is gone: start the way the app always starts.
  ordinaryStart,
}

/// What a tap on the notification carrying [payload] means, given the live
/// [cycle].
NotificationTap tapOutcome({
  required String? payload,
  required LiveCycle? cycle,
}) {
  final startAt = int.tryParse(payload ?? '');
  return cycle != null && startAt == epochMs(cycle.startAt)
      ? NotificationTap.openFocus
      : NotificationTap.ordinaryStart;
}

/// The live focus cycle as a plain value: one focus block and the break that
/// follows it (spec §4, §6.2). It mirrors the one `focus_cycle` row.
///
/// The two anchors, [startAt] and [endAt], are absolute instants and the sole
/// truth about whether the block completed.
final class LiveCycle {
  LiveCycle({
    required this.taskId,
    required DateTime startAt,
    required DateTime endAt,
    required this.focusMinutes,
    required this.breakMinutes,
    required this.autoStart,
    DateTime? breakStartAt,
    DateTime? breakSkippedAt,
    this.blockRecordId,
    DateTime? seenAt,
  }) : startAt = startAt.toUtc(),
       endAt = endAt.toUtc(),
       breakStartAt = breakStartAt?.toUtc(),
       breakSkippedAt = breakSkippedAt?.toUtc(),
       seenAt = seenAt?.toUtc();

  final int taskId;
  final DateTime startAt;
  final DateTime endAt;
  final int focusMinutes;
  final int breakMinutes;

  /// Auto-start as it was when the block began.
  final bool autoStart;

  /// Set by *Take break*, or by the settle under auto-start.
  final DateTime? breakStartAt;

  /// Set by *Skip break*.
  final DateTime? breakSkippedAt;

  /// The block record the settle wrote. Not null means credited.
  final int? blockRecordId;

  /// When the beat run was had (spec §7.4).
  final DateTime? seenAt;

  /// Whether the settle has recorded this block.
  bool get isCredited => blockRecordId != null;

  /// When the break runs out, if one has started.
  DateTime? get breakEndAt =>
      breakStartAt?.add(Duration(minutes: breakMinutes));

  /// This cycle as the settle leaves it (spec §4.5): credited, and under
  /// auto-start with its break begun at the block's end.
  LiveCycle afterSettle({required int blockRecordId}) => LiveCycle(
    taskId: taskId,
    startAt: startAt,
    endAt: endAt,
    focusMinutes: focusMinutes,
    breakMinutes: breakMinutes,
    autoStart: autoStart,
    breakStartAt: breakStartAt ?? (autoStart ? endAt : null),
    breakSkippedAt: breakSkippedAt,
    blockRecordId: blockRecordId,
    seenAt: seenAt,
  );
}

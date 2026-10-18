/// Instants are stored as integers of UTC epoch milliseconds (spec §6.2).
library;

int epochMs(DateTime instant) => instant.millisecondsSinceEpoch;

DateTime utcFromMs(int ms) =>
    DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);

/// The calendar day, `YYYY-MM-DD`, that [instant] falls on at [offset]: a
/// block record's `local_date` (spec §12, item 9).
String localDateAt(DateTime instant, Duration offset) {
  final local = instant.toUtc().add(offset);
  String two(int n) => n.toString().padLeft(2, '0');
  return '${local.year.toString().padLeft(4, '0')}-'
      '${two(local.month)}-${two(local.day)}';
}

/// Instants are stored as integers of UTC epoch milliseconds (spec §6.2).
library;

int epochMs(DateTime instant) => instant.millisecondsSinceEpoch;

DateTime utcFromMs(int ms) =>
    DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);

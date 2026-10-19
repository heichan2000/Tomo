import 'package:drift/drift.dart';

import '../data/instants.dart';
import '../data/tomo_database.dart';
import '../focus/cycle_ledger.dart';
import '../rewards/rewards.dart';

/// The four all-time numbers on the Stats screen (spec §8.9, ADR-0026).
final class Stats {
  const Stats({
    required this.level,
    required this.minutesFocused,
    required this.blocksFinished,
    required this.daysFocused,
  });

  final int level;

  /// Every finished block's minutes, added up.
  final int minutesFocused;
  final int blocksFinished;

  /// Local days with at least one finished block, by the day it ended. It
  /// only grows: there is no streak to lose.
  final int daysFocused;
}

/// The blocks finished on one local day, and their minutes.
final class DayTotals {
  const DayTotals({required this.blocks, required this.minutes});

  final int blocks;
  final int minutes;
}

/// Counts the Stats numbers fresh, every time, from the block records.
///
/// Nothing here is stored. And because a block record outlives its task
/// (ADR-0022), no delete or reopen can make any of them smaller.
final class StatsReader {
  StatsReader(this._db);

  final TomoDatabase _db;

  Future<Stats> read() async {
    final records = _db.blockRecords;
    final minutes = records.minutes.sum();
    final blocks = records.id.count();
    final days = records.localDate.count(distinct: true);
    final totals = await (_db.selectOnly(
      records,
    )..addColumns([minutes, blocks, days])).getSingle();
    final pet = await _db.select(_db.pets).getSingleOrNull();

    return Stats(
      level: levelForExp(pet?.exp ?? 0),
      minutesFocused: totals.read(minutes) ?? 0,
      blocksFinished: totals.read(blocks) ?? 0,
      daysFocused: totals.read(days) ?? 0,
    );
  }

  /// The blocks that ended on the local day [now] falls on, by the day each
  /// block stored at its settle: what the pet's break lines count as today.
  /// Not a Stats number (ADR-0026).
  Future<DayTotals> dayOf(
    DateTime now, {
    UtcOffsetAt utcOffsetAt = phoneUtcOffsetAt,
  }) async {
    final records = _db.blockRecords;
    final minutes = records.minutes.sum();
    final blocks = records.id.count();
    final day = localDateAt(now, utcOffsetAt(now));
    final totals =
        await (_db.selectOnly(records)
              ..addColumns([minutes, blocks])
              ..where(records.localDate.equals(day)))
            .getSingle();
    return DayTotals(
      blocks: totals.read(blocks) ?? 0,
      minutes: totals.read(minutes) ?? 0,
    );
  }
}

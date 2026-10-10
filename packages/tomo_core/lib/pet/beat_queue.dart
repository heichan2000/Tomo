import '../data/tomo_database.dart';
import 'beat.dart';

/// The beat queue against the database (spec §7.4, ADR-0009).
///
/// Nothing stores a run. It is owed while the live cycle is credited and its
/// run not yet seen, and it is rebuilt from that block's record every time
/// someone asks. So a run cut off by a kill is owed again on the next launch,
/// and once it is marked seen it is never owed again.
final class BeatQueue {
  BeatQueue(this._db);

  final TomoDatabase _db;

  /// The run owed right now, or an empty list.
  Future<List<Beat>> owedRun() async {
    final cycle = await _db.select(_db.focusCycle).getSingleOrNull();
    final recordId = cycle?.blockRecordId;
    if (recordId == null || cycle?.seenAt != null) return const [];

    final record = await (_db.select(
      _db.blockRecords,
    )..where((r) => r.id.equals(recordId))).getSingle();
    final pet = await (_db.select(
      _db.pets,
    )..where((p) => p.id.equals(record.petId))).getSingle();
    return beatRunFor(
      minutes: record.minutes,
      expGranted: record.expGranted,
      petExpAfter: record.petExpAfter,
      species: pet.species,
    );
  }
}

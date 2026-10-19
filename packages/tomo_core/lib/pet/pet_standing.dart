import '../data/tomo_database.dart';
import '../focus/cycle_ledger.dart';
import '../focus/live_cycle.dart';
import '../focus/projection.dart';
import '../rewards/rewards.dart';
import 'beat.dart';
import 'beat_queue.dart';
import 'pet_look.dart';
import 'species.dart';

/// The pet as a screen that shows it, but never plays its beats, sees it:
/// Home (spec §8.3). Read fresh from the database, stored nowhere else.
final class PetStanding {
  const PetStanding({
    required this.species,
    required this.name,
    required this.exp,
    required this.hatched,
    this.cycle,
    this.owedRun = const [],
  });

  final Species species;

  /// Null until the hatch names it, or if the app was closed on the naming
  /// step; then the pet goes by its species' name (§17, C30).
  final String? name;

  final int exp;

  /// Whether the pet row says it has hatched. The hatch beat may still be
  /// owed: see [lookAt].
  final bool hatched;

  /// The live cycle, if any.
  final LiveCycle? cycle;

  /// The beat run the live cycle still owes; it plays only on Focus.
  final List<Beat> owedRun;

  int get level => levelForExp(exp);

  /// What the pet looks like at [now] (spec §7.2), with the owed run waiting:
  /// a hatch not yet played keeps the egg, an evolution not yet played keeps
  /// the old stage.
  PetLook lookAt(
    DateTime now, {
    required bool calmPet,
    required bool reduceMotion,
  }) => look(
    LookState(
      species: species,
      exp: exp,
      hatched: hatched,
      focus: project(cycle, now).state,
      calmPet: calmPet,
      reduceMotion: reduceMotion,
      cycle: cycle,
      now: now,
    ),
    PendingBeats(waiting: owedRun),
  );

  /// The next instant after [now] at which the look can change with nothing
  /// written: while a block runs, each whole minute of it (the egg's crack,
  /// then the end of the block); while a break runs, its end. Null when
  /// only a write can change it.
  DateTime? nextChangeAfter(DateTime now) {
    final cycle = this.cycle;
    switch (project(cycle, now).state) {
      case FocusState.focusRunning:
        final minutes = now.difference(cycle!.startAt).inMinutes + 1;
        return cycle.startAt.add(Duration(minutes: minutes));
      case FocusState.breakRunning:
        return cycle!.breakEndAt;
      case FocusState.idle ||
          FocusState.focusComplete ||
          FocusState.breakComplete:
        return null;
    }
  }
}

/// Reads the pet's standing from the database.
final class PetReader {
  PetReader(this._db) : _beats = BeatQueue(_db);

  final TomoDatabase _db;
  final BeatQueue _beats;

  /// The pet now, or null before onboarding.
  Future<PetStanding?> read() => _db.transaction(() async {
    final pet = await _db.select(_db.pets).getSingleOrNull();
    if (pet == null) return null;
    final row = await _db.select(_db.focusCycle).getSingleOrNull();
    return PetStanding(
      species: pet.species,
      name: pet.name,
      exp: pet.exp,
      hatched: pet.hatchedAt != null,
      cycle: row == null ? null : liveCycleOf(row),
      owedRun: await _beats.owedRun(),
    );
  });

  /// The pet now and each time the pet, the cycle or a block record changes.
  Stream<PetStanding?> watch() => _db
      .customSelect(
        'SELECT 1',
        readsFrom: {_db.pets, _db.focusCycle, _db.blockRecords},
      )
      .watch()
      .asyncMap((_) => read());
}

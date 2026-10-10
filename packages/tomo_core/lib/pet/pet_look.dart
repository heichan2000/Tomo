import '../focus/live_cycle.dart';
import '../focus/projection.dart';
import '../rewards/rewards.dart';
import 'beat.dart';
import 'egg_crack.dart';
import 'species.dart';

/// The pet's expression. One value, so two faces at once cannot be said.
enum Face { celebrating, pleased, still, drowsy, resting }

/// How much the pet may move: [reduced] when the phone asks for less motion.
enum Movement { full, reduced }

/// How many pictures a species' egg has: whole, then one per crack step
/// (spec §7.2).
int eggPictureCount(Species species) => switch (species) {
  Species.geode => 4,
  Species.joe => 6,
  Species.lily => 5,
};

/// Everything the look depends on, as it is right now.
final class LookState {
  const LookState({
    required this.species,
    required this.exp,
    required this.hatched,
    required this.focus,
    required this.calmPet,
    required this.reduceMotion,
    required this.now,
    this.cycle,
  });

  final Species species;
  final int exp;

  /// Whether the pet row says it has hatched.
  final bool hatched;
  final FocusState focus;
  final bool calmPet;
  final bool reduceMotion;

  /// The live cycle and the time, used only for the egg's crack.
  final LiveCycle? cycle;
  final DateTime now;
}

/// Where the beat run stands: the beat playing now, and those still to play.
final class PendingBeats {
  const PendingBeats({this.playing, this.waiting = const []});

  /// Nothing playing, nothing waiting.
  static const none = PendingBeats();

  final Beat? playing;
  final List<Beat> waiting;
}

/// What goes in the pet's spot.
sealed class PetLook {
  const PetLook({required this.species, required this.movement});

  final Species species;
  final Movement movement;
}

/// The pet.
final class HatchedLook extends PetLook {
  const HatchedLook({
    required super.species,
    required super.movement,
    required this.stage,
    required this.face,
  });

  /// The evolution stage, 1 to 4.
  final int stage;
  final Face face;

  /// Idle moves happen only on the Resting face; Calm pet's Still has none.
  bool get mayIdle => face == Face.resting;

  @override
  bool operator ==(Object other) =>
      other is HatchedLook &&
      other.species == species &&
      other.movement == movement &&
      other.stage == stage &&
      other.face == face;

  @override
  int get hashCode => Object.hash(species, movement, stage, face);
}

/// The egg, before the hatch. It is outside the face ladder.
final class EggLook extends PetLook {
  const EggLook({
    required super.species,
    required super.movement,
    required this.picture,
  });

  /// Which of the egg's pictures to show: 0 is whole, then each crack step.
  final int picture;

  @override
  bool operator ==(Object other) =>
      other is EggLook &&
      other.species == species &&
      other.movement == movement &&
      other.picture == picture;

  @override
  int get hashCode => Object.hash(species, movement, picture);
}

/// What the pet looks like (spec §7.2, ADR-0009). A pure function: worked out
/// fresh every time, stored nowhere.
PetLook look(LookState state, PendingBeats pending) {
  final movement = state.reduceMotion ? Movement.reduced : Movement.full;
  final species = state.species;

  // The settle hatches the pet before the hatch beat plays, so the egg stays
  // until that beat starts.
  final hatchWaiting = pending.waiting.any((beat) => beat is Hatch);
  if (!state.hatched || hatchWaiting) {
    return EggLook(
      species: species,
      movement: movement,
      picture: hatchWaiting
          ? eggPictureCount(species) - 1
          : _crackPicture(state),
    );
  }

  // Likewise the settle raises the level before the evolution beat plays, so
  // the old stage stays until that beat starts.
  final evolutionWaiting = pending.waiting.whereType<Evolution>().firstOrNull;
  return HatchedLook(
    species: species,
    movement: movement,
    stage: evolutionWaiting?.from ?? stageForExp(state.exp),
    face: _face(state, pending.playing),
  );
}

/// The face: one value off one ladder, the highest rung that applies.
Face _face(LookState state, Beat? playing) {
  switch (playing) {
    case LevelUp() || TaskCompleted() || Evolution() || Hatch():
      return Face.celebrating;
    case BlockCredited():
      return Face.pleased;
    case null:
      break;
  }
  // Calm pet replaces the three everyday faces, and never touches a beat.
  if (state.calmPet) return Face.still;
  return switch (state.focus) {
    FocusState.breakRunning => Face.drowsy,
    FocusState.focusRunning => Face.pleased,
    FocusState.idle ||
    FocusState.focusComplete ||
    FocusState.breakComplete => Face.resting,
  };
}

/// The waiting egg is whole; across a block it cracks in equal shares, and
/// holds its last crack once the block has ended. Stopping early ends the
/// cycle, so the egg is whole again.
int _crackPicture(LookState state) {
  final cycle = state.cycle;
  if (cycle == null) return 0;
  return eggPicture(
    pictures: eggPictureCount(state.species),
    focusMinutes: cycle.focusMinutes,
    elapsedMinutes: state.now.difference(cycle.startAt).inMinutes,
  );
}

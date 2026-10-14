import 'pixel_art.dart';

/// How a pet stage is posed: which eye drawing it shows and how far its parts
/// have slid, all in whole pixels (ADR-0018). The movements are made of these;
/// `pet/pet_motion.dart` says which pose shows when.
///
/// Up is negative on the grid, so a [lift] of 2 draws the pet two rows higher.
final class Pose {
  const Pose({
    this.eyes = EyeShape.resting,
    this.eyesX = 0,
    this.eyesY = 0,
    this.drop = 0,
    this.lift = 0,
    this.extra = 0,
    this.twitch = 0,
    this.wiggle = 0,
  });

  /// Standing still, plain eyes.
  static const rest = Pose();

  /// The eye drawing from the species' eye sheet.
  final EyeShape eyes;

  /// The eyes alone moved sideways and down: the glance and the look up.
  final int eyesX, eyesY;

  /// How far what rides with the head sinks, and every part's rows above the
  /// stage's breath row: the breath, Drowsy, the head landing late.
  final int drop;

  /// The whole pet raised: the hop and the jump.
  final int lift;

  /// The parts that lift on the jump, raised further at its top.
  final int extra;

  /// The twitching parts raised.
  final int twitch;

  /// The whole pet slid sideways.
  final int wiggle;

  @override
  bool operator ==(Object other) =>
      other is Pose &&
      other.eyes == eyes &&
      other.eyesX == eyesX &&
      other.eyesY == eyesY &&
      other.drop == drop &&
      other.lift == lift &&
      other.extra == extra &&
      other.twitch == twitch &&
      other.wiggle == wiggle;

  @override
  int get hashCode =>
      Object.hash(eyes, eyesX, eyesY, drop, lift, extra, twitch, wiggle);

  @override
  String toString() =>
      'Pose(${eyes.name}, eyes $eyesX,$eyesY, drop $drop, lift $lift, '
      'extra $extra, twitch $twitch, wiggle $wiggle)';
}

/// Stage [stage] (0 for stage 1) of [species] as one 48×48 picture in [pose]:
/// its parts stacked in the species' paint order, front last, each slid by
/// whole pixels, with the eyes layer drawn from the eye sheet at each of the
/// stage's eye spots. Rows of colour-key characters, `.` for clear. Pixels
/// slid off the grid are dropped.
///
/// This is the same stacking `tool/art/pose.mjs` does for the review page.
List<String> composeStage(
  SpeciesArt species,
  int stage, {
  Pose pose = Pose.rest,
}) {
  final st = species.stages[stage];
  final picture = List.generate(_size, (_) => List.filled(_size, '.'));
  for (final part in species.paintOrder) {
    final rows = part == Part.eyes
        ? _eyesLayer(species.eyeSheet.faces[pose.eyes]!, st.eyes, pose)
        : gridRows(st.parts[part]!);
    final rides = species.ridesWithHead.contains(part);
    final breathRow = st.breathRow;
    bool sinks(int y) => rides || (breathRow != null && y < breathRow);
    var dy = -pose.lift;
    if (species.twitches.contains(part)) dy -= pose.twitch;
    if (species.liftsOnJump.contains(part)) dy -= pose.extra;
    // Within a part, the rows that sink land on top of the rows below them.
    for (final sinking in const [false, true]) {
      for (var y = 0; y < _size; y++) {
        if (sinks(y) != sinking) continue;
        final to = y + dy + (sinking ? pose.drop : 0);
        if (to < 0 || to >= _size) continue;
        for (var x = 0; x < _size; x++) {
          final c = rows[y][x];
          final across = x + pose.wiggle;
          if (c != '.' && across >= 0 && across < _size) {
            picture[to][across] = c;
          }
        }
      }
    }
  }
  return [for (final row in picture) row.join()];
}

const _size = 48;

List<String> _eyesLayer(Eye eye, List<Px> spots, Pose pose) {
  final layer = List.generate(_size, (_) => List.filled(_size, '.'));
  final rows = gridRows(eye.grid);
  for (final spot in spots) {
    for (var j = 0; j < rows.length; j++) {
      for (var i = 0; i < rows[j].length; i++) {
        final c = rows[j][i];
        final x = spot.x + eye.offset.x + pose.eyesX + i;
        final y = spot.y + eye.offset.y + pose.eyesY + j;
        if (c != '.' && x >= 0 && y >= 0 && x < _size && y < _size) {
          layer[y][x] = c;
        }
      }
    }
  }
  return [for (final row in layer) row.join()];
}

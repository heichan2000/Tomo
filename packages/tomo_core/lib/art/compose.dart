import 'pixel_art.dart';

/// Stage [stage] (0 for stage 1) of [species] as one 48×48 picture, standing
/// still: its parts stacked in the species' paint order, front last, with the
/// eyes layer drawn from the eye sheet's [face] at each of the stage's eye
/// spots. Rows of colour-key characters, `.` for clear.
///
/// This is the same stacking `tool/art/pose.mjs` does for the review page, in
/// its resting pose.
List<String> composeStage(
  SpeciesArt species,
  int stage, {
  EyeShape face = EyeShape.resting,
}) {
  final st = species.stages[stage];
  final picture = List.generate(_size, (_) => List.filled(_size, '.'));
  for (final part in species.paintOrder) {
    final rows = part == Part.eyes
        ? _eyesLayer(species.eyeSheet.faces[face]!, st.eyes)
        : gridRows(st.parts[part]!);
    for (var y = 0; y < _size; y++) {
      for (var x = 0; x < _size; x++) {
        final c = rows[y][x];
        if (c != '.') picture[y][x] = c;
      }
    }
  }
  return [for (final row in picture) row.join()];
}

const _size = 48;

List<String> _eyesLayer(Eye eye, List<Px> spots) {
  final layer = List.generate(_size, (_) => List.filled(_size, '.'));
  final rows = gridRows(eye.grid);
  for (final spot in spots) {
    for (var j = 0; j < rows.length; j++) {
      for (var i = 0; i < rows[j].length; i++) {
        final c = rows[j][i];
        final x = spot.x + eye.offset.x + i;
        final y = spot.y + eye.offset.y + j;
        if (c != '.' && x >= 0 && y >= 0 && x < _size && y < _size) {
          layer[y][x] = c;
        }
      }
    }
  }
  return [for (final row in layer) row.join()];
}

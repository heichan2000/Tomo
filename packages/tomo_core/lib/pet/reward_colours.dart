import '../art/drawings.dart';
import '../look/palette.dart';
import 'species.dart';

/// The colours of the reward effects (ADR-0019, #39). The art leaves them out
/// on purpose: the sparkle is coloured where it is drawn (§17 C40).

/// The sparkle's two colours in [theme]: the accent for its arms, and a
/// lighter colour of the same pet for its centre. Before the hatch
/// ([species] null), the neutral pair.
({int arms, int centre}) sparkleColours(ThemeName theme, Species? species) {
  final light = theme == ThemeName.light;
  final arms = accentOf(theme, species);
  if (species == null) {
    return (arms: arms, centre: light ? 0xFFC4AF8C : 0xFFE9DCC3);
  }
  final key = artOf(species).colours;
  return (
    arms: arms,
    centre:
        key[switch (species) {
          // The crystal on light; the crystal's light on black.
          Species.geode => light ? 'A' : 'a',
          // The brim's light blue on light; the paper's light on black.
          Species.joe => light ? 'a' : 'L',
          // The body on light; the belly on black.
          Species.lily => light ? 'B' : 'L',
        }]!,
  );
}

/// The confetti's colours in [theme]: the pet's own colours that stand out on
/// the ground at 1.45:1 or more, each once, in the order of its colour key.
/// Never its face's marks (`E`, the eyes; `F`, Geode's mouth and Lily's
/// nose), which read as specks of dirt (#71). If none were left, the accent.
List<int> confettiColours(ThemeName theme, Species species) {
  final ground = Palette.of(theme, species).ground;
  final colours = <int>{
    for (final MapEntry(:key, :value) in artOf(species).colours.entries)
      if (!_face.contains(key) && contrast(value, ground) >= 1.45) value,
  };
  return colours.isEmpty ? [accentOf(theme, species)] : colours.toList();
}

/// The colour-key characters of a pet's face marks.
const _face = {'E', 'F'};

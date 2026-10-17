import 'package:test/test.dart';
import 'package:tomo_core/look/palette.dart';
import 'package:tomo_core/pet/reward_colours.dart';
import 'package:tomo_core/pet/species.dart';

/// The colours the reward effects are drawn in (ADR-0019, #39).
void main() {
  test("the sparkle's arms are the theme's accent and its centre a lighter "
      'colour of the same pet, as ADR-0019 lists them', () {
    expect(sparkleColours(ThemeName.light, Species.geode), (
      arms: 0xFF3A6470,
      centre: 0xFF6EE0C6,
    ));
    expect(sparkleColours(ThemeName.dark, Species.geode), (
      arms: 0xFF6EE0C6,
      centre: 0xFFB6F0E2,
    ));
    expect(sparkleColours(ThemeName.light, Species.joe), (
      arms: 0xFF4A57B8,
      centre: 0xFF6F7ED8,
    ));
    expect(sparkleColours(ThemeName.dark, Species.joe), (
      arms: 0xFF6F7ED8,
      centre: 0xFFFDF6EA,
    ));
    expect(sparkleColours(ThemeName.light, Species.lily), (
      arms: 0xFF4A2A44,
      centre: 0xFFC89AB3,
    ));
    expect(sparkleColours(ThemeName.dark, Species.lily), (
      arms: 0xFFC89AB3,
      centre: 0xFFF2E7DA,
    ));
  });

  test('before the hatch the sparkle is the neutral pair', () {
    expect(sparkleColours(ThemeName.light, null), (
      arms: 0xFF4A443C,
      centre: 0xFFC4AF8C,
    ));
    expect(sparkleColours(ThemeName.dark, null), (
      arms: 0xFFEDE7DC,
      centre: 0xFFE9DCC3,
    ));
  });

  test("confetti is the pet's own colours that reach 1.45:1 on the ground, "
      'never its eyes', () {
    // On light, Joe's cream body and light are too pale to show (#39).
    expect(confettiColours(ThemeName.light, Species.joe), [
      0xFFCDB58A, // body shade
      0xFF4A57B8, // cap
      0xFF6F7ED8, // brim
    ]);
    // On black, Geode's near-black mouth would drop anyway. Its eyes are the
    // crystal light's colour, which shows once.
    expect(confettiColours(ThemeName.dark, Species.geode), [
      0xFF3A6470,
      0xFF274A55,
      0xFF4A7A86,
      0xFF6EE0C6,
      0xFFB6F0E2,
    ]);
  });

  test("confetti leaves out the face's other mark: Geode's near-black mouth "
      "and Lily's nose, as on the approved screens (#71)", () {
    expect(
      confettiColours(ThemeName.light, Species.geode),
      isNot(contains(0xFF0A1A1E)),
    );
    expect(confettiColours(ThemeName.light, Species.lily), [
      0xFFC89AB3, // body
      0xFF96739B, // body shade
      0xFF3F8494, // ears
      0xFF6FB2BF, // ear light
    ]);
  });
}

import 'dart:math' as math;

import '../art/pets/geode.dart';
import '../art/pets/joe.dart';
import '../art/pets/lily.dart';
import '../pet/species.dart';

/// Tomo's two themes (spec §9.1, ADR-0015).
enum ThemeName { light, dark }

/// Every colour the chrome uses in one theme, for one pet: the seven roles of
/// spec §9.1 plus the species accent and the labels that sit on it. Colours
/// are `0xAARRGGBB`, so the contrast promise is a plain computation (§16, #29).
///
/// **No status colours** (§9.1): the only chromatic colours are the accent,
/// which is one of the pet's own, and the destructive red.
final class Palette {
  const Palette._({
    required this.theme,
    required this.ground,
    required this.surface,
    required this.sunken,
    required this.ink,
    required this.muted,
    required this.boundary,
    required this.destructive,
    required this.onDestructive,
    required this.accent,
    required this.onAccent,
  });

  /// The palette for [theme] around [species], or around the egg when the pet
  /// has not hatched yet (null).
  factory Palette.of(ThemeName theme, Species? species) {
    final light = theme == ThemeName.light;
    return Palette._(
      theme: theme,
      ground: light ? 0xFFF5F1EA : 0xFF000000,
      surface: light ? 0xFFFCFAF6 : 0xFF161412,
      sunken: light ? 0xFFEAE4DA : 0xFF24211D,
      ink: light ? 0xFF24211D : 0xFFEDE7DC,
      muted: light ? 0xFF6A6359 : 0xFFA39B8F,
      boundary: light ? 0xFF8E867A : 0xFF756E64,
      destructive: light ? 0xFFA3402C : 0xFFFF4D40,
      onDestructive: light ? _white : _black,
      accent: accentOf(theme, species),
      onAccent: light ? _white : _black,
    );
  }

  final ThemeName theme;

  /// The screen behind everything.
  final int ground;

  /// Cards, rows, sheets: one step up from the ground.
  final int surface;

  /// Secondary buttons, tracks, chips, the unlit EXP blocks.
  final int sunken;

  final int ink;
  final int muted;

  /// The outline of a text field, the one part that has one (ADR-0017).
  final int boundary;

  final int destructive;
  final int onDestructive;

  /// The species accent (or the neutral one before the hatch).
  final int accent;
  final int onAccent;

  /// [fill] while it is held down: one shade toward [ink] (spec §9.3).
  ///
  /// Before the hatch, the dark accent *is* the ink, so pressing a primary
  /// button there moves toward [muted] instead, or nothing would change (§17
  /// C52).
  int pressed(int fill) => mix(fill, fill == ink ? muted : ink, _pressStep);
}

const _white = 0xFFFFFFFF;
const _black = 0xFF000000;

/// How far a press moves a fill toward the ink: the share approved in the
/// pixel interface kit (#38).
const _pressStep = 0.22;

/// The species accent: one of the pet's own colours, copied from its colour
/// key, never a new colour (ADR-0015). Before the hatch it is neutral.
int accentOf(ThemeName theme, Species? species) {
  final light = theme == ThemeName.light;
  return switch (species) {
    null => light ? 0xFF4A443C : 0xFFEDE7DC,
    // Body on light, crystal on black.
    Species.geode => geode.colours[light ? 'B' : 'A']!,
    // The cap on light, the brim's light blue on black.
    Species.joe => joe.colours[light ? 'A' : 'a']!,
    // The nose on light, the body on black.
    Species.lily => lily.colours[light ? 'F' : 'B']!,
  };
}

/// [from] moved a share [t] of the way to [to], channel by channel in sRGB,
/// opaque.
int mix(int from, int to, double t) {
  int channel(int shift) {
    final a = (from >> shift) & 0xFF, b = (to >> shift) & 0xFF;
    return (a + (b - a) * t).round();
  }

  return 0xFF000000 | channel(16) << 16 | channel(8) << 8 | channel(0);
}

/// The WCAG contrast ratio between two opaque colours, 1 to 21.
double contrast(int a, int b) {
  final la = _luminance(a), lb = _luminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

double _luminance(int colour) {
  double linear(int shift) {
    final c = ((colour >> shift) & 0xFF) / 255;
    return c <= 0.04045
        ? c / 12.92
        : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
  }

  return 0.2126 * linear(16) + 0.7152 * linear(8) + 0.0722 * linear(0);
}

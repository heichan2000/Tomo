import 'package:test/test.dart';
import 'package:tomo_core/look/palette.dart';
import 'package:tomo_core/pet/species.dart';

/// The colours (spec §9.1, ADR-0015). Promise 29: every colour role meets
/// 4.5:1 for text and 3:1 for parts, in light and in dark, around every pet.
void main() {
  // Before the hatch, then each species.
  const pets = <Species?>[null, ...Species.values];

  String hex(int c) => '#${(c & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

  for (final theme in ThemeName.values) {
    for (final species in pets) {
      final p = Palette.of(theme, species);
      final who = species?.name ?? 'egg';

      group('${theme.name}, $who', () {
        // Text and what it sits on, pressed shades included.
        final text = {
          'ink on ground': (p.ink, p.ground),
          'ink on surface': (p.ink, p.surface),
          'ink on sunken': (p.ink, p.sunken),
          'ink on pressed sunken': (p.ink, p.pressed(p.sunken)),
          'ink on pressed surface': (p.ink, p.pressed(p.surface)),
          'muted on ground': (p.muted, p.ground),
          'muted on surface': (p.muted, p.surface),
          'muted on sunken (turned off)': (p.muted, p.sunken),
          'on-accent on accent': (p.onAccent, p.accent),
          'on-accent on pressed accent': (p.onAccent, p.pressed(p.accent)),
          'on-destructive on destructive': (p.onDestructive, p.destructive),
          'on-destructive on pressed destructive': (
            p.onDestructive,
            p.pressed(p.destructive),
          ),
        };
        // Parts that carry meaning without words around them.
        final parts = {
          'field outline on surface': (p.boundary, p.surface),
          'typing outline on surface': (p.accent, p.surface),
          'focus ring on ground': (p.accent, p.ground),
          'focus ring on surface': (p.accent, p.surface),
          'doing glyph on surface': (p.accent, p.surface),
          'done glyph on surface': (p.muted, p.surface),
          'to-do glyph on surface': (p.ink, p.surface),
          'switch knob off, on sunken': (p.muted, p.sunken),
          'switch knob on, on accent': (p.onAccent, p.accent),
          'lit EXP block next to an unlit one': (p.accent, p.sunken),
          // Chosen is a solid block on an empty track, not a hue.
          'chosen segment on its track': (p.accent, p.sunken),
        };

        text.forEach((name, pair) {
          test('$name is at least 4.5:1', () {
            expect(
              contrast(pair.$1, pair.$2),
              greaterThanOrEqualTo(4.5),
              reason: '${hex(pair.$1)} on ${hex(pair.$2)}',
            );
          });
        });
        parts.forEach((name, pair) {
          test('$name is at least 3:1', () {
            expect(
              contrast(pair.$1, pair.$2),
              greaterThanOrEqualTo(3),
              reason: '${hex(pair.$1)} on ${hex(pair.$2)}',
            );
          });
        });

        test('a press always changes the shade', () {
          for (final fill in [p.accent, p.sunken, p.surface, p.destructive]) {
            expect(p.pressed(fill), isNot(fill), reason: hex(fill));
          }
        });
      });
    }
  }

  group('the species accent', () {
    test('is the spec table, copied from each pet', () {
      final table = {
        (ThemeName.light, null): 0xFF4A443C,
        (ThemeName.dark, null): 0xFFEDE7DC,
        (ThemeName.light, Species.geode): 0xFF3A6470,
        (ThemeName.dark, Species.geode): 0xFF6EE0C6,
        (ThemeName.light, Species.joe): 0xFF4A57B8,
        (ThemeName.dark, Species.joe): 0xFF6F7ED8,
        (ThemeName.light, Species.lily): 0xFF4A2A44,
        (ThemeName.dark, Species.lily): 0xFFC89AB3,
      };
      table.forEach((key, colour) {
        expect(hex(accentOf(key.$1, key.$2)), hex(colour), reason: '$key');
      });
    });

    test('labels on it are white in light and black in dark', () {
      for (final species in pets) {
        expect(Palette.of(ThemeName.light, species).onAccent, 0xFFFFFFFF);
        expect(Palette.of(ThemeName.dark, species).onAccent, 0xFF000000);
      }
    });
  });

  group('contrast', () {
    test('is 21 for black on white, either way round, and 1 for a colour on '
        'itself', () {
      expect(contrast(0xFF000000, 0xFFFFFFFF), closeTo(21, 1e-9));
      expect(contrast(0xFFFFFFFF, 0xFF000000), closeTo(21, 1e-9));
      expect(contrast(0xFF3A6470, 0xFF3A6470), 1);
    });
  });

  test('a press moves 22% toward the ink', () {
    expect(mix(0xFF000000, 0xFFFFFFFF, 0.22), 0xFF383838);
    final light = Palette.of(ThemeName.light, Species.geode);
    expect(light.pressed(light.sunken), mix(light.sunken, light.ink, 0.22));
  });
}

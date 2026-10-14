import 'package:test/test.dart';
import 'package:tomo_core/art/compose.dart';
import 'package:tomo_core/art/pets/geode.dart';
import 'package:tomo_core/art/pixel_art.dart';

const _n = 48;

/// A 48×48 grid, clear except for [pixels].
String _grid(Map<Px, String> pixels) => [
  for (var y = 0; y < _n; y++)
    [for (var x = 0; x < _n; x++) pixels[(x: x, y: y)] ?? '.'].join(),
].join('\n');

SpeciesArt _species({
  required List<Part> paintOrder,
  required Map<Part, String> parts,
  List<Px> eyes = const [],
  Map<EyeShape, Eye> faces = const {},
}) => SpeciesArt(
  name: 'Test',
  colours: const {},
  paintOrder: paintOrder,
  ridesWithHead: const {},
  twitches: const {},
  egg: const Egg(mark: Draft(), whole: '', cracks: []),
  stages: [
    Stage(
      mark: const Draft(),
      eyes: eyes,
      leanStep: 0,
      parts: {
        for (final part in Part.values) part: parts[part] ?? _grid(const {}),
      },
    ),
  ],
  eyeSheet: EyeSheet(mark: const Draft(), faces: faces),
);

void main() {
  test('a part later in the paint order covers an earlier one', () {
    final species = _species(
      paintOrder: [Part.body, Part.accent],
      parts: {
        Part.body: _grid({(x: 3, y: 4): 'B', (x: 5, y: 4): 'B'}),
        Part.accent: _grid({(x: 3, y: 4): 'A'}),
      },
    );

    final rows = composeStage(species, 0);

    expect(rows[4][3], 'A');
    expect(rows[4][5], 'B');
    expect(rows[0][0], '.');
  });

  test('the eyes are the face from the eye sheet, at each eye spot', () {
    final species = _species(
      paintOrder: [Part.head, Part.eyes],
      parts: {
        Part.head: _grid({for (var x = 0; x < 8; x++) (x: x, y: 10): 'H'}),
        // The stage's own eyes grid is not what is shown.
        Part.eyes: _grid({(x: 0, y: 0): 'X'}),
      },
      eyes: [(x: 1, y: 9), (x: 5, y: 9)],
      faces: {
        EyeShape.resting: const Eye((x: 0, y: 1), 'E.'),
        EyeShape.blink: const Eye((x: 0, y: 1), '.E'),
      },
    );

    final resting = composeStage(species, 0);
    expect(resting[10], 'HEHHHEHH${'.' * 40}');
    expect(resting[0][0], '.');

    final blink = composeStage(species, 0, face: EyeShape.blink);
    expect(blink[10], 'HHEHHHEH${'.' * 40}');
  });

  test('a real stage composes to a 48×48 picture standing on the grid', () {
    for (var i = 0; i < geode.stages.length; i++) {
      final rows = composeStage(geode, i);
      expect(rows, hasLength(_n));
      expect(rows.every((r) => r.length == _n), isTrue);
      expect(rows.join().replaceAll('.', ''), isNotEmpty);
    }
  });
}

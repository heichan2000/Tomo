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
  Set<Part> ridesWithHead = const {},
  Set<Part> twitches = const {},
  Set<Part> liftsOnJump = const {},
  int? breathRow,
}) => SpeciesArt(
  name: 'Test',
  colours: const {},
  paintOrder: paintOrder,
  ridesWithHead: ridesWithHead,
  twitches: twitches,
  liftsOnJump: liftsOnJump,
  egg: const Egg(mark: Draft(), whole: '', cracks: []),
  stages: [
    Stage(
      mark: const Draft(),
      eyes: eyes,
      leanStep: 0,
      breathRow: breathRow,
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

    final blink = composeStage(
      species,
      0,
      pose: const Pose(eyes: EyeShape.blink),
    );
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

  group('a pose slides whole parts by whole pixels (promise 21)', () {
    // A body, a head on it, the head's eye, and an accent on top: one column
    // each, so where every part went can be read off its letter.
    final species = _species(
      paintOrder: [Part.body, Part.head, Part.eyes, Part.accent],
      parts: {
        Part.body: _grid({(x: 10, y: 40): 'B', (x: 10, y: 30): 'b'}),
        Part.head: _grid({(x: 12, y: 20): 'H', (x: 13, y: 20): 'H'}),
        Part.accent: _grid({(x: 14, y: 10): 'A'}),
      },
      eyes: [(x: 12, y: 20)],
      faces: {
        EyeShape.resting: const Eye((x: 0, y: 0), 'E'),
        EyeShape.pleased: const Eye((x: 0, y: 0), 'P'),
      },
      ridesWithHead: {Part.head, Part.eyes},
      twitches: {Part.accent},
      liftsOnJump: {Part.accent},
      breathRow: 35,
    );

    /// Where each letter landed, as `letter@x,y`, read left to right, top
    /// to bottom.
    List<String> where(Pose pose) {
      final rows = composeStage(species, 0, pose: pose);
      return [
        for (var y = 0; y < _n; y++)
          for (var x = 0; x < _n; x++)
            if (rows[y][x] != '.') '${rows[y][x]}@$x,$y',
      ];
    }

    test('standing still', () {
      expect(where(Pose.rest), [
        'A@14,10',
        'E@12,20',
        'H@13,20',
        'b@10,30',
        'B@10,40',
      ]);
    });

    test('the lift raises the whole pet', () {
      expect(where(const Pose(lift: 2)), [
        'A@14,8',
        'E@12,18',
        'H@13,18',
        'b@10,28',
        'B@10,38',
      ]);
    });

    test('the drop sinks what rides with the head, and every row above the '
        'breath row', () {
      expect(where(const Pose(drop: 1)), [
        'A@14,11',
        'E@12,21',
        'H@13,21',
        'b@10,31',
        'B@10,40',
      ]);
    });

    test('the twitch lifts only the twitching part', () {
      expect(where(const Pose(twitch: 1)), [
        'A@14,9',
        'E@12,20',
        'H@13,20',
        'b@10,30',
        'B@10,40',
      ]);
    });

    test('the extra lift raises only the parts that lift on the jump', () {
      expect(where(const Pose(lift: 3, extra: 1)), [
        'A@14,6',
        'E@12,17',
        'H@13,17',
        'b@10,27',
        'B@10,37',
      ]);
    });

    test('the wiggle slides the whole pet sideways', () {
      expect(where(const Pose(wiggle: -1)), [
        'A@13,10',
        'E@11,20',
        'H@12,20',
        'b@9,30',
        'B@9,40',
      ]);
    });

    test('the eyes move alone, and show the face asked for', () {
      expect(where(const Pose(eyes: EyeShape.pleased, eyesX: 1, eyesY: -1)), [
        'A@14,10',
        'P@13,19',
        'H@12,20',
        'H@13,20',
        'b@10,30',
        'B@10,40',
      ]);
    });

    test('a pixel pushed off the grid is dropped', () {
      expect(where(const Pose(lift: 11)), [
        'E@12,9',
        'H@13,9',
        'b@10,19',
        'B@10,29',
      ]);
    });

    test('within a part, the rows that sink cover the rows below them', () {
      final species = _species(
        paintOrder: [Part.body],
        parts: {
          Part.body: _grid({(x: 0, y: 4): 'U', (x: 0, y: 5): 'L'}),
        },
        breathRow: 5,
      );
      final rows = composeStage(species, 0, pose: const Pose(drop: 1));
      expect(rows[4][0], '.');
      expect(rows[5][0], 'U');
    });
  });
}

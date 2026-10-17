import 'dart:math' as math;

import 'package:test/test.dart';
import 'package:tomo_core/art/compose.dart';
import 'package:tomo_core/art/drawings.dart';
import 'package:tomo_core/art/pixel_art.dart';
import 'package:tomo_core/look/palette.dart';
import 'package:tomo_core/pet/beat.dart';
import 'package:tomo_core/pet/pet_look.dart';
import 'package:tomo_core/pet/reward_colours.dart';
import 'package:tomo_core/pet/run_script.dart';
import 'package:tomo_core/pet/species.dart';

/// What a beat run shows at each moment (spec §7.5, ADR-0019): the timings of
/// Pixel reward effects (#39) and its hatch amendment.
void main() {
  RunScript script(
    List<Beat> run, {
    int expBefore = 700,
    Species species = Species.geode,
    ThemeName theme = ThemeName.light,
    Movement movement = Movement.full,
  }) => RunScript(
    run,
    species: species,
    expBefore: expBefore,
    theme: theme,
    movement: movement,
  );

  RunFrame at(RunScript s, int ms) => s.at(Duration(milliseconds: ms));

  const block = BlockCredited(minutes: 25, exp: 250);

  List<String> geodeStage(int stage) =>
      composeStage(artOf(Species.geode), stage - 1);

  group('block done', () {
    test('lasts 1.3 s, the pet bobbing Pleased at its stage', () {
      final s = script(const [block]);
      expect(s.length, const Duration(milliseconds: 1300));
      final frame = at(s, 0);
      expect(frame.beat, 0);
      expect(frame.pet, const ShownStage(stage: 1, face: Face.pleased));
      expect(frame.dither, isFalse);
    });

    test('lights the bar block by block from 300 ms, 70 ms apart, each new '
        'block popping', () {
      // 700 EXP is 100 into level 2: 3 blocks of 30. Plus 250 is 350: 11.
      final s = script(const [block]);
      expect(at(s, 299).bar, const BarShown(lit: 3));
      expect(at(s, 300).bar, const BarShown(lit: 4, pop: 3));
      expect(at(s, 369).bar, const BarShown(lit: 4, pop: 3));
      expect(at(s, 370).bar, const BarShown(lit: 5, pop: 4));
      expect(at(s, 790).bar, const BarShown(lit: 11, pop: 10));
      expect(at(s, 860).bar, const BarShown(lit: 11));
    });

    test('"+EXP" rises from 100 ms, a UI pixel every 60 ms to 9, settles at '
        '8 and is gone at 1.2 s', () {
      final s = script(const [block]);
      expect(at(s, 99).gain, isNull);
      expect(at(s, 100).gain, const Rise(exp: 250, dy: 1));
      expect(at(s, 160).gain, const Rise(exp: 250, dy: 2));
      expect(at(s, 580).gain, const Rise(exp: 250, dy: 9));
      expect(at(s, 640).gain, const Rise(exp: 250, dy: 8));
      expect(at(s, 1199).gain, const Rise(exp: 250, dy: 8));
      expect(at(s, 1200).gain, isNull);
    });

    test('under reduce motion "+EXP" cross-fades in place', () {
      final s = script(const [block], movement: Movement.reduced);
      expect(at(s, 100).gain, const Rise(exp: 250, dy: 0, opacity: 0));
      expect(at(s, 175).gain, const Rise(exp: 250, dy: 0, opacity: 0.5));
      expect(at(s, 600).gain, const Rise(exp: 250, dy: 0));
      expect(at(s, 1125).gain, const Rise(exp: 250, dy: 0, opacity: 0.5));
    });

    test('under reduce motion the bar jumps at 300 ms', () {
      final s = script(const [block], movement: Movement.reduced);
      expect(at(s, 299).bar, const BarShown(lit: 3));
      expect(at(s, 300).bar, const BarShown(lit: 11));
    });

    test('a block that reaches a new level fills the bar to the end', () {
      // 1100 EXP is 500 into level 2 (16 blocks); plus 250 crosses into 3.
      final s = script(const [block, LevelUp(level: 3)], expBefore: 1100);
      expect(at(s, 0).bar, const BarShown(lit: 16));
      expect(at(s, 1299).bar, const BarShown(lit: 20));
    });
  });

  group('level-up', () {
    // 1100 EXP is level 2; 1350 is level 3, 150 in: 5 blocks.
    final s = script(const [block, LevelUp(level: 3)], expBefore: 1100);

    test('follows the block beat: a Moment, the pet Celebrating, the choices '
        'at 3.5 s', () {
      expect(s.length, const Duration(milliseconds: 3500));
      final frame = at(s, 1300);
      expect(frame.beat, 1);
      expect(frame.pet, const ShownStage(stage: 1, face: Face.celebrating));
      expect(frame.dither, isTrue);
      expect(at(s, 1299).dither, isFalse);
    });

    test('the last beat lets the dither go 100 ms before the choices', () {
      expect(at(s, 3399).dither, isTrue);
      expect(at(s, 3400).dither, isFalse);
    });

    test('the "Level 3" plate pops in from 100 ms in steps of -4 -2 0 +1 0 UI '
        'pixels, then drops out by 1.84 s', () {
      expect(at(s, 1399).plate, isNull);
      expect(
        [
          for (final ms in [1400, 1470, 1540, 1610, 1680, 2999])
            at(s, ms).plate,
        ],
        [
          for (final dy in [-4, -2, 0, 1, 0, 0]) Plate(level: 3, dy: dy),
        ],
      );
      expect(at(s, 3000).plate, const Plate(level: 3, dy: -1));
      expect(at(s, 3070).plate, const Plate(level: 3, dy: -2));
      expect(at(s, 3140).plate, isNull);
    });

    test('the level shown changes as the plate arrives', () {
      expect(at(s, 1399).level, 2);
      expect(at(s, 1400).level, 3);
    });

    test('the bar, full, empties at 300 ms and refills from 400 ms, 90 ms '
        'apart', () {
      expect(at(s, 1599).bar, const BarShown(lit: 20));
      expect(at(s, 1600).bar, const BarShown(lit: 0));
      expect(at(s, 1700).bar, const BarShown(lit: 1, pop: 0));
      expect(at(s, 1790).bar, const BarShown(lit: 2, pop: 1));
      expect(at(s, 2060).bar, const BarShown(lit: 5, pop: 4));
      expect(at(s, 2150).bar, const BarShown(lit: 5));
    });

    test('six sparkles open in a ring around the pet from 150 ms, 170 ms '
        'apart, each playing 1 2 3 3 2 1 twice', () {
      // The first sparkle, every 70 ms from when it opens.
      final first = at(s, 1450).sparkles.single;
      final frames = [
        for (var ms = 0; ms < 1440; ms += 70)
          for (final k in at(s, 1450 + ms).sparkles)
            if (k.x == first.x && k.y == first.y) k.frame,
      ];

      expect(at(s, 1449).sparkles, isEmpty);
      expect(frames, [0, 1, 2, 2, 1, 0, 0, 1, 2, 2, 1, 0]);
      final centres = {
        for (var ms = 0; ms < 2200; ms += 10)
          for (final k in at(s, 1300 + ms).sparkles) (k.x, k.y),
      };
      expect(centres, hasLength(6));
      final pet = boundsOf(geodeStage(1));
      for (final (x, y) in centres) {
        expect(pet.contains(x, y), isFalse, reason: 'at ($x, $y)');
      }
    });

    test('under reduce motion the six sparkles hold still at frame 3, fading '
        'in and out', () {
      final r = script(
        const [block, LevelUp(level: 3)],
        expBefore: 1100,
        movement: Movement.reduced,
      );
      expect(at(r, 1449).sparkles, isEmpty);
      expect(at(r, 1550).sparkles, [
        for (final k in at(r, 1550).sparkles)
          SparkleShown(x: k.x, y: k.y, frame: 2, opacity: 0.5),
      ]);
      expect(at(r, 1550).sparkles, hasLength(6));
      expect(at(r, 2000).sparkles.map((k) => k.opacity), everyElement(1.0));
      expect(at(r, 2950).sparkles, isEmpty);
    });

    test('under reduce motion the plate cross-fades and the bar jumps', () {
      final r = script(
        const [block, LevelUp(level: 3)],
        expBefore: 1100,
        movement: Movement.reduced,
      );
      expect(at(r, 1400).plate, const Plate(level: 3, dy: 0, opacity: 0));
      expect(at(r, 1500).plate, const Plate(level: 3, dy: 0, opacity: 0.5));
      expect(at(r, 2000).plate, const Plate(level: 3, dy: 0));
      expect(at(r, 3100).plate, isNull);
      expect(at(r, 1600).bar, const BarShown(lit: 5));
    });
  });

  group('task done', () {
    // 700 EXP is 3 blocks into level 2; the bonus of 100 makes 800: 6.
    const task = TaskCompleted(bonusExp: 100);
    final s = script(const [task]);

    test('is a Moment of 2.45 s, the pet Celebrating, the dither going 100 ms '
        'before the choices', () {
      expect(s.length, const Duration(milliseconds: 2450));
      expect(at(s, 0).pet, const ShownStage(stage: 1, face: Face.celebrating));
      expect(at(s, 0).dither, isTrue);
      expect(at(s, 2349).dither, isTrue);
      expect(at(s, 2350).dither, isFalse);
    });

    test('the "Task done" plate, "+100 EXP" and the bar', () {
      expect(at(s, 99).plate, isNull);
      expect(at(s, 100).plate, const Plate(dy: -4));
      expect(at(s, 2050).plate, isNull);
      expect(at(s, 149).gain, isNull);
      expect(at(s, 150).gain, const Rise(exp: 100, dy: 1));
      expect(at(s, 1250).gain, isNull);
      expect(at(s, 349).bar, const BarShown(lit: 3));
      expect(at(s, 350).bar, const BarShown(lit: 4, pop: 3));
      expect(at(s, 440).bar, const BarShown(lit: 5, pop: 4));
      expect(at(s, 620).bar, const BarShown(lit: 6));
    });

    test('three sparkles open from 100 ms, 200 ms apart, once each', () {
      expect(at(s, 99).sparkles, isEmpty);
      final centres = {
        for (var ms = 0; ms < 2450; ms += 10)
          for (final k in at(s, ms).sparkles) (k.x, k.y),
      };
      expect(centres, hasLength(3));
      expect(at(s, 100).sparkles, hasLength(1));
      expect(at(s, 300).sparkles, hasLength(2));
      expect(at(s, 1000).sparkles, isEmpty);
    });

    test("36 pieces of confetti in the pet's colours launch from the top of "
        'its head within 140 ms of 150 ms, and are gone 2.4 s later', () {
      expect(at(s, 149).confetti, isEmpty);
      final pieces = at(s, 290).confetti;
      expect(pieces, hasLength(36));
      expect(
        pieces.map((p) => p.colour).toSet(),
        everyElement(isIn(confettiColours(ThemeName.light, Species.geode))),
      );
      // Every third piece is a single pixel; the others flutter between a
      // square of two and a strip of two.
      expect(pieces.where((p) => p.width == 1 && p.height == 1), hasLength(12));
      expect(pieces.where((p) => p.width == 2), hasLength(24));
      final head = boundsOf(geodeStage(1));
      final middle = (head.left + head.right) / 2;
      for (final p in pieces) {
        expect(p.y, lessThanOrEqualTo(head.top + 4));
        expect((p.x - middle).abs(), lessThanOrEqualTo(17));
      }
      expect(at(s, 150 + 140 + 2400 + 1).confetti, isEmpty);
    });

    test('under reduce motion there is no confetti, and six sparkles hold '
        'still at frame 3', () {
      final r = script(const [task], movement: Movement.reduced);
      expect(at(r, 290).confetti, isEmpty);
      expect(at(r, 1000).sparkles, hasLength(6));
      expect(at(r, 1000).sparkles.map((k) => k.frame), everyElement(2));
    });

    test('a bonus that reaches a new level fills the bar, and the level-up '
        'follows', () {
      final r = script(const [task, LevelUp(level: 3)], expBefore: 1100);
      expect(at(r, 2449).bar, const BarShown(lit: 20));
      expect(at(r, 2450).beat, 1);
      expect(at(r, 2450).dither, isTrue);
    });
  });

  group('evolution', () {
    // Level 10 begins at 5400 EXP, and with it stage 2.
    const run = [block, LevelUp(level: 10), Evolution(from: 1, to: 2)];
    final s = script(run, expBefore: 5300);
    const e = 3500;

    test('follows the level-up, and the choices come 4 s after it starts', () {
      expect(at(s, e - 1).beat, 1);
      expect(at(s, e).beat, 2);
      expect(s.length, const Duration(milliseconds: e + 4000));
    });

    test('the old stage holds through the beats before it', () {
      expect(at(s, 0).pet, const ShownStage(stage: 1, face: Face.pleased));
      expect(
        at(s, e - 1).pet,
        const ShownStage(stage: 1, face: Face.celebrating),
      );
    });

    test('small sparkles close in from three rings for 0.6 s', () {
      expect(at(s, e).pet, const ShownStage(stage: 1, face: Face.resting));
      final rings = [
        for (final ms in [e, e + 200, e + 400])
          {for (final k in at(s, ms).sparkles) (k.x, k.y)},
      ];
      expect(rings[0], hasLength(8));
      // Each ring is inside the one before.
      final box = boundsOf(geodeStage(1));
      double reach(Set<(int, int)> ring) =>
          ring.map((p) => (p.$1 - box.right).abs()).reduce(math.max).toDouble();
      final second = rings[1].difference(rings[0]);
      final third = rings[2].difference(rings[1]);
      expect(second, hasLength(8));
      expect(third, hasLength(8));
      expect(reach(second), lessThan(reach(rings[0])));
      expect(at(s, e + 599).sparkles, isNotEmpty);
    });

    test('then the flicker plays alone: five swaps at 0, 500, 950, 1350 and '
        '1700 ms, ending on the new stage', () {
      int stageAt(int ms) => (at(s, e + 600 + ms).pet as ShownStage).stage;
      expect(
        [
          for (final ms in [0, 499, 500, 949, 950, 1349, 1350, 1699])
            stageAt(ms),
        ],
        [2, 2, 1, 1, 2, 2, 1, 1],
      );
      expect(stageAt(1700), 2);
      for (var ms = e + 600; ms < e + 2300; ms += 10) {
        final frame = at(s, ms);
        expect((frame.pet as ShownStage).face, Face.still);
        expect(frame.sparkles, isEmpty, reason: 'at $ms');
        expect(frame.confetti, isEmpty);
        expect(frame.plate, isNull);
        expect(frame.gain, isNull);
      }
    });

    test('then 12 large sparkles open in a wave, 45 ms apart, 8 medium ones '
        'inside, and 44 pieces of confetti', () {
      final burst = e + 2300;
      expect(
        at(s, burst).pet,
        const ShownStage(stage: 2, face: Face.celebrating),
      );
      expect(at(s, burst).sparkles, hasLength(1));
      expect(at(s, burst + 45).sparkles, hasLength(2));
      final first = at(s, burst).sparkles.single;
      expect(
        [
          for (var ms = 0; ms < 560; ms += 70)
            for (final k in at(s, burst + ms).sparkles)
              if (k.x == first.x && k.y == first.y) k.frame,
        ],
        [0, 1, 2, 3, 3, 2, 1, 0],
      );
      final centres = {
        for (var ms = 0; ms < 1600; ms += 5)
          for (final k in at(s, burst + ms).sparkles) (k.x, k.y),
      };
      expect(centres, hasLength(20));
      expect(at(s, burst + 140).confetti, hasLength(44));
    });

    test('the dither holds from the level-up to 100 ms before the choices', () {
      for (var ms = 1300; ms < e + 3900; ms += 50) {
        expect(at(s, ms).dither, isTrue, reason: 'at $ms');
      }
      expect(at(s, e + 3900).dither, isFalse);
    });

    test('under reduce motion it is the 0.6 s cross-fade, then ten large '
        'sparkles held still', () {
      final r = script(run, expBefore: 5300, movement: Movement.reduced);
      expect(r.length, const Duration(milliseconds: e + 2700));
      expect(
        at(r, e + 599).pet,
        const ShownStage(stage: 1, face: Face.resting),
      );
      expect(
        at(r, e + 900).pet,
        const CrossFade(
          from: ShownStage(stage: 1, face: Face.resting),
          to: ShownStage(stage: 2, face: Face.still),
          share: 0.5,
        ),
      );
      expect(
        at(r, e + 1200).pet,
        const ShownStage(stage: 2, face: Face.celebrating),
      );
      final sparkles = at(r, e + 1500).sparkles;
      expect(sparkles, hasLength(10));
      expect(sparkles.map((k) => k.frame), everyElement(3));
      expect(at(r, e + 1500).confetti, isEmpty);
    });
  });

  group('hatch', () {
    const first = BlockCredited(minutes: 15, exp: 150);
    const run = [first, Hatch(species: Species.geode)];
    final s = script(run, expBefore: 0);
    const h = 1300;
    final lastCrack = eggPictureCount(Species.geode) - 1;

    test("the first block's beat plays with the egg holding still at its last "
        'crack', () {
      expect(at(s, 0).pet, ShownEgg(picture: lastCrack));
      expect(at(s, 100).gain, const Rise(exp: 150, dy: 1));
      expect(at(s, 1299).bar, const BarShown(lit: 5));
      expect(at(s, 0).cleared, isFalse);
      expect(at(s, 0).hatched, isFalse);
    });

    test('then the screen clears and the egg shakes three times, the last '
        'harder and faster', () {
      expect(at(s, h).cleared, isTrue);
      expect(at(s, h).dither, isFalse);
      int shift(int ms) => (at(s, h + ms).pet as ShownEgg).shift;
      expect(
        [
          for (final ms in [299, 300, 380, 460, 540, 620, 780]) shift(ms),
        ],
        [0, -1, 0, 1, 0, -1, 0],
      );
      expect(
        [
          for (final ms in [1100, 1180, 1260]) shift(ms),
        ],
        [-1, 0, 1],
      );
      expect(
        [
          for (final ms in [1799, 1800, 1860, 1920, 1980, 2399, 2400])
            shift(ms),
        ],
        [0, -1, 0, 1, 0, 0, 0],
      );
      expect(at(s, h + 2499).hatched, isFalse);
    });

    test('at 2.5 s the shell breaks with the pet already there, and its '
        'colour arrives', () {
      expect(
        at(s, h + 2500).pet,
        const ShownStage(stage: 1, face: Face.celebrating),
      );
      expect(at(s, h + 2500).hatched, isTrue);
      expect(at(s, h + 2500).sparkles, isNotEmpty);
      expect(at(s, h + 2500 + 140).confetti, hasLength(64));
    });

    test("the shell flies off from exactly where the egg was, all but the "
        "pet's own peeking eyes, and is gone after 1.5 s", () {
      final art = artOf(Species.geode);
      final egg = gridRows(art.egg.cracks.last);
      final expected = {
        for (var y = 0; y < egg.length; y++)
          for (var x = 0; x < egg[y].length; x++)
            if (egg[y][x] != '.' && !art.egg.staysAtHatch.contains(egg[y][x]))
              (x, y, art.colours[egg[y][x]]),
      };
      final shell = at(s, h + 2500).shell;
      expect({for (final p in shell) (p.x, p.y, p.colour)}, expected);
      expect(shell, hasLength(expected.length));

      double spread(int ms) {
        final pieces = at(s, h + 2500 + ms).shell;
        return pieces
                .map((p) => (p.x - 24).abs() + (p.y - 32).abs())
                .reduce((a, b) => a + b) /
            pieces.length;
      }

      expect(spread(500), greaterThan(spread(0)));
      expect(at(s, h + 4000).shell, isNotEmpty);
      expect(at(s, h + 4001).shell, isEmpty);
    });

    test('naming steps in at 3.7 s', () {
      expect(s.length, const Duration(milliseconds: h + 3700));
    });

    test('under reduce motion the egg still shakes a pixel, then cross-fades '
        'into the pet, which brings its colour and still sparkles', () {
      final r = script(run, expBefore: 0, movement: Movement.reduced);
      expect((at(r, h + 300).pet as ShownEgg).shift, -1);
      expect(
        at(r, h + 2800).pet,
        CrossFade(
          from: ShownEgg(picture: lastCrack),
          to: const ShownStage(stage: 1, face: Face.still),
          share: 0.5,
        ),
      );
      expect(at(r, h + 2800).hatched, isFalse);
      expect(at(r, h + 2800).shell, isEmpty);
      expect(at(r, h + 3100).hatched, isTrue);
      expect(at(r, h + 3500).sparkles, hasLength(12));
      expect(at(r, h + 3500).sparkles.map((k) => k.frame), everyElement(3));
      expect(at(r, h + 3500).confetti, isEmpty);
      expect(r.length, const Duration(milliseconds: h + 4300));
    });
  });

  group('the payload', () {
    test('steps in as the run ends: 4 UI pixels up into place over 280 ms', () {
      final s = script(const [block]);
      expect(at(s, 1299).payload, isNull);
      expect(at(s, 1300).payload, const StepIn(dy: 4));
      expect(at(s, 1440).payload, const StepIn(dy: 1));
      expect(at(s, 1580).payload, const StepIn(dy: 0));
    });

    test('under reduce motion it cross-fades in over 150 ms', () {
      final s = script(const [block], movement: Movement.reduced);
      expect(at(s, 1375).payload, const StepIn(dy: 0, opacity: 0.5));
      expect(at(s, 1450).payload, const StepIn(dy: 0));
    });

    test("once it is in, the pet is the screen's own again, while the last "
        "beat's confetti finishes falling", () {
      final s = script(const [TaskCompleted(bonusExp: 100)]);
      expect(at(s, 2450).pet, isNull);
      expect(at(s, 2450).confetti, isNotEmpty);
    });

    test('everything is still at the end, which is where a skip lands', () {
      final s = script(const [TaskCompleted(bonusExp: 100)]);
      // The choices finish stepping in 280 ms after 2.45 s; the last piece of
      // confetti is gone by 2.7 s.
      expect(s.end, const Duration(milliseconds: 2730));
      final frame = at(s, 2730);
      expect(frame.confetti, isEmpty);
      expect(frame.sparkles, isEmpty);
      expect(frame.plate, isNull);
      expect(frame.gain, isNull);
      expect(frame.dither, isFalse);
      expect(frame.bar, const BarShown(lit: 6));
      expect(frame.payload, const StepIn(dy: 0));
      final hatch = script(const [
        BlockCredited(minutes: 15, exp: 150),
        Hatch(species: Species.geode),
      ], expBefore: 0);
      expect(at(hatch, hatch.end.inMilliseconds).hatched, isTrue);
    });
  });
}

/// The smallest box holding every painted pixel of [rows].
({int left, int top, int right, int bottom, bool Function(int, int) contains})
boundsOf(List<String> rows) {
  var left = 48, top = 48, right = -1, bottom = -1;
  for (var y = 0; y < rows.length; y++) {
    for (var x = 0; x < rows[y].length; x++) {
      if (rows[y][x] == '.') continue;
      if (x < left) left = x;
      if (x > right) right = x;
      if (y < top) top = y;
      if (y > bottom) bottom = y;
    }
  }
  return (
    left: left,
    top: top,
    right: right,
    bottom: bottom,
    contains: (x, y) => x >= left && x <= right && y >= top && y <= bottom,
  );
}

import 'dart:math' as math;

import 'package:test/test.dart';
import 'package:tomo_core/art/compose.dart';
import 'package:tomo_core/art/pixel_art.dart';
import 'package:tomo_core/pet/pet_look.dart';
import 'package:tomo_core/pet/pet_motion.dart';
import 'package:tomo_core/pet/species.dart';

/// How the pet on screen moves (spec §7.3, §7.6): the timings of the movement
/// table, and the rules of ambient life. Promises 19 and 21.
void main() {
  HatchedLook pet(Face face, {Movement movement = Movement.full}) =>
      HatchedLook(
        species: Species.geode,
        movement: movement,
        stage: 1,
        face: face,
      );

  EggLook egg({bool mayWobble = true}) => EggLook(
    species: Species.joe,
    movement: Movement.full,
    picture: 0,
    mayWobble: mayWobble,
  );

  PetMotion motion(PetLook look, {int seed = 1}) =>
      PetMotion(look, random: math.Random(seed));

  Duration ms(int n) => Duration(milliseconds: n);

  /// Every 10 ms from [from] to [to], what [read] says, as `time: value`
  /// each time it changes.
  List<String> changes(
    PetMotion m,
    Object Function(Duration) read, {
    int from = 0,
    required int to,
  }) {
    final out = <String>[];
    Object? last;
    for (var t = from; t <= to; t += 10) {
      final now = read(ms(t));
      if (now != last) out.add('$t: $now');
      last = now;
    }
    return out;
  }

  group('the movement table', () {
    test('Resting breathes: down a pixel, then up, 0.8 s each way', () {
      final m = motion(pet(Face.resting));
      expect(changes(m, (t) => m.pose(t).drop, to: 2000), [
        '0: 0',
        '800: 1',
        '1600: 0',
      ]);
    });

    test('under reduce motion the breath takes 1.6 s each way', () {
      final m = motion(pet(Face.resting, movement: Movement.reduced));
      expect(changes(m, (t) => m.pose(t).drop, to: 3500), [
        '0: 0',
        '1600: 1',
        '3200: 0',
      ]);
    });

    test(
      'Resting blinks the bottom eye row for 0.15 s, every 2.6 to 6.4 s',
      () {
        for (var seed = 0; seed < 20; seed++) {
          final m = motion(pet(Face.resting), seed: seed);
          // Before the first idle move can start, at 15 s.
          final blinks = changes(
            m,
            (t) => m.pose(t).eyes == EyeShape.blink,
            to: 14900,
          ).skip(1).map((c) => int.parse(c.split(':').first)).toList();
          expect(blinks.length, greaterThanOrEqualTo(4), reason: 'seed $seed');
          expect(blinks.first, inInclusiveRange(2600, 6400));
          for (var i = 0; i + 1 < blinks.length; i += 2) {
            expect(blinks[i + 1] - blinks[i], 150, reason: 'shut 0.15 s');
          }
          for (var i = 2; i < blinks.length; i += 2) {
            // From one blink's end to the next one's start.
            expect(blinks[i] - blinks[i - 1], inInclusiveRange(2600, 6400));
          }
        }
      },
    );

    test(
      'Pleased bobs 1, 2, 1 pixels at 0.07 s as it begins, then breathes',
      () {
        final m = motion(pet(Face.pleased));
        expect(changes(m, (t) => m.pose(t).lift, to: 3000), [
          '0: 1',
          '70: 2',
          '140: 1',
          '210: 0',
        ]);
        expect(changes(m, (t) => m.pose(t).drop, to: 2000), [
          '0: 0',
          '800: 1',
          '1600: 0',
        ]);
        expect(m.pose(ms(500)).eyes, EyeShape.pleased);
      },
    );

    test('reduced, Pleased rises one pixel for 0.21 s', () {
      final m = motion(pet(Face.pleased, movement: Movement.reduced));
      expect(changes(m, (t) => m.pose(t).lift, to: 3000), ['0: 1', '210: 0']);
    });

    test('a restart plays the bob again', () {
      final m = motion(pet(Face.pleased));
      m.restart(ms(5000));
      expect(changes(m, (t) => m.pose(t).lift, from: 5000, to: 5300), [
        '5000: 1',
        '5070: 2',
        '5140: 1',
        '5210: 0',
      ]);
    });

    test('Drowsy sinks a pixel and breathes 1.6 s each way, either way', () {
      for (final movement in Movement.values) {
        final m = motion(pet(Face.drowsy, movement: movement));
        expect(changes(m, (t) => m.pose(t).drop, to: 3500), [
          '0: 1',
          '1600: 2',
          '3200: 1',
        ]);
        expect(m.pose(ms(100)).eyes, EyeShape.drowsy);
      }
    });

    test('Celebrating jumps 1,2,3,3,2,1 at 0.07 s, the head lands 0.14 s '
        'late, every 0.9 s', () {
      final m = motion(pet(Face.celebrating));
      String at(Duration t) {
        final p = m.pose(t);
        return 'lift ${p.lift} extra ${p.extra} drop ${p.drop}';
      }

      expect(changes(m, at, to: 960), [
        '0: lift 1 extra 0 drop 0',
        '70: lift 2 extra 1 drop 0',
        '140: lift 3 extra 1 drop 0',
        '280: lift 2 extra 1 drop 0',
        '350: lift 1 extra 0 drop 0',
        '420: lift 0 extra 0 drop 1',
        '560: lift 0 extra 0 drop 0',
        '900: lift 1 extra 0 drop 0',
      ]);
      expect(m.pose(ms(600)).eyes, EyeShape.pleased);
    });

    test('reduced, Celebrating is a one-pixel hop for 0.28 s, every 0.9 s', () {
      final m = motion(pet(Face.celebrating, movement: Movement.reduced));
      expect(changes(m, (t) => m.pose(t).lift, to: 1300), [
        '0: 1',
        '280: 0',
        '900: 1',
        '1180: 0',
      ]);
    });

    test('Still: nothing moves, no blink, for as long as it lasts', () {
      final m = motion(pet(Face.still));
      expect(changes(m, m.pose, to: 120000), ['0: ${Pose.rest}']);
    });

    test('reduced, nothing moves more than one pixel', () {
      for (final face in Face.values) {
        final m = motion(pet(face, movement: Movement.reduced));
        m.hello(ms(0));
        for (var t = 0; t <= 600000; t += 10) {
          final p = m.pose(ms(t));
          // Drowsy's sink is where it rests; its breath is the one pixel.
          final drop = face == Face.drowsy ? p.drop - 1 : p.drop;
          for (final shift in [
            p.eyesX,
            p.eyesY,
            drop,
            p.lift + p.extra,
            p.twitch,
            p.wiggle,
          ]) {
            expect(shift.abs(), lessThanOrEqualTo(1), reason: '$face at $t');
          }
        }
      }
    });
  });

  group('idle moves', () {
    /// The idle moves [m] plays from 0 to [to] ms, as `start: move`.
    List<(int, Act)> idleMoves(PetMotion m, {int to = 600000}) => [
      for (final c in changes(m, (t) => m.playing(t)?.name ?? 'none', to: to))
        if (!c.endsWith('none'))
          (int.parse(c.split(':').first), Act.values.byName(c.split(' ').last)),
    ];

    test('the resting pet plays one every 15 to 30 s, never the same twice '
        'in a row', () {
      for (var seed = 0; seed < 5; seed++) {
        final moves = idleMoves(motion(pet(Face.resting), seed: seed));
        expect(moves.length, greaterThan(20));
        expect(moves.first.$1, inInclusiveRange(15000, 30000));
        for (var i = 1; i < moves.length; i++) {
          expect(moves[i].$1 - moves[i - 1].$1, inInclusiveRange(15000, 30000));
          expect(moves[i].$2, isNot(moves[i - 1].$2));
        }
        expect({for (final m in moves) m.$2}, Act.idleMoves.toSet());
      }
    });

    test('only on the Resting face: never in a block, a break, a beat or '
        'under Calm pet', () {
      for (final face in Face.values.where((f) => f != Face.resting)) {
        expect(idleMoves(motion(pet(face))), isEmpty, reason: '$face');
      }
    });

    test('a new face stops a move in play and the schedule with it', () {
      final m = motion(pet(Face.resting));
      final first = idleMoves(m, to: 30000).first.$1;
      m.show(pet(Face.pleased), ms(first + 50));
      expect(m.playing(ms(first + 60)), isNull);
      expect(idleMoves(m, to: 600000).where((e) => e.$1 > first), isEmpty);
    });

    test('the moves, full and reduced', () {
      // Each move's shifts the first time it plays, from its start to the
      // first moment after it, as `time: value` on change.
      Map<Act, List<String>> moves(Movement movement) {
        final m = motion(pet(Face.resting, movement: movement));
        final out = <Act, List<String>>{};
        String shift(Act act, Pose p) => switch (act) {
          Act.glance => '${p.eyesX}',
          Act.lookUp => '${p.eyesY}',
          Act.doubleBlink => p.eyes.name,
          Act.twitch => '${p.twitch}',
          Act.wiggle => '${p.wiggle}',
          Act.hop => '${p.lift}',
        };
        final done = <Act>{};
        Act? act;
        var start = 0;
        String? last;
        for (var t = 0; t <= 600000 && done.length < 5; t += 10) {
          final playing = m.playing(ms(t));
          final pose = m.pose(ms(t));
          if (playing != null && playing != act && !done.contains(playing)) {
            act = playing;
            start = t;
            last = null;
          }
          if (act == null) continue;
          final seen = out[act];
          if (seen != null && seen.isNotEmpty && playing == null) {
            // The first moment after the move.
            final now = shift(act, pose);
            if (now != last) seen.add('${t - start}: $now');
            done.add(act);
            act = null;
            continue;
          }
          final list = out.putIfAbsent(act, () => []);
          final now = shift(act, pose);
          if (now != last) list.add('${t - start}: $now');
          last = now;
        }
        return out;
      }

      final full = moves(Movement.full);
      expect(full[Act.glance], [
        '0: 0',
        '150: -1',
        '850: 0',
        '1000: 1',
        '1700: 0',
      ]);
      expect(full[Act.lookUp], ['0: 0', '100: -1', '1100: 0']);
      // The breath's blinks aside, these two closes are the move's.
      expect(full[Act.doubleBlink]!.take(4), [
        '0: blink',
        '150: resting',
        '300: blink',
        '450: resting',
      ]);
      expect(full[Act.twitch], ['0: 1', '120: 0', '240: 1', '360: 0']);
      expect(full[Act.wiggle], [
        '0: -1',
        '100: 0',
        '200: 1',
        '300: 0',
        '400: -1',
        '500: 0',
        '600: 1',
        '700: 0',
      ]);

      final reduced = moves(Movement.reduced);
      expect(reduced[Act.glance], full[Act.glance]);
      expect(reduced[Act.lookUp], full[Act.lookUp]);
      expect(reduced[Act.twitch], ['0: 1', '200: 0']);
      expect(reduced[Act.wiggle], ['0: -1', '300: 0']);
    });
  });

  group('the hello and the tap', () {
    test(
      'the hello is the hop: 1, 2, 1 pixels at 0.07 s, happy eyes 0.6 s',
      () {
        final m = motion(pet(Face.resting));
        expect(m.hello(ms(1000)), isTrue);
        String at(Duration t) {
          final p = m.pose(t);
          return '${p.lift} ${p.eyes.name}';
        }

        expect(changes(m, at, from: 1000, to: 1700), [
          '1000: 1 pleased',
          '1070: 2 pleased',
          '1140: 1 pleased',
          '1210: 0 pleased',
          '1600: 0 resting',
        ]);
      },
    );

    test('reduced, the hop is one pixel for 0.21 s', () {
      final m = motion(pet(Face.resting, movement: Movement.reduced));
      m.hello(ms(0));
      expect(changes(m, (t) => m.pose(t).lift, to: 700), ['0: 1', '210: 0']);
    });

    test('a tap on the resting pet hops; taps during a move are ignored', () {
      final m = motion(pet(Face.resting));
      expect(m.tap(ms(0)), isTrue);
      expect(m.tap(ms(100)), isFalse);
      expect(m.tap(ms(590)), isFalse);
      expect(m.tap(ms(600)), isTrue);
    });

    test('in a block, a break, a beat or under Calm pet, neither the hello '
        'nor a tap does anything', () {
      for (final face in Face.values.where((f) => f != Face.resting)) {
        final m = motion(pet(face));
        final before = changes(m, m.pose, to: 1000);
        final again = motion(pet(face));
        expect(again.hello(ms(0)), isFalse, reason: '$face');
        expect(again.tap(ms(0)), isFalse, reason: '$face');
        expect(changes(again, again.pose, to: 1000), before);
      }
    });
  });

  group('the egg', () {
    test('waiting, it wobbles a pixel left then right, 150 ms steps, every '
        '15 to 30 s', () {
      final m = motion(egg());
      final shifts = changes(m, m.eggShift, to: 600000).skip(1).toList();
      expect(shifts.length, greaterThan(60));
      final starts = <int>[];
      for (var i = 0; i < shifts.length; i += 3) {
        final start = int.parse(shifts[i].split(':').first);
        starts.add(start);
        expect(shifts.sublist(i, i + 3), [
          '$start: -1',
          '${start + 150}: 1',
          '${start + 300}: 0',
        ]);
      }
      expect(starts.first, inInclusiveRange(15000, 30000));
      for (var i = 1; i < starts.length; i++) {
        expect(starts[i] - starts[i - 1], inInclusiveRange(15000, 30000));
      }
    });

    test('a tap wobbles it, once at a time', () {
      final m = motion(egg());
      expect(m.tap(ms(100)), isTrue);
      expect(m.tap(ms(200)), isFalse);
      expect(changes(m, m.eggShift, from: 100, to: 500), [
        '100: -1',
        '250: 1',
        '400: 0',
      ]);
    });

    test('when it may not wobble (Calm pet, or a block running) it holds '
        'still, tapped or not', () {
      final m = motion(egg(mayWobble: false));
      expect(m.tap(ms(0)), isFalse);
      expect(changes(m, m.eggShift, to: 600000), ['0: 0']);
    });

    test('Calm pet turned on stops a wobble in play', () {
      final m = motion(egg());
      m.tap(ms(0));
      m.show(egg(mayWobble: false), ms(50));
      expect(m.eggShift(ms(60)), 0);
      expect(changes(m, m.eggShift, from: 60, to: 600000), ['60: 0']);
    });
  });

  test('looking again only when nextChange says misses nothing', () {
    for (final look in [
      ...Face.values.map(pet),
      ...Face.values.map((f) => pet(f, movement: Movement.reduced)),
      egg(),
    ]) {
      Object read(PetMotion m, Duration t) =>
          look is EggLook ? m.eggShift(t) : m.pose(t);

      final every = motion(look);
      every.tap(ms(3000));
      final all = changes(every, (t) => read(every, t), to: 120000);

      final jumping = motion(look);
      jumping.tap(ms(3000));
      final seen = <String>[];
      Object? last;
      var t = Duration.zero;
      while (t <= ms(120000)) {
        final now = read(jumping, t);
        if (now != last) seen.add('${t.inMilliseconds}: $now');
        last = now;
        final next = jumping.nextChange(t);
        expect(next, greaterThan(t));
        expect(next - t, lessThanOrEqualTo(const Duration(seconds: 1)));
        t = next;
      }
      expect(seen, all, reason: '$look');
    }
  });
}

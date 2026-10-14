import 'package:test/test.dart';
import 'package:tomo_core/art/drawings.dart';
import 'package:tomo_core/focus/live_cycle.dart';
import 'package:tomo_core/focus/projection.dart';
import 'package:tomo_core/pet/beat.dart';
import 'package:tomo_core/pet/pet_look.dart';
import 'package:tomo_core/pet/species.dart';

/// `look(state, pending)` (spec §7.2): what the pet looks like, worked out
/// fresh and stored nowhere. Promises 17, 18 and 19.
void main() {
  final nine = DateTime.utc(2026, 10, 10, 9);

  LookState state({
    Species species = Species.geode,
    int exp = 1000,
    bool hatched = true,
    FocusState focus = FocusState.idle,
    bool calmPet = false,
    bool reduceMotion = false,
    LiveCycle? cycle,
    DateTime? now,
  }) => LookState(
    species: species,
    exp: exp,
    hatched: hatched,
    focus: focus,
    calmPet: calmPet,
    reduceMotion: reduceMotion,
    cycle: cycle,
    now: now ?? nine,
  );

  HatchedLook hatchedLook(
    LookState s, [
    PendingBeats pending = PendingBeats.none,
  ]) => look(s, pending) as HatchedLook;

  group('the face, one value off one ladder', () {
    test('everyday faces follow the timer', () {
      expect(hatchedLook(state(focus: FocusState.idle)).face, Face.resting);
      expect(
        hatchedLook(state(focus: FocusState.focusRunning)).face,
        Face.pleased,
      );
      expect(
        hatchedLook(state(focus: FocusState.focusComplete)).face,
        Face.resting,
      );
      expect(
        hatchedLook(state(focus: FocusState.breakRunning)).face,
        Face.drowsy,
      );
      expect(
        hatchedLook(state(focus: FocusState.breakComplete)).face,
        Face.resting,
      );
    });

    test('Calm pet replaces the three everyday faces with Still', () {
      for (final focus in FocusState.values) {
        expect(
          hatchedLook(state(focus: focus, calmPet: true)).face,
          Face.still,
          reason: focus.name,
        );
      }
    });

    test('the block-done beat shows Pleased', () {
      const playing = PendingBeats(
        playing: BlockCredited(minutes: 25, exp: 250),
      );

      expect(
        hatchedLook(state(focus: FocusState.focusComplete), playing).face,
        Face.pleased,
      );
    });

    test('a level-up, task-done, evolution or hatch beat shows '
        'Celebrating', () {
      for (final beat in const <Beat>[
        LevelUp(level: 3),
        TaskCompleted(bonusExp: 75),
        Evolution(from: 1, to: 2),
        Hatch(species: Species.geode),
      ]) {
        expect(
          hatchedLook(
            state(focus: FocusState.focusComplete),
            PendingBeats(playing: beat),
          ).face,
          Face.celebrating,
          reason: '$beat',
        );
      }
    });

    test('Calm pet never touches a beat', () {
      expect(
        hatchedLook(
          state(focus: FocusState.focusComplete, calmPet: true),
          const PendingBeats(playing: BlockCredited(minutes: 25, exp: 250)),
        ).face,
        Face.pleased,
      );
      expect(
        hatchedLook(
          state(focus: FocusState.focusComplete, calmPet: true),
          const PendingBeats(playing: LevelUp(level: 3)),
        ).face,
        Face.celebrating,
      );
    });

    test('a beat still waiting does not change the face', () {
      expect(
        hatchedLook(
          state(focus: FocusState.focusComplete),
          const PendingBeats(waiting: [LevelUp(level: 3)]),
        ).face,
        Face.resting,
      );
    });
  });

  group('idle moves', () {
    test('only the Resting face may make them', () {
      expect(hatchedLook(state()).mayIdle, isTrue);
      expect(
        hatchedLook(state(focus: FocusState.focusRunning)).mayIdle,
        isFalse,
      );
      expect(
        hatchedLook(state(focus: FocusState.breakRunning)).mayIdle,
        isFalse,
      );
    });

    test('Calm pet stills them', () {
      expect(hatchedLook(state(calmPet: true)).mayIdle, isFalse);
    });
  });

  group('the stage', () {
    test('comes from level', () {
      expect(hatchedLook(state(exp: 0)).stage, 1);
      expect(hatchedLook(state(exp: 9 * 600)).stage, 2);
      expect(hatchedLook(state(exp: 39 * 600)).stage, 3);
      expect(hatchedLook(state(exp: 99 * 600)).stage, 4);
    });

    test('holds the old stage while an evolution beat is still to play', () {
      // The settle has already raised the EXP into stage 2.
      final evolved = state(exp: 9 * 600 + 50, focus: FocusState.focusComplete);

      expect(
        hatchedLook(
          evolved,
          const PendingBeats(
            playing: BlockCredited(minutes: 25, exp: 250),
            waiting: [LevelUp(level: 10), Evolution(from: 1, to: 2)],
          ),
        ).stage,
        1,
      );
      expect(
        hatchedLook(
          evolved,
          const PendingBeats(
            playing: LevelUp(level: 10),
            waiting: [Evolution(from: 1, to: 2)],
          ),
        ).stage,
        1,
      );
    });

    test('reports the new stage once the evolution beat starts', () {
      final evolved = state(exp: 9 * 600 + 50, focus: FocusState.focusComplete);

      expect(
        hatchedLook(
          evolved,
          const PendingBeats(playing: Evolution(from: 1, to: 2)),
        ).stage,
        2,
      );
      expect(hatchedLook(evolved).stage, 2);
    });

    test('holds nothing back for any other waiting beat', () {
      expect(
        hatchedLook(
          state(exp: 1250, focus: FocusState.focusComplete),
          const PendingBeats(
            playing: BlockCredited(minutes: 25, exp: 250),
            waiting: [LevelUp(level: 3)],
          ),
        ).stage,
        1,
      );
    });
  });

  group('movement', () {
    test('is full, or reduced when the phone asks for less motion', () {
      expect(look(state(), PendingBeats.none).movement, Movement.full);
      expect(
        look(state(reduceMotion: true), PendingBeats.none).movement,
        Movement.reduced,
      );
    });

    test('Calm pet does not change it: two knobs, two needs', () {
      expect(
        look(state(calmPet: true), PendingBeats.none).movement,
        Movement.full,
      );
    });
  });

  test('the species is the one chosen at setup', () {
    for (final species in Species.values) {
      expect(look(state(species: species), PendingBeats.none).species, species);
    }
  });

  test('time away never changes the pet', () {
    final today = look(state(now: nine), PendingBeats.none);
    final muchLater = look(
      state(now: nine.add(const Duration(days: 90))),
      PendingBeats.none,
    );

    expect(muchLater, today);
  });

  group('before the hatch, the egg', () {
    LiveCycle firstBlock({int minutes = 20}) => LiveCycle(
      taskId: 1,
      startAt: nine,
      endAt: nine.add(Duration(minutes: minutes)),
      focusMinutes: minutes,
      breakMinutes: 5,
      autoStart: false,
    );

    EggLook egg(LookState s, [PendingBeats pending = PendingBeats.none]) =>
        look(s, pending) as EggLook;

    test('waits whole, outside the face ladder', () {
      final waiting = egg(state(hatched: false, exp: 0, species: Species.joe));

      expect(waiting.species, Species.joe);
      expect(waiting.picture, 0);
    });

    test("each species' egg has its own number of pictures", () {
      expect(eggPictureCount(Species.geode), 4);
      expect(eggPictureCount(Species.joe), 6);
      expect(eggPictureCount(Species.lily), 5);
      // The same as the eggs drawn: whole, then each crack.
      for (final species in Species.values) {
        expect(
          eggPictureCount(species),
          artOf(species).egg.cracks.length + 1,
          reason: '$species',
        );
      }
    });

    test('cracks in equal shares across a running block', () {
      // Geode: four pictures over 20 minutes, five minutes each.
      int pictureAt(int minute) => egg(
        state(
          hatched: false,
          exp: 0,
          focus: FocusState.focusRunning,
          cycle: firstBlock(),
          now: nine.add(Duration(minutes: minute)),
        ),
      ).picture;

      expect(pictureAt(0), 0);
      expect(pictureAt(4), 0);
      expect(pictureAt(5), 1);
      expect(pictureAt(10), 2);
      expect(pictureAt(19), 3);
    });

    test(
      'at the end of the block, before the settle, it holds its last crack',
      () {
        expect(
          egg(
            state(
              hatched: false,
              exp: 0,
              focus: FocusState.focusComplete,
              cycle: firstBlock(),
              now: nine.add(const Duration(minutes: 20)),
            ),
          ).picture,
          3,
        );
      },
    );

    test('stopping early leaves it whole again', () {
      expect(
        egg(state(hatched: false, exp: 0, focus: FocusState.idle)).picture,
        0,
      );
    });

    test('Calm pet does not hide the cracks: they are progress', () {
      expect(
        egg(
          state(
            hatched: false,
            exp: 0,
            calmPet: true,
            focus: FocusState.focusRunning,
            cycle: firstBlock(),
            now: nine.add(const Duration(minutes: 19)),
          ),
        ).picture,
        3,
      );
    });

    test('wobbles only while it waits, and never under Calm pet', () {
      expect(egg(state(hatched: false, exp: 0)).mayWobble, isTrue);
      expect(
        egg(state(hatched: false, exp: 0, calmPet: true)).mayWobble,
        isFalse,
      );
      for (final focus in FocusState.values.where(
        (f) => f != FocusState.idle,
      )) {
        expect(
          egg(state(hatched: false, exp: 0, focus: focus, cycle: firstBlock()))
              .mayWobble,
          isFalse,
          reason: '$focus',
        );
      }
    });

    test('the settle has hatched the pet, but until the hatch beat plays it '
        'is still the egg, at its last crack', () {
      // After the settle: hatched, with the first block's EXP.
      final settled = state(
        hatched: true,
        exp: 200,
        focus: FocusState.focusComplete,
      );

      final duringBlockBeat = egg(
        settled,
        const PendingBeats(
          playing: BlockCredited(minutes: 20, exp: 200),
          waiting: [Hatch(species: Species.geode)],
        ),
      );
      final waitingForTheTap = egg(
        settled,
        const PendingBeats(
          waiting: [
            BlockCredited(minutes: 20, exp: 200),
            Hatch(species: Species.geode),
          ],
        ),
      );

      expect(duringBlockBeat.picture, 3);
      expect(waitingForTheTap.picture, 3);
    });

    test('once the hatch beat starts, the pet is there, celebrating', () {
      final hatching = hatchedLook(
        state(hatched: true, exp: 200, focus: FocusState.focusComplete),
        const PendingBeats(playing: Hatch(species: Species.geode)),
      );

      expect(hatching.stage, 1);
      expect(hatching.face, Face.celebrating);
    });
  });
}

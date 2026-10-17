import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tomo/pet/run_player.dart';
import 'package:tomo_core/look/palette.dart';
import 'package:tomo_core/notifications/haptics.dart';
import 'package:tomo_core/pet/beat.dart';
import 'package:tomo_core/pet/pet_look.dart';
import 'package:tomo_core/pet/run_script.dart';
import 'package:tomo_core/pet/species.dart';

/// The run player (spec §7.4): a run plays in order, one beat at a time; a
/// tap anywhere skips it; it says whether it finished or was skipped, so the
/// screen can mark it seen; each beat fires one reward tap as it plays.
void main() {
  // A block that reaches level 3: the block beat (1.3 s), then the level-up
  // (2.2 s), then the choices.
  RunScript levelRun() => RunScript(
    const [BlockCredited(minutes: 25, exp: 250), LevelUp(level: 3)],
    species: Species.geode,
    expBefore: 1100,
    theme: ThemeName.light,
    movement: Movement.full,
  );

  late List<Haptic> taps;
  late List<RunEnd> ends;

  RunPlayer player(RunScript script) => RunPlayer(
    script: script,
    vsync: const TestVSync(),
    haptics: _Recorder((h) => taps.add(h)),
    onEnd: ends.add,
  );

  setUp(() {
    taps = [];
    ends = [];
  });

  testWidgets('plays the beats in order, one reward tap as each starts', (
    tester,
  ) async {
    final p = player(levelRun())..start();
    await tester.pump();
    expect(p.frame.beat, 0);
    expect(taps, [Haptic.rewardTap]);

    await tester.pump(const Duration(milliseconds: 1250));
    expect(p.frame.beat, 0);
    await tester.pump(const Duration(milliseconds: 100));
    expect(p.frame.beat, 1);
    expect(taps, [Haptic.rewardTap, Haptic.rewardTap]);
    p.dispose();
  });

  testWidgets('says it finished when the run reaches its payload, once', (
    tester,
  ) async {
    final p = player(levelRun())..start();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 3450));
    expect(ends, isEmpty);
    await tester.pump(const Duration(milliseconds: 100));
    expect(ends, [RunEnd.finished]);
    expect(p.frame.payload, isNotNull);

    // The last beat's effects play out, then everything holds still.
    await tester.pump(const Duration(seconds: 5));
    expect(ends, [RunEnd.finished]);
    expect(p.playing, isFalse);
    p.dispose();
  });

  testWidgets('a skip lands on the payload and says it was skipped; the beats '
      'not reached fire no tap', (tester) async {
    final p = player(levelRun())..start();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    p.skip();
    await tester.pump();
    expect(ends, [RunEnd.skipped]);
    expect(taps, [Haptic.rewardTap]);
    expect(p.frame.payload, const StepIn(dy: 0));
    expect(p.frame.bar, const BarShown(lit: 5));
    expect(p.playing, isFalse);

    await tester.pump(const Duration(seconds: 5));
    expect(ends, [RunEnd.skipped]);
    p.dispose();
  });

  testWidgets('a tap anywhere over the screen skips the run', (tester) async {
    final p = player(levelRun());
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SkipRun(player: p, child: const SizedBox.expand()),
      ),
    );
    p.start();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tapAt(const Offset(10, 10));
    await tester.pump();
    expect(ends, [RunEnd.skipped]);

    // Once it is over, taps go to the screen again.
    await tester.tapAt(const Offset(10, 10));
    expect(ends, [RunEnd.skipped]);
    p.dispose();
  });
}

class _Recorder implements HapticPlayer {
  _Recorder(this._record);

  final void Function(Haptic) _record;

  @override
  Future<void> play(Haptic haptic) async => _record(haptic);
}

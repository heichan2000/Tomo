import 'package:flutter_test/flutter_test.dart';
import 'package:tomo/pet/beats_screen.dart';
import 'package:tomo/pet/reward_view.dart';
import 'package:tomo/ui/motion.dart';

import '../ui/kit_harness.dart';

/// The debug beats screen plays every run to its end, in both themes, full
/// and reduced, and a tap on the stand-in skips.
void main() {
  for (final reduced in [false, true]) {
    testWidgets('every run plays to its end${reduced ? ', reduced' : ''}', (
      tester,
    ) async {
      await pumpKit(tester, const BeatsScreen(), reduceMotion: reduced);
      await tester.pump();
      final motion = find.words(reduced ? 'On' : 'Off').first;
      await tester.ensureVisible(motion);
      await tester.tap(motion);
      await tester.pump();
      await tester.ensureVisible(find.words('Repeat'));
      await tester.tap(find.words('Repeat'));
      await tester.pump();

      for (final (from, then) in [
        ('Block', 'Nothing'),
        ('Block', 'Level'),
        ('Block', 'Evolve'),
        ('Block', 'Hatch'),
        ('Task', 'Nothing'),
        ('Task', 'Level'),
        ('Task', 'Evolve'),
      ]) {
        final run = '$from then $then';
        for (final theme in ['Light', 'Dark']) {
          await tester.ensureVisible(find.words(theme).first);
          await tester.tap(find.words(theme).first);
          await tester.pump();
          for (final words in [from, then]) {
            await tester.ensureVisible(find.words(words).first);
            await tester.tap(find.words(words).first);
            await tester.pump();
          }
          await tester.pump();
          expect(find.byType(RewardPet), findsOneWidget, reason: run);
          expect(reduceMotion(tester.element(find.byType(RewardPet))), reduced);
          for (var ms = 0; ms < 12000; ms += 50) {
            await tester.pump(const Duration(milliseconds: 50));
            expect(tester.takeException(), isNull, reason: '$run at $ms');
          }
          expect(
            find.words('The run said: finished'),
            findsOneWidget,
            reason: '$run in $theme',
          );
        }
      }
    });
  }

  testWidgets('a tap on the stand-in skips the run', (tester) async {
    await pumpKit(tester, const BeatsScreen());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tapAt(tester.getCenter(find.byType(RewardPet)));
    await tester.pump();
    expect(find.words('The run said: skipped'), findsOneWidget);
    // Let the repeat timer run out.
    await tester.pump(const Duration(seconds: 2));
  });
}

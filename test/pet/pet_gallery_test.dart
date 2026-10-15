import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tomo/pet/pet_gallery_screen.dart';
import 'package:tomo/pet/pet_view.dart';

import '../ui/kit_harness.dart';

/// The debug pet gallery opens and every switch works, with nothing clipped.
void main() {
  for (final scale in [1.0, 2.0]) {
    testWidgets('every switch works at $scale text, with nothing clipped', (
      tester,
    ) async {
      await pumpKit(tester, const PetGalleryScreen(), textScale: scale);
      await tester.pump();
      expect(find.byType(PetView), findsNWidgets(3 * 4 + 4 + 6 + 5));

      for (final words in [
        'Block',
        'Break',
        'Done',
        'Beat again',
        'Level',
        'Rest',
        'Glance',
        'Hello',
        'Calm pet',
        'Dark',
        'On',
        'Joe',
        'Setup 96',
      ]) {
        await tester.ensureVisible(find.words(words).first);
        await tester.pump();
        await tester.tap(find.words(words).first);
        await tester.pump(const Duration(milliseconds: 500));
        expect(tester.takeException(), isNull, reason: words);
      }

      final scrollable = find.byType(Scrollable).first;
      final position = tester.state<ScrollableState>(scrollable).position;
      while (position.pixels < position.maxScrollExtent) {
        await tester.drag(scrollable, const Offset(0, -600));
        await tester.pump();
        expect(tester.takeException(), isNull);
      }
    });
  }
}

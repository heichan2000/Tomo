import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tomo/pet/pet_view.dart';
import 'package:tomo/ui/whole_dots.dart';
import 'package:tomo_core/art/compose.dart';
import 'package:tomo_core/art/pets/geode.dart';
import 'package:tomo_core/art/pets/joe.dart';
import 'package:tomo_core/art/pixel_art.dart';
import 'package:tomo_core/pet/pet_look.dart';
import 'package:tomo_core/pet/species.dart';

import '../ui/kit_harness.dart';

/// The pet on screen (spec §7.3, §7.6, §12). Its timings are kept in
/// `tomo_core` (`pet_motion_test.dart`); here, that the widget shows them,
/// answers taps only when it should, and is one silent screen-reader item.
/// Promise 32, the pet's half.
void main() {
  const label = 'Geode, level 7. 480 of 600 EXP toward level 8. Stage 1 of 4.';

  HatchedLook pet(Face face, {int stage = 1}) => HatchedLook(
    species: Species.geode,
    movement: Movement.full,
    stage: stage,
    face: face,
  );

  const egg = EggLook(
    species: Species.joe,
    movement: Movement.full,
    picture: 0,
    mayWobble: true,
  );

  var now = Duration.zero;
  setUp(() => now = Duration.zero);

  Future<void> show(
    WidgetTester tester,
    PetLook look, {
    PetCues? cues,
    Object? beat,
  }) => pumpKit(
    tester,
    PetView(
      look: look,
      spot: PetSpot.home,
      semanticLabel: label,
      cues: cues,
      beat: beat,
      elapsed: () => now,
    ),
  );

  /// Lets [ms] go by on the pet's clock and the test's.
  Future<void> wait(WidgetTester tester, int ms) async {
    now += Duration(milliseconds: ms);
    await tester.pump(Duration(milliseconds: ms));
  }

  List<String> shown(WidgetTester tester) =>
      tester.widget<PixelGrid>(find.byType(PixelGrid)).rows;

  testWidgets('it paints the look it is given', (tester) async {
    await show(tester, pet(Face.still, stage: 3));
    expect(shown(tester), composeStage(geode, 2));

    await show(
      tester,
      const EggLook(species: Species.joe, movement: Movement.full, picture: 2),
    );
    expect(shown(tester), gridRows(joe.egg.cracks[1]));
  });

  testWidgets('it stands in its spot, on the bottom edge', (tester) async {
    await show(tester, pet(Face.still));
    expect(tester.getSize(find.byType(PetView)), const Size.square(192));
    expect(
      tester.getBottomLeft(find.byType(PixelGrid)).dy,
      tester.getBottomLeft(find.byType(PetView)).dy,
    );
  });

  testWidgets('it moves: the breath, on time', (tester) async {
    await show(tester, pet(Face.resting));
    expect(shown(tester), composeStage(geode, 0));
    await wait(tester, 800);
    expect(shown(tester), composeStage(geode, 0, pose: const Pose(drop: 1)));
  });

  testWidgets('a tap on the resting pet hops', (tester) async {
    await show(tester, pet(Face.resting));
    await tester.tap(find.byType(PetView));
    await wait(tester, 80);
    expect(
      shown(tester),
      composeStage(geode, 0, pose: const Pose(eyes: EyeShape.pleased, lift: 2)),
    );
  });

  testWidgets('during a block a tap does nothing', (tester) async {
    await show(tester, pet(Face.pleased));
    await wait(tester, 1000);
    await tester.tap(find.byType(PetView));
    await wait(tester, 80);
    // Breathing, eyes pleased, not lifted.
    expect(
      shown(tester),
      composeStage(geode, 0, pose: const Pose(eyes: EyeShape.pleased, drop: 1)),
    );
  });

  testWidgets('the hello hops when the app opens onto the resting pet', (
    tester,
  ) async {
    final cues = PetCues();
    addTearDown(cues.dispose);
    await show(tester, pet(Face.resting), cues: cues);
    cues.hello();
    await wait(tester, 80);
    expect(
      shown(tester),
      composeStage(geode, 0, pose: const Pose(eyes: EyeShape.pleased, lift: 2)),
    );
  });

  testWidgets('a new beat starts the face over: the block-done bob', (
    tester,
  ) async {
    await show(tester, pet(Face.pleased));
    await wait(tester, 1000);
    await show(tester, pet(Face.pleased), beat: 'block done');
    await wait(tester, 80);
    expect(
      shown(tester),
      composeStage(geode, 0, pose: const Pose(eyes: EyeShape.pleased, lift: 2)),
    );
  });

  testWidgets('a tap on the waiting egg wobbles it', (tester) async {
    await show(tester, egg);
    await tester.tap(find.byType(PetView));
    await wait(tester, 10);
    expect(shown(tester), [
      for (final row in gridRows(joe.egg.whole)) '${row.substring(1)}.',
    ]);
  });

  testWidgets('to a screen reader it is one item, read as what the pet is, '
      'and silent while it moves', (tester) async {
    final semantics = tester.ensureSemantics();
    await show(tester, pet(Face.resting));

    void check() {
      final node = tester.getSemantics(find.byType(PetView));
      expect(node.label, label);
      expect(node.mergeAllDescendantsIntoThisNode || !node.hasChildren, isTrue);
      final data = node.getSemanticsData();
      expect(data.flagsCollection.isLiveRegion, isFalse);
      // The tap hop is for sighted users; the pet is not a button.
      expect(data.hasAction(SemanticsAction.tap), isFalse);
      // The picture inside is not an item of its own.
      expect(tester.getSemantics(find.byType(PixelGrid)).id, node.id);
    }

    check();
    await tester.tap(find.byType(PetView));
    // Through the hop and the first idle moves.
    for (var i = 0; i < 400; i++) {
      await wait(tester, 100);
    }
    check();
    semantics.dispose();
  });
}

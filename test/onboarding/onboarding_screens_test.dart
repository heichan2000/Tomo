import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tomo/app/shell.dart';
import 'package:tomo/onboarding/onboarding_screens.dart';
import 'package:tomo/pet/pet_view.dart';
import 'package:tomo/ui/buttons.dart';
import 'package:tomo/ui/pixel_icon.dart';
import 'package:tomo_core/art/pixel_art.dart';
import 'package:tomo_core/data/tomo_database.dart';
import 'package:tomo_core/look/palette.dart';
import 'package:tomo_core/pet/pet_look.dart';
import 'package:tomo_core/pet/species.dart';
import 'package:tomo_core/tasks/task_status.dart';

import '../app/app_harness.dart';
import '../ui/kit_harness.dart';

/// Onboarding (spec §8.2): choose an egg, say what you are working on,
/// and nothing is written until the end. The pet is a surprise until the
/// hatch (ADR-0031), and there is no personality to choose (ADR-0030).
void main() {
  Finder tile(String name) => find
      .ancestor(of: find.words(name), matching: find.byType(Pressable))
      .first;

  Finder button(String label) => find
      .ancestor(of: find.words(label), matching: find.byType(PixelButton))
      .first;

  bool enabled(WidgetTester tester, String label) =>
      tester.widget<PixelButton>(button(label)).onPressed != null;

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  /// Taps [label] on the second screen and lets its one write finish.
  Future<void> finishWith(WidgetTester tester, String label) async {
    await tester.tap(button(label));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
  }

  Future<List<T>> all<T>(
    WidgetTester tester,
    TomoDatabase db,
    Future<List<T>> Function() read,
  ) async => (await tester.runAsync(read))!;

  testTomo('it opens on Choose your egg, the stone egg chosen', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpTomo(tester, onboarded: false);

    expect(find.words('Choose your egg'), findsOneWidget);
    for (final name in ['Stone egg', 'Paper egg', 'Spotted egg']) {
      expect(find.words(name), findsOneWidget);
    }
    expect(
      tester.getSemantics(tile('Stone egg')),
      isSemantics(
        label: 'Stone egg',
        isButton: true,
        isSelected: true,
        hasSelectedState: true,
        isInMutuallyExclusiveGroup: true,
        hasTapAction: true,
        isEnabled: true,
        hasEnabledState: true,
        isFocusable: true,
      ),
    );
    expect(
      tester.getSemantics(tile('Paper egg')),
      isSemantics(isSelected: false),
    );
    expect(
      find.words('Cool, heavy and very still. Something patient is inside.'),
      findsOneWidget,
    );
    expect(find.byType(PetView), findsNWidgets(3));
    for (final view in tester.widgetList<PetView>(find.byType(PetView))) {
      expect(view.look, isA<EggLook>().having((l) => l.picture, 'whole', 0));
    }
    expect(find.words('Personality'), findsNothing);
    expect(find.words('Chatty'), findsNothing);
    semantics.dispose();
  });

  testTomo('the chosen egg has its hint, and no pet is named', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpTomo(tester, onboarded: false);

    await tap(tester, tile('Paper egg'));
    expect(
      tester.getSemantics(tile('Paper egg')),
      isSemantics(isSelected: true),
    );
    expect(
      tester.getSemantics(tile('Stone egg')),
      isSemantics(isSelected: false),
    );
    expect(
      find.words(
        'It rustles, neatly folded at every edge. Something tidy is inside.',
      ),
      findsOneWidget,
    );

    await tap(tester, tile('Spotted egg'));
    expect(
      find.words(
        'It wiggles when you look at it. Something cheerful is inside.',
      ),
      findsOneWidget,
    );
    for (final name in ['Geode', 'Joe', 'Lily']) {
      expect(find.textContaining(name), findsNothing);
    }
    semantics.dispose();
  });

  testTomo("the check sits in the chosen tile's corner, so no tile grows", (
    tester,
  ) async {
    await pumpTomo(tester, onboarded: false);
    final heights = [
      for (final name in ['Stone egg', 'Paper egg', 'Spotted egg'])
        tester.getSize(tile(name)).height,
    ];

    await tap(tester, tile('Spotted egg'));

    for (final (i, name) in ['Stone egg', 'Paper egg', 'Spotted egg'].indexed) {
      expect(tester.getSize(tile(name)).height, heights[i], reason: name);
    }
    final check = find.byWidgetPredicate(
      (w) => w is PixelIcon && w.name == IconName.check,
    );
    expect(check, findsOneWidget);
    expect(
      find.descendant(of: tile('Spotted egg'), matching: check),
      findsOneWidget,
    );
    final corner = tester.getTopLeft(check);
    final box = tester.getRect(tile('Spotted egg'));
    expect(
      corner.dy,
      lessThan(tester.getTopLeft(find.byType(PetView).last).dy),
    );
    expect(corner.dx - box.left, lessThan(box.width / 4));
  });

  testTomo('only the chosen egg sways', (tester) async {
    await pumpTomo(tester, onboarded: false);
    await tap(tester, tile('Paper egg'));

    final looks = [
      for (final view in tester.widgetList<PetView>(find.byType(PetView)))
        view.look as EggLook,
    ];
    expect([for (final look in looks) look.species], Species.values);
    expect([for (final look in looks) look.mayWobble], [false, true, false]);
  });

  testTomo('Back keeps the chosen pet; nothing is written before the end', (
    tester,
  ) async {
    final db = await pumpTomo(tester, onboarded: false);

    await tap(tester, tile('Spotted egg'));
    await tap(tester, button('Next'));

    expect(find.words('What are you working on?'), findsOneWidget);
    expect(await all(tester, db, db.select(db.pets).get), isEmpty);
    expect(await all(tester, db, db.select(db.projects).get), isEmpty);

    await tap(tester, find.bySemanticsLabel('Back'));
    expect(find.words('Choose your egg'), findsOneWidget);
    expect(
      tester.getSemantics(tile('Spotted egg')),
      isSemantics(isSelected: true),
    );
  });

  testTomo('Android back on the second screen goes to the first', (
    tester,
  ) async {
    await pumpTomo(tester, onboarded: false);
    await tap(tester, button('Next'));

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.words('Choose your egg'), findsOneWidget);
  });

  testTomo('Done stays off until a line is typed', (tester) async {
    await pumpTomo(tester, onboarded: false);
    await tap(tester, button('Next'));

    expect(enabled(tester, 'Done'), isFalse);
    expect(enabled(tester, 'Skip'), isTrue);

    await tester.enterText(find.byType(EditableText), '   ');
    await tester.pump();
    expect(enabled(tester, 'Done'), isFalse);

    await tester.enterText(find.byType(EditableText), 'Write the intro');
    await tester.pump();
    expect(enabled(tester, 'Done'), isTrue);
  });

  testTomo('the line is at most 60 characters, the project-name limit', (
    tester,
  ) async {
    await pumpTomo(tester, onboarded: false);
    await tap(tester, button('Next'));

    await tester.enterText(find.byType(EditableText), 'x' * 80);
    await tester.pump();

    final field = tester.widget<EditableText>(find.byType(EditableText));
    expect(field.controller.text, 'x' * 60);
  });

  testTomo('Done makes the egg, the project and the first task, then Home', (
    tester,
  ) async {
    final db = await pumpTomo(tester, onboarded: false);
    await tap(tester, tile('Paper egg'));
    await tap(tester, button('Next'));

    await tester.enterText(find.byType(EditableText), '  Write the intro ');
    await tester.pump();
    await finishWith(tester, 'Done');

    final pets = await all(tester, db, db.select(db.pets).get);
    expect(pets, hasLength(1));
    expect(pets.single.species, Species.joe);
    expect(pets.single.name, isNull);
    expect(pets.single.hatchedAt, isNull);
    final projects = await all(tester, db, db.select(db.projects).get);
    expect(projects.map((p) => p.name), ['Write the intro']);
    final tasks = await all(tester, db, db.select(db.tasks).get);
    expect(tasks.map((t) => t.title), ['Write the intro']);
    expect(tasks.single.status, TaskStatus.todo);
    expect(tasks.single.projectId, projects.single.id);

    expect(find.byType(TomoShell).hitTestable(), findsOneWidget);
    expect(find.byType(PickPetScreen), findsNothing);
    expect(find.byType(FirstTaskScreen), findsNothing);
  });

  testTomo('the keyboard\'s Done finishes too, once a line is typed', (
    tester,
  ) async {
    final db = await pumpTomo(tester, onboarded: false);
    await tap(tester, button('Next'));

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(await all(tester, db, db.select(db.pets).get), isEmpty);

    await tester.enterText(find.byType(EditableText), 'Thesis');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();

    final tasks = await all(tester, db, db.select(db.tasks).get);
    expect(tasks.map((t) => t.title), ['Thesis']);
    expect(find.byType(TomoShell), findsOneWidget);
  });

  testTomo('Skip makes the egg and one project called My work, no task', (
    tester,
  ) async {
    final db = await pumpTomo(tester, onboarded: false);
    await tap(tester, button('Next'));
    await tester.enterText(find.byType(EditableText), 'Typed, then skipped');
    await tester.pump();

    await finishWith(tester, 'Skip');

    final pets = await all(tester, db, db.select(db.pets).get);
    expect(pets.single.species, Species.geode);
    final projects = await all(tester, db, db.select(db.projects).get);
    expect(projects.map((p) => p.name), ['My work']);
    expect(await all(tester, db, db.select(db.tasks).get), isEmpty);
    expect(find.byType(TomoShell).hitTestable(), findsOneWidget);
  });

  testTomo('nothing overflows at 200% text, in both themes', (tester) async {
    for (final dpr in screens) {
      for (final theme in ThemeName.values) {
        await pumpTomo(
          tester,
          onboarded: false,
          dpr: dpr,
          textScale: 2,
          theme: theme,
        );
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(button('Next'));
        await tester.pumpAndSettle();
        await tap(tester, button('Next'));
        expect(tester.takeException(), isNull);
        expect(find.words('What are you working on?'), findsOneWidget);
      }
    }
  });
}

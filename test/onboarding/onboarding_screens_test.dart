import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tomo/app/shell.dart';
import 'package:tomo/onboarding/onboarding_screens.dart';
import 'package:tomo/ui/buttons.dart';
import 'package:tomo_core/data/tomo_database.dart';
import 'package:tomo_core/look/palette.dart';
import 'package:tomo_core/pet/personality.dart';
import 'package:tomo_core/pet/species.dart';
import 'package:tomo_core/tasks/task_status.dart';

import '../app/app_harness.dart';
import '../ui/kit_harness.dart';

/// Onboarding (spec §8.2): choose a pet and its personality, say what you are
/// working on, and nothing is written until the end.
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

  testTomo('it opens on Choose your pet, Geode and Quiet chosen', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpTomo(tester, onboarded: false);

    expect(find.words('Choose your pet'), findsOneWidget);
    for (final name in ['Geode', 'Joe', 'Lily']) {
      expect(find.words(name), findsOneWidget);
    }
    expect(
      tester.getSemantics(tile('Geode')),
      isSemantics(
        label: 'Geode',
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
    expect(tester.getSemantics(tile('Joe')), isSemantics(isSelected: false));
    expect(find.words('I am Geode. I keep every minute.'), findsOneWidget);
    expect(find.words('Personality'), findsOneWidget);
    expect(
      find.words('How much your pet says. You can change it in Settings.'),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testTomo('the chosen pet describes itself, Quiet or Chatty', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpTomo(tester, onboarded: false);

    await tap(tester, tile('Joe'));
    expect(tester.getSemantics(tile('Joe')), isSemantics(isSelected: true));
    expect(tester.getSemantics(tile('Geode')), isSemantics(isSelected: false));
    expect(find.words('Joe. 1 paper bird. I count.'), findsOneWidget);

    await tap(tester, find.words('Chatty'));
    expect(
      find.words(
        "I'm Joe! 1 paper bird who counts every block and every minute, "
        'out loud.',
      ),
      findsOneWidget,
    );

    await tap(tester, find.words('Quiet'));
    expect(find.words('Joe. 1 paper bird. I count.'), findsOneWidget);
    semantics.dispose();
  });

  testTomo('Back keeps the choices; nothing is written before the end', (
    tester,
  ) async {
    final db = await pumpTomo(tester, onboarded: false);

    await tap(tester, tile('Lily'));
    await tap(tester, find.words('Chatty'));
    await tap(tester, button('Next'));

    expect(find.words('What are you working on?'), findsOneWidget);
    expect(await all(tester, db, db.select(db.pets).get), isEmpty);
    expect(await all(tester, db, db.select(db.projects).get), isEmpty);

    await tap(tester, find.bySemanticsLabel('Back'));
    expect(find.words('Choose your pet'), findsOneWidget);
    expect(tester.getSemantics(tile('Lily')), isSemantics(isSelected: true));
    expect(find.words('Chatty'), findsOneWidget);
  });

  testTomo('Android back on the second screen goes to the first', (
    tester,
  ) async {
    await pumpTomo(tester, onboarded: false);
    await tap(tester, button('Next'));

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.words('Choose your pet'), findsOneWidget);
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
    await tap(tester, tile('Joe'));
    await tap(tester, find.words('Chatty'));
    await tap(tester, button('Next'));

    await tester.enterText(find.byType(EditableText), '  Write the intro ');
    await tester.pump();
    await finishWith(tester, 'Done');

    final pets = await all(tester, db, db.select(db.pets).get);
    expect(pets, hasLength(1));
    expect(pets.single.species, Species.joe);
    expect(pets.single.personality, Personality.chatty);
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
    expect(pets.single.personality, Personality.quiet);
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

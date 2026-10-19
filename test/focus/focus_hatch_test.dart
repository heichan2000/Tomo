import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tomo/focus/hatch.dart';
import 'package:tomo/home/home_screen.dart';
import 'package:tomo/ui/buttons.dart';
import 'package:tomo/ui/tomo_theme.dart';
import 'package:tomo_core/data/tomo_database.dart';
import 'package:tomo_core/look/palette.dart';
import 'package:tomo_core/testing.dart';

import '../app/app_harness.dart';
import '../ui/kit_harness.dart';

/// The hatch takeover (spec §8.7, ADR-0012, §17 C5–C6): the first block's
/// ordinary beat, then the screen cleared for the egg to break, then the
/// pet's hatch line, the **Name your …** field pre-filled with the species
/// name, and *Done*, back to Focus's choices.
void main() {
  // The first block starts at nine and runs to 9:25.
  final nine = DateTime.utc(2026, 10, 18, 9);
  DateTime at(int minute) => nine.add(Duration(minutes: minute));

  late TestClock clock;
  late TomoDatabase db;
  late WidgetTester current;

  /// Lets the database's work, on the real clock, reach the screen, without
  /// playing the run to its end.
  Future<void> catchUp(WidgetTester tester) async {
    for (var i = 0; i < 3; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)),
      );
      await tester.pump();
    }
    await petChanged(tester, db);
  }

  Future<void> settle(WidgetTester tester) async {
    await catchUp(tester);
    await tester.pumpAndSettle();
  }

  /// Opens the app on the egg's first block, a minute before its end.
  Future<void> open(
    WidgetTester tester, {
    double textScale = 1,
    ThemeName theme = ThemeName.light,
  }) async {
    current = tester;
    clock = TestClock(nine);
    db = await pumpTomo(
      tester,
      clock: clock.call,
      before: (db) async {
        await startBlockOn(db);
        clock.now = at(24);
      },
      textScale: textScale,
      theme: theme,
    );
    await settle(tester);
  }

  /// The block runs out, and its run starts playing: still on its first
  /// frames, the block beat.
  Future<void> blockEnds(WidgetTester tester) async {
    clock.now = at(25);
    await tester.pump(const Duration(minutes: 1));
    await catchUp(tester);
    await catchUp(tester);
  }

  /// The block runs out and its run plays through to the naming.
  Future<void> toNaming(WidgetTester tester) async {
    await blockEnds(tester);
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.tap(finder);
    await settle(tester);
    await settle(tester);
  }

  Future<void> back(WidgetTester tester) async {
    await tester.binding.handlePopRoute();
    await settle(tester);
  }

  Finder button(String label) =>
      find.ancestor(of: find.words(label), matching: find.byType(PixelButton));
  final field = find.byType(EditableText);
  Finder minimise() => find.bySemanticsLabel('Minimise');

  Future<PetRow> petRow() async =>
      (await current.runAsync(() => db.select(db.pets).getSingle()))!;
  Future<FocusCycleRow> cycleRow() async =>
      (await current.runAsync(() => db.select(db.focusCycle).getSingle()))!;

  const hatchLine =
      'Hello. Twenty-five minutes of Write the intro, and I am made of them.';

  testTomo('the block beat plays with Focus around it, then the takeover '
      'clears the screen', (tester) async {
    await open(tester);

    await blockEnds(tester);
    await tester.pump(const Duration(milliseconds: 400));
    expect(minimise(), findsOneWidget, reason: 'the ordinary beat first (C6)');
    expect(find.byType(HatchTakeover), findsNothing);

    await tester.pump(const Duration(seconds: 2));
    expect(find.byType(HatchTakeover), findsOneWidget);
    expect(minimise(), findsNothing, reason: 'no minimise in the takeover');
    expect(find.words('Take a 5-min break'), findsNothing);

    await tester.pumpAndSettle();
    expect(find.words(hatchLine), findsOneWidget);
    expect(find.words('Name your Geode'), findsOneWidget);
    expect(button('Done'), findsOneWidget);
  });

  testTomo('the accent is the egg\'s grey until the shell breaks', (
    tester,
  ) async {
    await open(tester);
    final grey = TomoColours.of(ThemeName.light, null).accent;
    Color accent() =>
        TomoTheme.of(tester.element(find.byType(HatchTakeover))).accent;

    await blockEnds(tester);
    await tester.pump(const Duration(seconds: 2));
    expect(accent(), grey);

    await tester.pumpAndSettle();
    expect(accent(), isNot(grey));
  });

  testTomo('Android back does nothing while the egg breaks', (tester) async {
    await open(tester);

    await blockEnds(tester);
    await tester.pump(const Duration(seconds: 2));
    await tester.binding.handlePopRoute();
    await tester.pump();

    expect(find.byType(HatchTakeover), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
    expect((await petRow()).name, isNull);
  });

  testTomo('the name is pre-filled with the species name, and Done keeps it', (
    tester,
  ) async {
    await open(tester);
    await toNaming(tester);

    expect(tester.widget<EditableText>(field).controller.text, 'Geode');

    await tap(tester, button('Done'));

    expect((await petRow()).name, 'Geode');
    expect(find.byType(HatchTakeover), findsNothing);
    expect(button('Take a 5-min break'), findsOneWidget);
    expect(find.words(hatchLine), findsOneWidget, reason: 'the line stays');
    expect((await cycleRow()).seenAt, isNotNull);
  });

  testTomo('a typed name is kept, trimmed', (tester) async {
    await open(tester);
    await toNaming(tester);

    await tester.enterText(field, '  Pebble ');
    await tap(tester, button('Done'));

    expect((await petRow()).name, 'Pebble');
  });

  testTomo('the keyboard\'s Done key names the pet too', (tester) async {
    await open(tester);
    await toNaming(tester);

    await tester.enterText(field, 'Pebble');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await settle(tester);
    await settle(tester);

    expect((await petRow()).name, 'Pebble');
    expect(button('Take a 5-min break'), findsOneWidget);
  });

  testTomo('a name cleared away is the species name again', (tester) async {
    await open(tester);
    await toNaming(tester);

    await tester.enterText(field, '   ');
    await tap(tester, button('Done'));

    expect((await petRow()).name, 'Geode');
  });

  testTomo('a name stops at 20 characters', (tester) async {
    await open(tester);
    await toNaming(tester);

    await tester.enterText(field, 'A' * 25);
    await tester.pump();

    expect(tester.widget<EditableText>(field).controller.text, 'A' * 20);
  });

  testTomo('the first touch selects the whole name, so typing replaces it', (
    tester,
  ) async {
    await open(tester);
    await toNaming(tester);

    await tester.tap(field);
    await tester.pump();
    await tester.pump();

    final selection = tester.widget<EditableText>(field).controller.selection;
    expect(selection.start, 0);
    expect(selection.end, 'Geode'.length);
  });

  testTomo('Android back on the naming acts as Done', (tester) async {
    await open(tester);
    await toNaming(tester);

    await tester.enterText(field, 'Pebble');
    await back(tester);
    await settle(tester);

    expect((await petRow()).name, 'Pebble');
    expect(button('Take a 5-min break'), findsOneWidget);
  });

  testTomo('a tap skips the breaking egg straight to the naming', (
    tester,
  ) async {
    await open(tester);

    await blockEnds(tester);
    await tester.pump(const Duration(seconds: 2));
    await tester.tapAt(const Offset(200, 200));
    await tester.pump();

    expect(button('Done'), findsOneWidget);
    await tap(tester, button('Done'));
    expect((await petRow()).name, 'Geode');
  });

  testTomo('a screen reader hears the field as Name your Geode', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await open(tester);
    await toNaming(tester);

    expect(find.bySemanticsLabel('Name your Geode'), findsOneWidget);
    semantics.dispose();
  });

  testTomo('at 200% text in dark, the naming scrolls rather than clips', (
    tester,
  ) async {
    await open(tester, textScale: 2, theme: ThemeName.dark);
    await toNaming(tester);
    expect(tester.takeException(), isNull);

    await tap(tester, button('Done'));
    expect(button('Take a 5-min break'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tomo/app/providers.dart';
import 'package:tomo/settings/licences_screen.dart';
import 'package:tomo/settings/settings_screen.dart';
import 'package:tomo/ui/buttons.dart';
import 'package:tomo/ui/font_licence.dart';
import 'package:tomo/ui/segmented.dart';
import 'package:tomo/ui/sharp_text.dart';
import 'package:tomo/ui/switch.dart';
import 'package:tomo/ui/text_field.dart';
import 'package:tomo/ui/tomo_theme.dart';
import 'package:tomo_core/data/settings.dart';
import 'package:tomo_core/data/tomo_database.dart';
import 'package:tomo_core/diagnostics/diagnostic_entry.dart';
import 'package:tomo_core/look/palette.dart';

import '../app/app_harness.dart';
import '../platform/fake_notifications.dart';
import '../ui/kit_harness.dart';

/// Settings (spec §8.10): Rename pet once hatched, Calm pet, Auto-start, the
/// notification status and the phone's settings, Appearance, and About with
/// the version, the licences and Share diagnostics.
void main() {
  Finder iconButton(String label) => find.byWidgetPredicate(
    (widget) => widget is PixelIconButton && widget.semanticLabel == label,
  );

  Finder switchRow(String title) => find.byWidgetPredicate(
    (widget) => widget is PixelSwitchRow && widget.title == title,
  );

  ProviderContainer container(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(SettingsScreen)));

  /// Lets the stores' and the database's work finish on the real clock.
  Future<void> settle(WidgetTester tester, TomoDatabase db) async {
    for (var i = 0; i < 3; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)),
      );
      await tester.pump();
    }
    await petChanged(tester, db);
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, TomoDatabase db, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.tap(finder);
    await settle(tester, db);
  }

  Future<void> hatch(TomoDatabase db, {String? name = 'Pip'}) =>
      db.customStatement(
        "UPDATE pets SET name = ${name == null ? 'NULL' : "'$name'"}, "
        'exp = 150, hatched_at = 1',
      );

  Future<void> openSettings(WidgetTester tester, TomoDatabase db) async {
    await settle(tester, db);
    await tester.tap(iconButton('Settings'));
    await settle(tester, db);
    expect(find.byType(SettingsScreen), findsOneWidget);
  }

  testTomo('the five groups, in order', (tester) async {
    final db = await pumpTomo(tester, before: hatch);
    await openSettings(tester, db);

    for (final label in [
      'Settings',
      'Pet',
      'Rename pet',
      'Calm pet',
      'Focus',
      'Auto-start',
      'Notifications',
      'Appearance',
      'Match phone',
      'About',
      'Version',
      'Licences',
      'Share diagnostics',
    ]) {
      expect(find.words(label), findsOneWidget, reason: label);
    }
    expect(find.words('Pip'), findsOneWidget);
    expect(find.words('1.0.0 (1)'), findsOneWidget);
    // No personality to choose (ADR-0030).
    expect(find.textContaining('Personality'), findsNothing);
  });

  testTomo('before the hatch there is no Rename pet', (tester) async {
    final db = await pumpTomo(tester);
    await openSettings(tester, db);

    expect(find.words('Rename pet'), findsNothing);
    expect(find.words('Calm pet'), findsOneWidget);
  });

  testTomo('Rename pet writes the new name', (tester) async {
    final db = await pumpTomo(tester, before: hatch);
    await openSettings(tester, db);

    await tap(tester, db, find.words('Rename pet'));
    final field = find.byType(PixelTextField);
    expect(field, findsOneWidget);
    await tester.enterText(field, '  Pebble ');
    await tester.pump();
    await tap(tester, db, find.words('Rename'));

    final pet = await tester.runAsync(() => db.select(db.pets).getSingle());
    expect(pet!.name, 'Pebble');
    expect(find.byType(PixelTextField), findsNothing);
    expect(find.words('Pebble'), findsOneWidget);
  });

  testTomo('Calm pet and Auto-start switch at once, and are kept', (
    tester,
  ) async {
    final db = await pumpTomo(tester, before: hatch);
    await openSettings(tester, db);

    await tap(tester, db, switchRow('Calm pet'));
    await tap(tester, db, switchRow('Auto-start'));

    final ref = container(tester);
    expect(ref.read(calmPetProvider), isTrue);
    expect(ref.read(autoStartProvider).value, isTrue);
    final settings = ref.read(settingsProvider);
    expect(await tester.runAsync(settings.calmPet), isTrue);
    expect(await tester.runAsync(settings.autoStart), isTrue);
    expect(tester.widget<PixelSwitchRow>(switchRow('Calm pet')).value, isTrue);
  });

  testTomo('Appearance changes the theme at once', (tester) async {
    final db = await pumpTomo(tester, before: hatch, theme: ThemeName.light);
    await openSettings(tester, db);
    final segmented = find.byType(PixelSegmented<Appearance>);
    expect(
      tester.widget<PixelSegmented<Appearance>>(segmented).selected,
      Appearance.system,
    );

    await tap(tester, db, find.words('Dark'));

    expect(container(tester).read(appearanceProvider), Appearance.dark);
    expect(
      await tester.runAsync(
        container(tester).read(settingsProvider).appearance,
      ),
      Appearance.dark,
    );
    expect(
      tester.widget<PixelSegmented<Appearance>>(segmented).selected,
      Appearance.dark,
    );
  });

  group('notifications', () {
    for (final (access, asked, line) in [
      ((enabled: true, canAsk: true), false, 'Notifications are on'),
      ((enabled: false, canAsk: false), true, 'Notifications are off'),
      (
        (enabled: false, canAsk: true),
        false,
        'Not asked yet. Your phone will ask when you start your first block.',
      ),
    ]) {
      testTomo(line, (tester) async {
        final permission = FakePermission(access: access);
        final db = await pumpTomo(
          tester,
          before: hatch,
          permission: permission,
        );
        if (asked) {
          await tester.runAsync(
            () => ProviderScope.containerOf(
              tester.element(find.byType(TomoTheme).first),
            ).read(deviceOnlyFileProvider).setNotificationPermissionAsked(),
          );
        }
        await openSettings(tester, db);

        expect(find.words(line), findsOneWidget);
        await tap(tester, db, find.words('Open system settings'));
        expect(permission.settingsOpened, 1);
      });
    }
  });

  testTomo('Share diagnostics is off with no errors recorded', (tester) async {
    final shared = SharedTexts();
    final db = await pumpTomo(tester, before: hatch, shareSheet: shared);
    await openSettings(tester, db);

    expect(find.words('No errors recorded'), findsOneWidget);
    final button = find.byWidgetPredicate(
      (widget) => widget is PixelButton && widget.label == 'Share diagnostics',
    );
    expect(tester.widget<PixelButton>(button).onPressed, isNull);
  });

  testTomo('Share diagnostics hands the log to the share sheet', (
    tester,
  ) async {
    final shared = SharedTexts();
    final db = await pumpTomo(tester, before: hatch, shareSheet: shared);
    final log = ProviderScope.containerOf(
      tester.element(find.byType(TomoTheme).first),
    ).read(diagnosticLogProvider);
    // Recorded on the real clock, where the log's file work runs.
    await tester.runAsync(() {
      for (var i = 0; i < 2; i++) {
        log.record(
          DiagnosticEntry.error(
            DiagnosticCode.taskWriteFailed,
            StateError('secret words'),
            StackTrace.current,
            at: DateTime.utc(2026, 10, 19),
          ),
        );
      }
      return log.settled;
    });
    await openSettings(tester, db);

    expect(find.words('2 errors recorded'), findsOneWidget);
    await tap(tester, db, find.words('Share diagnostics'));
    await settle(tester, db);

    expect(shared.shared, hasLength(1));
    expect(shared.shared.single.fileName, 'tomo-diagnostics.txt');
    expect(shared.shared.single.text, contains('taskWriteFailed'));
    expect(shared.shared.single.text, isNot(contains('secret words')));
  });

  testTomo('Licences lists the font, and opens its text', (tester) async {
    registerFontLicence();
    final db = await pumpTomo(tester, before: hatch);
    await openSettings(tester, db);

    await tap(tester, db, find.words('Licences'));
    expect(find.byType(LicencesScreen), findsOneWidget);
    await tap(tester, db, find.words('Ark Pixel Font'));
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is PixelText &&
            widget.words.contains('SIL OPEN FONT LICENSE Version 1.1'),
      ),
      findsOneWidget,
    );
  });
}

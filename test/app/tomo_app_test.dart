import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tomo/app/error_block.dart';
import 'package:tomo/app/shell.dart';
import 'package:tomo/onboarding/onboarding_screens.dart';
import 'package:tomo/l10n/app_localizations.dart';
import 'package:tomo/ui/tomo_theme.dart';
import 'package:tomo_core/data/settings.dart';
import 'package:tomo_core/look/palette.dart';

import '../ui/kit_harness.dart';
import 'app_harness.dart';

/// The app's root: where a cold start lands (spec §8.1), and the error block
/// when the database can't be opened (§6.2, §8.11).
void main() {
  testTomo('with no pet, it opens on Onboarding, above no shell', (
    tester,
  ) async {
    await pumpTomo(tester, onboarded: false);

    expect(find.byType(PickPetScreen), findsOneWidget);
    expect(find.byType(TomoShell), findsNothing);
  });

  testTomo('the app name comes from the copy files', (tester) async {
    await pumpTomo(tester);

    final context = tester.element(find.byType(TomoShell));
    expect(AppLocalizations.of(context).appName, 'Tomo');
    expect(tester.widget<Title>(find.byType(Title)).title, 'Tomo');
  });

  testTomo('before the hatch, the accent is the neutral one', (tester) async {
    await pumpTomo(tester);

    final colours = TomoTheme.of(tester.element(find.byType(TomoShell)));
    expect(colours.accent, TomoColours.of(ThemeName.light, null).accent);
  });

  group('the error block', () {
    testWidgets('is what opens when start-up fails: the line, no pet', (
      tester,
    ) async {
      await loadArkPixel();
      await tester.pumpWidget(
        const StartFailedApp(appearance: Appearance.dark),
      );
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(ErrorBlock));
      expect(find.words(AppLocalizations.of(context).error), findsOneWidget);
      expect(TomoTheme.of(context).dark, isTrue);
      expect(find.byType(TomoShell), findsNothing);
    });

    testWidgets('names Share diagnostics, in plain words', (tester) async {
      await tester.pumpWidget(
        const StartFailedApp(appearance: Appearance.light),
      );
      await tester.pumpAndSettle();

      final words = AppLocalizations.of(tester.element(find.byType(ErrorBlock)))
          .error;
      expect(words, contains('Settings > About > Share diagnostics'));
    });

    testWidgets('stands alone, with nothing of the app above it', (
      tester,
    ) async {
      await tester.pumpWidget(const ErrorBlock());

      expect(tester.takeException(), isNull);
      expect(find.textContaining('Share diagnostics'), findsOneWidget);
    });

    testWidgets('fits at 200% text', (tester) async {
      await loadArkPixel();
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(
        const StartFailedApp(appearance: Appearance.system),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}

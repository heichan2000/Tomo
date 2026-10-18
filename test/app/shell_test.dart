import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tomo/app/placeholder_screens.dart';
import 'package:tomo/app/routes.dart';
import 'package:tomo/home/home_screen.dart';
import 'package:tomo/app/shell.dart';
import 'package:tomo/ui/buttons.dart';
import 'package:tomo/ui/kit_gallery_screen.dart';
import 'package:tomo/ui/sheet.dart';
import 'package:tomo_core/look/palette.dart';

import '../ui/kit_harness.dart';
import 'app_harness.dart';

/// The shell (spec §8.1, §15.1): two tabs that each keep their own stack, the
/// banner's place, the tab bar, Android back, and the wide-screen column.
void main() {
  Finder tabWords(String label) => find.descendant(
    of: find.byType(ShellTabBar),
    matching: find.words(label),
  );

  Finder tab(String label) => find
      .ancestor(of: tabWords(label), matching: find.byType(GestureDetector))
      .first;

  Finder tabBarShown() => tabWords('Home').hitTestable();

  Future<void> back(WidgetTester tester) async {
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
  }

  Finder gear() => find.byWidgetPredicate(
    (widget) => widget is PixelIconButton && widget.semanticLabel == 'Settings',
  );

  bool showing(WidgetTester tester, String words) =>
      find.words(words).hitTestable().evaluate().isNotEmpty;

  testTomo('a cold start opens the shell on Home, with two tabs', (
    tester,
  ) async {
    await pumpTomo(tester);

    expect(find.byType(TomoShell), findsOneWidget);
    expect(find.byType(HomeScreen).hitTestable(), findsOneWidget);
    expect(find.words('Home'), findsWidgets);
    expect(find.words('Work'), findsWidgets);
    expect(find.byType(RunningBannerSlot), findsOneWidget);
  });

  testTomo('the tab you are on is the selected one to a screen reader', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpTomo(tester);

    expect(
      tester.getSemantics(tabWords('Home')),
      isSemantics(
        label: 'Home',
        isButton: true,
        isSelected: true,
        hasSelectedState: true,
        isInMutuallyExclusiveGroup: true,
        hasTapAction: true,
        hasLongPressAction: true,
      ),
    );
    expect(
      tester.getSemantics(tabWords('Work')),
      isSemantics(
        label: 'Work',
        isButton: true,
        isSelected: false,
        hasSelectedState: true,
        isInMutuallyExclusiveGroup: true,
        hasTapAction: true,
      ),
    );
    semantics.dispose();
  });

  testTomo('each tab keeps its own stack', (tester) async {
    await pumpTomo(tester);

    await tester.tap(tab('Work'));
    await tester.pumpAndSettle();
    await tester.tap(find.words('A project'));
    await tester.pumpAndSettle();
    expect(showing(tester, 'Project'), isTrue);

    await tester.tap(tab('Home'));
    await tester.pumpAndSettle();
    await tester.tap(gear().hitTestable());
    await tester.pumpAndSettle();
    expect(showing(tester, 'Settings'), isTrue);

    await tester.tap(tab('Work'));
    await tester.pumpAndSettle();
    expect(showing(tester, 'Project'), isTrue);

    await tester.tap(tab('Home'));
    await tester.pumpAndSettle();
    expect(showing(tester, 'Settings'), isTrue);
  });

  testTomo('tapping the tab you are on goes back to its first screen', (
    tester,
  ) async {
    await pumpTomo(tester);
    await tester.tap(tab('Work'));
    await tester.pumpAndSettle();
    await tester.tap(find.words('A project'));
    await tester.pumpAndSettle();
    await tester.tap(find.words('A task'));
    await tester.pumpAndSettle();
    expect(showing(tester, 'Task'), isTrue);

    await tester.tap(tab('Work'));
    await tester.pumpAndSettle();

    expect(find.byType(WorkPlaceholder).hitTestable(), findsOneWidget);
  });

  testTomo('a pushed screen keeps the tab bar', (tester) async {
    await pumpTomo(tester);
    final bar = tester.getRect(find.byType(ShellTabBar));

    await tester.tap(gear());
    await tester.pumpAndSettle();

    expect(showing(tester, 'Settings'), isTrue);
    expect(tester.getRect(find.byType(ShellTabBar)), bar);
    expect(tabBarShown(), findsOneWidget);
  });

  group('Android back', () {
    testTomo("closes the tab's top screen", (tester) async {
      await pumpTomo(tester);
      await tester.tap(gear());
      await tester.pumpAndSettle();

      await back(tester);

      expect(find.byType(HomeScreen).hitTestable(), findsOneWidget);
    });

    testTomo("on Work's first screen goes to Home", (tester) async {
      await pumpTomo(tester);
      await tester.tap(tab('Work'));
      await tester.pumpAndSettle();

      await back(tester);

      expect(find.byType(HomeScreen).hitTestable(), findsOneWidget);
    });

    testTomo("on Home's first screen leaves the app", (tester) async {
      final calls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          calls.add(call);
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await pumpTomo(tester);

      await back(tester);

      expect(calls.map((c) => c.method), contains('SystemNavigator.pop'));
    });
  });

  testTomo('Focus opens over the tab bar, and minimising returns', (
    tester,
  ) async {
    await pumpTomo(tester);

    // Focus on a live cycle, as the banner opens it.
    openFocus(tester.element(find.byType(HomeScreen)));
    await tester.pumpAndSettle();

    expect(find.byType(FocusPlaceholder).hitTestable(), findsOneWidget);
    expect(tabBarShown(), findsNothing);

    await tester.tap(find.words('Minimise'));
    await tester.pumpAndSettle();

    expect(tabBarShown(), findsOneWidget);
  });

  testTomo('a sheet covers the tab bar', (tester) async {
    await pumpTomo(tester);

    unawaited(
      showPixelSheet<void>(
        tester.element(find.byType(HomeScreen)),
        (_) => const SizedBox(height: 100),
      ),
    );
    await tester.pumpAndSettle();

    expect(tabBarShown(), findsNothing);
  });

  testTomo('the keyboard covers the tab bar; the screen above shrinks', (
    tester,
  ) async {
    await pumpTomo(tester);
    final screen = tester.getRect(find.byType(HomeScreen));
    final bar = tester.getRect(find.byType(ShellTabBar));

    tester.view.viewInsets = const FakeViewPadding(bottom: 900);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();

    final keyboardTop = (2400 - 900) / 2.625;
    expect(tester.getRect(find.byType(ShellTabBar)), bar);
    expect(
      tester.getRect(find.byType(HomeScreen)).bottom,
      closeTo(keyboardTop, 1e-9),
    );
    expect(tester.getRect(find.byType(HomeScreen)).top, screen.top);
  });

  testTomo('the tab bar sits above the phone\'s own buttons', (tester) async {
    tester.view.viewPadding = const FakeViewPadding(bottom: 63);
    tester.view.padding = const FakeViewPadding(bottom: 63);
    addTearDown(tester.view.resetViewPadding);
    addTearDown(tester.view.resetPadding);
    await pumpTomo(tester);

    final bar = tester.getRect(find.byType(ShellTabBar));
    final tabs = tester.getRect(tab('Home'));
    expect(bar.bottom, 2400 / 2.625);
    expect(tabs.bottom, lessThanOrEqualTo(bar.bottom - 63 / 2.625));
  });

  testTomo('tabs are at least 48 pt, and land on whole dots', (tester) async {
    for (final dpr in screens) {
      await pumpTomo(tester, dpr: dpr);
      for (final label in ['Home', 'Work']) {
        final rect = tester.getRect(tab(label));
        expect(rect.height, greaterThanOrEqualTo(48 - 1e-9));
      }
      final bar = tester.getRect(find.byType(ShellTabBar));
      expect(bar.top, wholeDots(tester));
    }
  });

  testTomo('nothing overflows at 200% text, in both themes', (tester) async {
    for (final dpr in screens) {
      for (final theme in ThemeName.values) {
        await pumpTomo(tester, dpr: dpr, textScale: 2, theme: theme);
        expect(tester.takeException(), isNull);
        expect(find.words('Home'), findsWidgets);
      }
    }
  });

  group('the wide-screen column', () {
    testTomo('a phone gets the whole width', (tester) async {
      await pumpTomo(tester);

      expect(tester.getRect(find.byType(TomoShell)).width, 1080 / 2.625);
    });

    testTomo('a screen 600 pt wide or more gets a centred phone column', (
      tester,
    ) async {
      // A tablet: 1600 × 2560 dots at 2×, so 800 pt wide.
      await pumpTomo(tester, dpr: 2, physicalSize: const Size(1600, 2560));

      final column = tester.getRect(find.byType(TomoShell));
      expect(column.width, 412);
      expect(column.left, (800 - 412) / 2);
      expect(column.left, wholeDots(tester));
      expect(column.right, wholeDots(tester));
      expect(tester.getRect(find.byType(ShellTabBar)).width, 412);
    });

    testTomo('its edges stay on whole dots at an awkward ratio', (
      tester,
    ) async {
      await pumpTomo(tester, dpr: 2.625, physicalSize: const Size(1800, 2560));

      final column = tester.getRect(find.byType(TomoShell));
      expect(column.left, wholeDots(tester));
      expect(column.right, wholeDots(tester));
      expect(column.width, lessThanOrEqualTo(412));
    });
  });

  testTomo('a debug build reaches the kit gallery from the Home tab', (
    tester,
  ) async {
    await pumpTomo(tester);

    await tester.longPress(tab('Home'));
    await tester.pumpAndSettle();

    expect(find.byType(KitGalleryScreen), findsOneWidget);
  });
}

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tomo/ui/buttons.dart';
import 'package:tomo/ui/kit_gallery_screen.dart';
import 'package:tomo/ui/pixel_icon.dart';
import 'package:tomo/ui/rows.dart';
import 'package:tomo/ui/sharp_text.dart';
import 'package:tomo/ui/tomo_theme.dart';
import 'package:tomo_core/art/pixel_art.dart';
import 'package:tomo_core/data/settings.dart';
import 'package:tomo_core/look/palette.dart';
import 'package:tomo_core/pet/species.dart';
import 'package:tomo_core/tasks/task_status.dart';

import 'kit_harness.dart';

/// The app's look (spec §9.1) and the kit gallery.
void main() {
  group('the theme', () {
    test('follows the phone unless Appearance says otherwise', () {
      expect(themeFor(Appearance.system, Brightness.light), ThemeName.light);
      expect(themeFor(Appearance.system, Brightness.dark), ThemeName.dark);
      expect(themeFor(Appearance.light, Brightness.dark), ThemeName.light);
      expect(themeFor(Appearance.dark, Brightness.light), ThemeName.dark);
    });

    testWidgets('reaches every part, with the pet\'s accent', (tester) async {
      await pumpKit(
        tester,
        const PixelText('Hello'),
        theme: ThemeName.dark,
        species: Species.lily,
      );
      final colours = TomoTheme.of(tester.element(find.byType(PixelText)));
      expect(colours.dark, isTrue);
      expect(colours.accent, const Color(0xFFC89AB3));
    });

    testWidgets('sets the status bar icons to show on the ground', (
      tester,
    ) async {
      for (final (theme, icons) in [
        (ThemeName.light, Brightness.dark),
        (ThemeName.dark, Brightness.light),
      ]) {
        await pumpKit(tester, const SizedBox(), theme: theme);
        final region = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
          find.byType(AnnotatedRegion<SystemUiOverlayStyle>).first,
        );
        expect(region.value.statusBarIconBrightness, icons, reason: '$theme');
      }
    });

    testWidgets('scrolling never stretches or glows past the end', (
      tester,
    ) async {
      await pumpKit(
        tester,
        SizedBox(
          height: 300,
          child: ListView(
            children: [for (var i = 0; i < 30; i++) PixelRow(title: 'Row $i')],
          ),
        ),
      );
      await tester.drag(find.byType(ListView), const Offset(0, 300));
      await tester.pump();
      expect(find.byType(StretchingOverscrollIndicator), findsNothing);
      expect(find.byType(GlowingOverscrollIndicator), findsNothing);
    });
  });

  testWidgets('a row\'s own buttons stay separate for screen readers', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpKit(
      tester,
      SizedBox(
        width: 360,
        child: PixelRow(
          title: 'Write the intro',
          subtitle: '2 of 4 blocks',
          onTap: () {},
          leading: PixelIconButton(
            icon: const StatusGlyph(TaskStatus.doing),
            semanticLabel: 'Doing',
            onPressed: () {},
          ),
          trailing: [
            PixelIconButton(
              icon: const PixelIcon(IconName.more),
              semanticLabel: 'More',
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
    expect(tester.getSize(find.byType(PixelRow)).height, lessThan(100));
    expect(
      tester.getSemantics(find.byType(PixelRow)),
      matchesSemantics(
        label: 'Write the intro\n2 of 4 blocks',
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        isFocusable: true,
        hasTapAction: true,
        hasFocusAction: true,
        children: [
          matchesSemantics(
            label: 'Doing',
            isButton: true,
            hasEnabledState: true,
            isEnabled: true,
            isFocusable: true,
            hasTapAction: true,
            hasFocusAction: true,
          ),
          matchesSemantics(
            label: 'More',
            isButton: true,
            hasEnabledState: true,
            isEnabled: true,
            isFocusable: true,
            hasTapAction: true,
            hasFocusAction: true,
          ),
        ],
      ),
    );
    handle.dispose();
  });

  group('the kit gallery', () {
    Future<void> scrollThrough(WidgetTester tester) async {
      final scrollable = find.byType(Scrollable).first;
      final position = tester.state<ScrollableState>(scrollable).position;
      while (position.pixels < position.maxScrollExtent) {
        await tester.drag(scrollable, const Offset(0, -600));
        await tester.pump();
        expect(tester.takeException(), isNull);
      }
    }

    for (final dpr in screens) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('shows every part at $dpr×, $scale text, with nothing '
            'clipped', (tester) async {
          for (final theme in ThemeName.values) {
            for (final species in [null, ...Species.values]) {
              await pumpKit(
                tester,
                const KitGalleryScreen(),
                dpr: dpr,
                textScale: scale,
                theme: theme,
                species: species,
              );
              await tester.pump();
              expect(tester.takeException(), isNull);
            }
          }
          await scrollThrough(tester);
        });
      }
    }

    testWidgets('opens each sheet and the pushed screens', (tester) async {
      await pumpKit(tester, const KitGalleryScreen(), textScale: 2);
      await tester.pump();
      for (final label in [
        'Stop this block?',
        'New project (a field)',
        'A long sheet that scrolls',
        'Push a screen',
        'Open a takeover from below',
      ]) {
        await tester.scrollUntilVisible(
          find.words(label).last,
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.words(label).last);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: label);
        // The Android back gesture.
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
      }
    });
  });
}

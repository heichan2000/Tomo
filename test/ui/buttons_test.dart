import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tomo/ui/buttons.dart';
import 'package:tomo/ui/pixel_box.dart';
import 'package:tomo/ui/pixel_icon.dart';
import 'package:tomo/ui/sharp_text.dart';
import 'package:tomo/ui/tomo_theme.dart';
import 'package:tomo_core/art/pixel_art.dart';
import 'package:tomo_core/look/palette.dart';

import 'kit_harness.dart';

/// Buttons and their states (spec §9.3, §12.7).
void main() {
  TomoColours colours(WidgetTester tester) =>
      TomoTheme.of(tester.element(find.byType(PixelBox).first));

  Color? fill(WidgetTester tester) =>
      tester.widget<PixelBox>(find.byType(PixelBox).first).fill;

  Color? ring(WidgetTester tester) =>
      tester.widget<PixelBox>(find.byType(PixelBox).first).ring;

  testWidgets('a button is at least 48 pt tall, a whole number of dots, with '
      'its label in the middle', (tester) async {
    for (final dpr in screens) {
      for (final scale in [1.0, 1.3, 2.0]) {
        await pumpKit(
          tester,
          PixelButton(label: 'Start focusing', onPressed: () {}),
          dpr: dpr,
          textScale: scale,
        );
        final button = tester.getRect(find.byType(PixelBox));
        final label = tester.getRect(find.byType(PixelText));
        final why = '$dpr×, $scale';
        expect(button.height, greaterThanOrEqualTo(48 - 1e-9), reason: why);
        expect(button.height, wholeDots(tester), reason: why);
        expect(
          label.top - button.top,
          closeTo(button.bottom - label.bottom, 1e-6),
          reason: why,
        );
        expect(label.top - button.top, wholeDots(tester), reason: why);
      }
    }
  });

  testWidgets('each kind has its own fill', (tester) async {
    final kinds = <ButtonKind, Color? Function(TomoColours)>{
      ButtonKind.primary: (c) => c.accent,
      ButtonKind.secondary: (c) => c.sunken,
      ButtonKind.quiet: (c) => null,
      ButtonKind.quietMuted: (c) => null,
      ButtonKind.quietDestructive: (c) => null,
      ButtonKind.destructive: (c) => c.destructive,
    };
    for (final MapEntry(key: kind, value: expected) in kinds.entries) {
      await pumpKit(
        tester,
        PixelButton(label: 'Go', kind: kind, onPressed: () {}),
      );
      expect(fill(tester), expected(colours(tester)), reason: kind.name);
    }
  });

  testWidgets('pressing shades the fill toward ink at once, and a tap acts', (
    tester,
  ) async {
    var taps = 0;
    await pumpKit(tester, PixelButton(label: 'Go', onPressed: () => taps++));
    final c = colours(tester);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(PixelButton)),
    );
    await tester.pump();
    expect(fill(tester), c.pressed(c.accent));

    await gesture.up();
    await tester.pump();
    expect(fill(tester), c.accent);
    expect(taps, 1);
  });

  testWidgets('a pressed quiet button gets a sunken fill', (tester) async {
    await pumpKit(
      tester,
      PixelButton(
        label: 'Skip break',
        kind: ButtonKind.quiet,
        held: HeldState.pressed,
        onPressed: () {},
      ),
    );
    expect(fill(tester), colours(tester).sunken);
  });

  testWidgets('a turned-off button is solid sunken with muted words, and '
      'does nothing', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpKit(
      tester,
      const PixelButton(label: 'Start focusing', onPressed: null),
    );
    final c = colours(tester);
    expect(fill(tester), c.sunken);
    expect(tester.widget<PixelText>(find.byType(PixelText)).colour, c.muted);

    await tester.tap(find.byType(PixelButton));
    await tester.pump();
    expect(fill(tester), c.sunken);
    expect(
      tester.getSemantics(find.byType(PixelButton)),
      isSemantics(
        label: 'Start focusing',
        isButton: true,
        hasEnabledState: true,
        isEnabled: false,
      ),
    );
    handle.dispose();
  });

  testWidgets('screen readers hear a button and its words', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpKit(tester, PixelButton(label: 'Keep going', onPressed: () {}));
    expect(
      tester.getSemantics(find.byType(PixelButton)),
      isSemantics(
        label: 'Keep going',
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        isFocusable: true,
        hasTapAction: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('keyboard focus shows the accent ring; Enter presses', (
    tester,
  ) async {
    var taps = 0;
    await pumpKit(tester, PixelButton(label: 'Go', onPressed: () => taps++));
    expect(ring(tester), isNull);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(ring(tester), colours(tester).accent);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('a touch never shows the ring', (tester) async {
    await pumpKit(tester, PixelButton(label: 'Go', onPressed: () {}));
    await tester.tap(find.byType(PixelButton));
    await tester.pump();
    expect(ring(tester), isNull);
  });

  testWidgets('an icon button is a 48 pt target with a label', (tester) async {
    final handle = tester.ensureSemantics();
    for (final dpr in screens) {
      await pumpKit(
        tester,
        PixelIconButton(
          icon: const PixelIcon(IconName.gear),
          semanticLabel: 'Settings',
          onPressed: () {},
        ),
        dpr: dpr,
      );
      final size = tester.getSize(find.byType(PixelIconButton));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.width, wholeDots(tester));
      expect(size.height, size.width);
      // The icon: 12 UI pixels.
      expect(
        tester.getSize(find.byType(PixelIcon)).width,
        closeTo(12 * bodyDots(dpr) / dpr, 1e-9),
      );
    }
    expect(
      tester.getSemantics(find.byType(PixelIconButton)),
      isSemantics(label: 'Settings', isButton: true, hasTapAction: true),
    );
    handle.dispose();
  });

  test('pressing a primary button before the hatch in dark still shows', () {
    final dark = TomoColours.of(ThemeName.dark, null);
    expect(dark.pressed(dark.accent), isNot(dark.accent));
  });
}

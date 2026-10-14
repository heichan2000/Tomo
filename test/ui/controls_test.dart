import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tomo/ui/exp_bar.dart';
import 'package:tomo/ui/pixel_box.dart';
import 'package:tomo/ui/segmented.dart';
import 'package:tomo/ui/switch.dart';
import 'package:tomo/ui/tomo_theme.dart';
import 'package:tomo/ui/ui_pixel.dart';

import 'kit_harness.dart';

/// Segmented controls, switches and the EXP bar (spec §9.3).
void main() {
  group('a segmented control', () {
    Widget appearance(String selected, ValueChanged<String> onChanged) =>
        SizedBox(
          width: 360,
          child: PixelSegmented<String>(
            segments: const [
              Segment('phone', 'Match phone'),
              Segment('light', 'Light'),
              Segment('dark', 'Dark'),
            ],
            selected: selected,
            onChanged: onChanged,
          ),
        );

    Rect option(WidgetTester tester, String label) => tester.getRect(
      find
          .ancestor(of: find.words(label), matching: find.byType(PixelBox))
          .first,
    );

    test('shares one row only when every label fits', () {
      expect(
        PixelSegmented.fitsOnOneRow(
          labels: [60, 30, 30],
          width: 3 * (60 + 4 * 4) + 2 * 4,
          uiPixel: 4,
        ),
        isTrue,
      );
      expect(
        PixelSegmented.fitsOnOneRow(
          labels: [60, 30, 30],
          width: 3 * (60 + 4 * 4) + 2 * 4 - 1,
          uiPixel: 4,
        ),
        isFalse,
      );
    });

    testWidgets('shares one row in equal parts, one UI pixel apart', (
      tester,
    ) async {
      await pumpKit(tester, appearance('phone', (_) {}));
      final a = option(tester, 'Match phone');
      final b = option(tester, 'Light');
      final c = option(tester, 'Dark');
      expect(a.top, b.top);
      expect(b.top, c.top);
      final u = UiPixel(2.625);
      expect(b.left - a.right, closeTo(u.pt, 1e-9));
      expect(c.left - b.right, closeTo(u.pt, 1e-9));
      for (final r in [a, b, c]) {
        expect(r.width, wholeDots(tester));
        expect((r.width - a.width).abs() * 2.625, lessThanOrEqualTo(1 + 1e-9));
        expect(r.height, greaterThanOrEqualTo(48));
      }
    });

    testWidgets('stacks the options when they don\'t fit, and never clips', (
      tester,
    ) async {
      await pumpKit(tester, appearance('phone', (_) {}), textScale: 2);
      final a = option(tester, 'Match phone');
      final b = option(tester, 'Light');
      expect(b.top, greaterThan(a.bottom));
      expect(b.left, a.left);
      expect(b.width, a.width);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a tap chooses; the chosen option is in the accent', (
      tester,
    ) async {
      String? chosen;
      await pumpKit(tester, appearance('phone', (v) => chosen = v));
      await tester.tap(find.words('Dark'));
      expect(chosen, 'dark');

      final colours = TomoTheme.of(tester.element(find.words('Dark')));
      final chosenBox = tester.widget<PixelBox>(
        find
            .ancestor(
              of: find.words('Match phone'),
              matching: find.byType(PixelBox),
            )
            .first,
      );
      expect(chosenBox.fill, colours.accent);
    });

    testWidgets('screen readers hear one choice of a group', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpKit(tester, appearance('light', (_) {}));
      expect(
        tester.getSemantics(find.words('Light')),
        isSemantics(
          label: 'Light',
          isSelected: true,
          hasSelectedState: true,
          isInMutuallyExclusiveGroup: true,
          hasTapAction: true,
        ),
      );
      expect(
        tester.getSemantics(find.words('Dark')),
        isSemantics(
          label: 'Dark',
          isSelected: false,
          hasSelectedState: true,
          isInMutuallyExclusiveGroup: true,
          hasTapAction: true,
        ),
      );
      handle.dispose();
    });
  });

  group('a switch', () {
    testWidgets('turns on and off, and says which', (tester) async {
      final handle = tester.ensureSemantics();
      var on = false;
      await pumpKit(
        tester,
        StatefulBuilder(
          builder: (context, setState) => PixelSwitch(
            value: on,
            semanticLabel: 'Calm pet',
            onChanged: (v) => setState(() => on = v),
          ),
        ),
      );
      expect(
        tester.getSemantics(find.byType(PixelSwitch)),
        isSemantics(
          label: 'Calm pet',
          hasToggledState: true,
          isToggled: false,
          hasTapAction: true,
        ),
      );
      await tester.tap(find.byType(PixelSwitch));
      await tester.pumpAndSettle();
      expect(on, isTrue);
      expect(
        tester.getSemantics(find.byType(PixelSwitch)),
        isSemantics(label: 'Calm pet', hasToggledState: true, isToggled: true),
      );
      expect(
        tester.getSize(find.byType(PixelSwitch)).width,
        greaterThanOrEqualTo(48),
      );
      handle.dispose();
    });

    testWidgets('its knob slides in whole UI pixels within 120 ms', (
      tester,
    ) async {
      var on = false;
      late StateSetter set;
      await pumpKit(
        tester,
        StatefulBuilder(
          builder: (context, setState) {
            set = setState;
            return SwitchLook(value: on);
          },
        ),
      );
      final u = UiPixel(2.625);
      double knob() =>
          tester.getTopLeft(find.byType(PixelBox).last).dx -
          tester.getTopLeft(find.byType(PixelBox).first).dx;
      expect(knob(), closeTo(u(2), 1e-9));

      set(() => on = true);
      for (var ms = 0; ms <= 120; ms += 10) {
        await tester.pump(const Duration(milliseconds: 10));
        final pixels = knob() / u.pt;
        expect(pixels, closeTo(pixels.roundToDouble(), 1e-9), reason: '$ms ms');
      }
      await tester.pump(const Duration(milliseconds: 1));
      expect(knob(), closeTo(u(12), 1e-9));
    });

    testWidgets('a switch row is one target that toggles', (tester) async {
      final handle = tester.ensureSemantics();
      var on = false;
      await pumpKit(
        tester,
        SizedBox(
          width: 360,
          child: StatefulBuilder(
            builder: (context, setState) => PixelSwitchRow(
              title: 'Calm pet',
              subtitle: 'Your pet stays still',
              value: on,
              onChanged: (v) => setState(() => on = v),
            ),
          ),
        ),
      );
      await tester.tap(find.words('Your pet stays still'));
      await tester.pumpAndSettle();
      expect(on, isTrue);
      expect(
        tester.getSemantics(find.byType(PixelSwitchRow)),
        isSemantics(
          label: 'Calm pet\nYour pet stays still',
          hasToggledState: true,
          isToggled: true,
          hasTapAction: true,
        ),
      );
      handle.dispose();
    });
  });

  group('the EXP bar', () {
    test('blocks are as wide as fits in whole UI pixels', () {
      // 20 blocks and 19 one-pixel gaps.
      expect(ExpBar.blockWidth(20 * 5 + 19), 5);
      expect(ExpBar.blockWidth(20 * 5 + 19 + 19), 5);
      expect(ExpBar.blockWidth(20 * 6 + 19), 6);
      expect(ExpBar.blockWidth(10), 1);
    });

    testWidgets('is 20 blocks with the lit ones in the accent', (tester) async {
      await pumpKit(tester, const SizedBox(width: 300, child: ExpBar(lit: 8)));
      final boxes = tester.widgetList<PixelBox>(find.byType(PixelBox)).toList();
      final colours = TomoTheme.of(tester.element(find.byType(ExpBar)));
      expect(boxes, hasLength(20));
      expect(boxes.where((b) => b.fill == colours.accent), hasLength(8));
      expect(boxes.where((b) => b.fill == colours.sunken), hasLength(12));
      expect(boxes.every((b) => !b.cutCorners), isTrue);

      final u = UiPixel(2.625);
      final first = tester.getRect(find.byType(PixelBox).at(0));
      final second = tester.getRect(find.byType(PixelBox).at(1));
      expect(first.height, closeTo(u(6), 1e-9));
      expect(second.left - first.right, closeTo(u(1), 1e-9));
      expect(tester.getSize(find.byType(ExpBar)).width, lessThanOrEqualTo(300));
    });

    testWidgets('never lights more than 20 or fewer than none', (tester) async {
      await pumpKit(tester, const SizedBox(width: 300, child: ExpBar(lit: 25)));
      final colours = TomoTheme.of(tester.element(find.byType(ExpBar)));
      expect(
        tester
            .widgetList<PixelBox>(find.byType(PixelBox))
            .every((b) => b.fill == colours.accent),
        isTrue,
      );
    });
  });
}
